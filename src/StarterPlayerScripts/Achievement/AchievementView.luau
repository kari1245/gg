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
local function RenderAchievementItem(scope, achData, props)
	local title = achData.Title
	local isUnlocked = achData.IsUnlocked
	local isEquipped = scope:Computed(function(use) 
		return use(props.CurrentTitle) == title 
	end)
	
	-- Use achievement's custom color
	local achColor = achData.Color or Theme.NeonPurple

	local stateColor = scope:Computed(function(use)
		if not isUnlocked then return Color3.fromRGB(80, 80, 80) end -- Locked = gray
		return use(isEquipped) and Theme.NeonGreen or achColor
	end)

	local btnColor = scope:Computed(function(use)
		if not isUnlocked then return Color3.fromRGB(100, 100, 100) end
		return use(isEquipped) and Theme.GlitchRed or achColor
	end)

	local btnText = scope:Computed(function(use)
		if not isUnlocked then return "○ LOCKED" end
		return use(isEquipped) and "▼ UNEQUIP" or "▲ EQUIP"
	end)
	
	local btnDisabled = scope:Computed(function(use)
		return not isUnlocked
	end)

	return scope:New "Frame" {
		Size = UDim2.new(1, -10, 0, 110), -- Tăng từ 90 lên 110 pixels
		BackgroundColor3 = Theme.MidBg,
		BackgroundTransparency = isUnlocked and 0.3 or 0.6,
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },

			-- Viền sáng lên khi Equip
			scope:New "UIStroke" { 
				Color = stateColor, 
				Thickness = scope:Computed(function(use) return use(isEquipped) and 3 or 1.5 end),
				Transparency = isUnlocked and 0 or 0.5
			},
			
			-- Glow khi equipped
			scope:New "ImageLabel" {
				Visible = isEquipped,
				Size = UDim2.fromScale(1.05, 1.05), Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
				Image = "rbxassetid://5028857084",
				ImageColor3 = achColor,
				ImageTransparency = 0.6, ZIndex = 0
			},
			
			-- Icon
			scope:New "TextLabel" {
				Text = isUnlocked and (achData.Icon or "◆") or "○",
			Size = UDim2.fromScale(0.06, 0.45),
			Position = UDim2.fromScale(0.02, 0.1),
				BackgroundTransparency = 1,
				TextColor3 = isUnlocked and achColor or Color3.fromRGB(100, 100, 100),
				Font = Enum.Font.Code,
				TextSize = 32,
				ZIndex = 2
			},

			-- Tên Title
			scope:New "TextLabel" {
				Text = title, 
			Size = UDim2.fromScale(0.5, 0.28), 
			BackgroundTransparency = 1, 
			Position = UDim2.fromScale(0.1, 0.08),
				TextColor3 = scope:Computed(function(use) 
					if not isUnlocked then return Color3.fromRGB(120, 120, 120) end
					return use(isEquipped) and Theme.NeonGreen or achColor
				end), 
				Font = Enum.Font.Code, 
				TextSize = 16,
				TextScaled = true,
				TextXAlignment = "Left", 
				TextTruncate = "AtEnd",
				TextStrokeTransparency = 0.5,
				ZIndex = 2
			},
			
			-- Description (Điều kiện)
			scope:New "TextLabel" {
				Text = "📋 " .. achData.Desc,
			Size = UDim2.fromScale(0.5, 0.22),
			Position = UDim2.fromScale(0.1, 0.4),
				BackgroundTransparency = 1,
				TextColor3 = isUnlocked and Color3.fromRGB(180, 180, 180) or Color3.fromRGB(100, 100, 100),
				Font = Enum.Font.Code,
				TextSize = 12,
				TextXAlignment = "Left",
				TextTruncate = "AtEnd",
				ZIndex = 2
			},
			
			-- Requirement Value
			scope:New "TextLabel" {
				Text = string.format("🎯 %s: %s", achData.Type, tostring(achData.Val)),
			Size = UDim2.fromScale(0.5, 0.22),
			Position = UDim2.fromScale(0.1, 0.65),
				BackgroundTransparency = 1,
				TextColor3 = isUnlocked and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(80, 100, 80),
				Font = Enum.Font.Code,
				TextSize = 11,
				TextXAlignment = "Left",
				ZIndex = 2
			},

			-- Nút bấm
			CyberButton(scope, {
				Text = btnText,
				Color = btnColor,
			Size = UDim2.fromScale(0.15, 0.45), 
			Position = UDim2.fromScale(0.98, 0.5), 
				AnchorPoint = Vector2.new(1, 0.5),
				Disabled = btnDisabled,
				OnClick = function() 
					local current = Fusion.peek(props.CurrentTitle)
					if not isUnlocked then return end -- Can't click locked achievements
					-- If already equipped, unequip it
					if current == title then 
						props.OnEquip("") -- Empty string to unequip
					else
						props.OnEquip(title)
					end
				end
			})
		}
	}
end

local function GetAchData(title)
	for _, ach in ipairs(GameConfig.Achievements) do
		if ach.Title == title then return ach end
	end
	return nil
end

function AchievementView.New(scope, props)
	local AchievementList = scope:Computed(function(use)
		local list = {}
		local unlockedSet = {}
		
		-- Build unlocked set for fast lookup
		for _, title in ipairs(use(props.UnlockedList)) do
			if title ~= "NO_DATA" then
				unlockedSet[title] = true
			end
		end
		
		-- Show ALL achievements with unlock status
		for _, ach in ipairs(GameConfig.Achievements) do
			local achCopy = {
				ID = ach.ID,
				Type = ach.Type,
				Val = ach.Val,
				Title = ach.Title,
				Desc = ach.Desc,
				Color = ach.Color,
				Icon = ach.Icon,
				IsUnlocked = unlockedSet[ach.Title] or false
			}
			table.insert(list, achCopy)
		end
		
		-- Sort: unlocked first, then by ID
		table.sort(list, function(a, b)
			if a.IsUnlocked ~= b.IsUnlocked then
				return a.IsUnlocked
			end
			return a.ID < b.ID
		end)
		
		return list
	end)

	return scope:New "ScreenGui" {
		Name = "UI_Achievement", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			CyberButton(scope, {
					Text = "◆ RNK", Size = UDim2.new(0.065, 0, 0.09, 0), Position = UDim2.new(0.015, 0, 0.13, 0),				Color = Theme.NeonPurple, OnClick = props.OnToggle
			}),
			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.75, 0.7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Theme.DarkBg,
				BackgroundTransparency = 0.1,
				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 20) },
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
								scope:New "ScrollingFrame" {
									Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0.5, 0, 0.5, 0),
									AnchorPoint = Vector2.new(0.5, 0.5),
										BackgroundTransparency = 1, AutomaticCanvasSize = "Y", CanvasSize = UDim2.new(),
										ScrollBarThickness = 6, ScrollBarImageColor3 = Theme.NeonPurple,
										[Fusion.Children] = {
									scope:New "UIListLayout" { Padding = UDim.new(0, 12) },
											scope:ForValues(AchievementList, function(use, inner, achData)
												return RenderAchievementItem(inner, achData, props)
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