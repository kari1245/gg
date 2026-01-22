local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local AchievementView = {}
local Theme = GameConfig.CyberTheme

-- Cyber Button với neon glow
local function CyberButton(scope, props)
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 40, 1)

	return scope:New "TextButton" {
		Text = "", Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = Theme.DarkBg,
		BackgroundTransparency = scope:Computed(function(use)
			return use(props.Disabled) and 0.7 or 0.2 
		end),
		AutoButtonColor = false,

		[Fusion.OnEvent "MouseEnter"] = function() 
			-- [FIX] Peek giá trị Disabled để check
			if not Fusion.peek(props.Disabled) then isHover:set(true) end 
		end,

		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,

		[Fusion.OnEvent "Activated"] = function() 
			-- [FIX QUAN TRỌNG] Phải peek() để lấy giá trị boolean thật sự
			local isDisabled = Fusion.peek(props.Disabled)
			if not isDisabled and props.OnClick then 
				props.OnClick() 
			end 
		end,

		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" { 
				Thickness = 2.5,
				Color = props.Color or Theme.NeonPurple,
				Transparency = 0
			},
			-- Glow effect
			scope:New "ImageLabel" {
				Size = UDim2.fromScale(1.15, 1.15), Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
				Image = "rbxassetid://5028857084",
				ImageColor3 = props.Color or Theme.NeonPurple,
				ImageTransparency = 0.65, ZIndex = -1
			},
			scope:New "TextLabel" { 
				Text = props.Text or "", 
				Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, 
				TextColor3 = props.Color or Theme.NeonPurple, 
				Font = Enum.Font.Code, TextSize = 16,
				TextStrokeTransparency = 0.5,
				ZIndex = 2 
			}
		}
	}
end

-- [[ HÀM RENDER ITEM ]]
local function RenderAchievementItem(scope, title, props)
	local isEquipped = scope:Computed(function(use) 
		return use(props.CurrentTitle) == title 
	end)

	local stateColor = scope:Computed(function(use)
		return use(isEquipped) and Theme.NeonGreen or Theme.NeonPurple
	end)

	local btnColor = scope:Computed(function(use)
		return use(isEquipped) and Theme.NeonGreen or GameConfig.Colors.Gold
	end)

	local btnText = scope:Computed(function(use)
		return use(isEquipped) and "▼ ACTIVE" or "▲ EQUIP"
	end)

	return scope:New "Frame" {
		Size = UDim2.new(1, 0, 0, 60), 
		BackgroundColor3 = Theme.MidBg,
		BackgroundTransparency = 0.3,
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },

			-- Viền sáng lên khi Equip
			scope:New "UIStroke" { 
				Color = stateColor, 
				Thickness = scope:Computed(function(use) return use(isEquipped) and 3 or 1.5 end),
				Transparency = 0
			},
			
			-- Glow khi equipped
			scope:New "ImageLabel" {
				Visible = isEquipped,
				Size = UDim2.fromScale(1.05, 1.05), Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
				Image = "rbxassetid://5028857084",
				ImageColor3 = Theme.NeonGreen,
				ImageTransparency = 0.6, ZIndex = 0
			},

			-- Tên Title
			scope:New "TextLabel" {
				Text = "► " .. title, 
				Size = UDim2.fromScale(0.58, 0.6), 
				BackgroundTransparency = 1, 
				Position = UDim2.new(0.03, 0, 0.2, 0),
				TextColor3 = scope:Computed(function(use) 
					return use(isEquipped) and Theme.NeonGreen or Color3.fromRGB(200,200,200) 
				end), 
				Font = Enum.Font.Code, TextScaled = true, 
				TextXAlignment = "Left", TextTruncate = "AtEnd",
				TextStrokeTransparency = 0.7,
				ZIndex = 2
			},

			-- Nút bấm
			CyberButton(scope, {
				Text = btnText,
				Color = btnColor,
				Size = UDim2.fromOffset(95, 38), 
				Position = UDim2.new(1, -12, 0.5, 0), 
				AnchorPoint = Vector2.new(1, 0.5),
				Disabled = isEquipped,
				OnClick = function() 
					local current = Fusion.peek(props.CurrentTitle)
					if current ~= title then props.OnEquip(title) end 
				end
			})
		}
	}
end

local function GetAchType(title)
	for _, ach in ipairs(GameConfig.Achievements) do
		if ach.Title == title then return ach.Type end
	end
	return "Other"
end

function AchievementView.New(scope, props)
	local AchievementList = scope:Computed(function(use)
		local list = {}
		-- [FIX] Thêm NO_DATA vào danh sách hiển thị nếu chưa có
		local hasNoData = false
		for _, title in ipairs(use(props.UnlockedList)) do
			if title == "NO_DATA" then hasNoData = true end
			if GetAchType(title) == "Wallet" then table.insert(list, title) end
		end
		-- Nếu người chơi có NO_DATA (từ DataService), ta cho nó hiện ở cột này
		if hasNoData then table.insert(list, 1, "NO_DATA") end
		return list
	end)

	return scope:New "ScreenGui" {
		Name = "UI_Achievement", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			CyberButton(scope, {
				Text = "◢ XP", Size = UDim2.new(0.065, 0, 0.09, 0), Position = UDim2.new(0.015, 0, 0.13, 0),
				Color = Theme.NeonPurple, OnClick = props.OnToggle
			}),

			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.75, 0.7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Theme.DarkBg,
				BackgroundTransparency = 0.1,
				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 20) },
					scope:New "UIAspectRatioConstraint" { AspectRatio = 1.07 },
					scope:New "UIStroke" { 
						Thickness = 3.5,
						Transparency = 0,
						[Fusion.Children] = { 
							scope:New "UIGradient" { 
								Color = ColorSequence.new{
									ColorSequenceKeypoint.new(0, Theme.NeonPurple),
									ColorSequenceKeypoint.new(0.5, Theme.NeonPink),
									ColorSequenceKeypoint.new(1, Theme.NeonOrange)
								},
								Rotation = 45
							}
						}
					},
					scope:New "ImageLabel" { 
						Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, 
						Image = "rbxassetid://6071575925", 
						ImageColor3 = Theme.NeonPurple, ImageTransparency = 0.92, 
						ScaleType = "Tile", TileSize = UDim2.fromOffset(45, 45),
						ZIndex = 0,
						[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 20) } } 
					},

					scope:New "TextLabel" {
						Text = "◢◤ HALL OF FAME ◥◣", 
					Size = UDim2.new(1, 0, 0.095, 0), 
					BackgroundTransparency = 1,
					TextColor3 = Theme.NeonPurple, 
					Font = Enum.Font.Code, TextScaled = true,
					TextXAlignment = "Center", 
					Position = UDim2.fromScale(0, 0.015),
						TextStrokeTransparency = 0.4,
						TextStrokeColor3 = Theme.NeonPink,
						ZIndex = 2
					},
					CyberButton(scope, { Text = "✕", Size = UDim2.new(0.065, 0, 0.09, 0), Position = UDim2.new(0.98, 0, 0.015, 0), AnchorPoint = Vector2.new(1,0), Color = Theme.GlitchRed, OnClick = props.OnClose }),

					scope:New "Frame" {
						Size = UDim2.new(1, -40, 1, -100), Position = UDim2.new(0.5, 0, 0, 85),
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundTransparency = 1,
						[Fusion.Children] = {
							-- DANH SÁCH THÀNH TỰU
							scope:New "Frame" {
								Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.5,
								[Fusion.Children] = {
									scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
									scope:New "TextLabel" {
										Text = "◢ ACHIEVEMENTS ◣", 
										Size = UDim2.new(1, 0, 0, 50), 
										BackgroundTransparency = 1,
										TextColor3 = Theme.NeonPurple, 
										Font = Enum.Font.Code, 
										TextSize = 22,
										TextScaled = true,
										TextStrokeTransparency = 0.5,
										ZIndex = 2
									},
									scope:New "ScrollingFrame" {
										Size = UDim2.new(1, -20, 1, -65), Position = UDim2.new(0.5, 0, 0, 60),
										AnchorPoint = Vector2.new(0.5, 0),
										BackgroundTransparency = 1, AutomaticCanvasSize = "Y", CanvasSize = UDim2.new(),
										ScrollBarThickness = 6, ScrollBarImageColor3 = Theme.NeonPurple,
										[Fusion.Children] = {
											scope:New "UIListLayout" { Padding = UDim.new(0, 10) },
											scope:ForValues(AchievementList, function(use, inner, title)
												return RenderAchievementItem(inner, title, props)
											end)
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
end

return AchievementView