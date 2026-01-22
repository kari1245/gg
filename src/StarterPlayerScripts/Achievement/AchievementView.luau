local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local AchievementView = {}

-- [[ NÚT BẤM CYBER (ĐÃ FIX LỖI CLICK) ]]
local function CyberButton(scope, props)
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 40, 1)

	-- Tính toán màu nút
	local finalColor = props.Color

	return scope:New "TextButton" {
		Text = "", Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = Color3.fromRGB(25, 20, 35),

		-- [FIX] Dùng Computed để tự động cập nhật độ mờ khi Disabled thay đổi
		BackgroundTransparency = scope:Computed(function(use)
			return use(props.Disabled) and 0.5 or 0 
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
			scope:New "UIScale" { Scale = scale }, scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" { Thickness = 2, Transparency = 0, [Fusion.Children] = {
				scope:New "UIGradient" {
					Color = scope:Computed(function(use)
						local c = use(finalColor) or Color3.fromRGB(170, 0, 255)
						return ColorSequence.new{ColorSequenceKeypoint.new(0, c), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))}
					end),
					Rotation = 90
				}
			}},
			scope:New "TextLabel" { 
				Text = props.Text or "", 
				Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, 
				TextColor3 = finalColor, 
				Font = Enum.Font.GothamBlack, TextSize = 14, ZIndex = 2 
			}
		}
	}
end

-- [[ HÀM RENDER ITEM ]]
local function RenderAchievementItem(scope, title, props)
	-- Kiểm tra equip
	local isEquipped = scope:Computed(function(use) 
		return use(props.CurrentTitle) == title 
	end)

	-- Màu sắc thay đổi theo trạng thái
	local stateColor = scope:Computed(function(use)
		return use(isEquipped) and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(100, 50, 150)
	end)

	local btnColor = scope:Computed(function(use)
		return use(isEquipped) and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 200, 0)
	end)

	local btnText = scope:Computed(function(use)
		return use(isEquipped) and "ACTIVE" or "EQUIP"
	end)

	return scope:New "Frame" {
		Size = UDim2.new(1, 0, 0, 55), BackgroundColor3 = Color3.fromRGB(30, 20, 40),
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },

			-- Viền sáng lên khi Equip
			scope:New "UIStroke" { 
				Color = stateColor, 
				Thickness = scope:Computed(function(use) return use(isEquipped) and 2 or 1 end)
			},

			-- Tên Title
			scope:New "TextLabel" {
				Text = title, Size = UDim2.fromScale(0.6, 1), BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0),
				TextColor3 = scope:Computed(function(use) return use(isEquipped) and Color3.new(1,1,1) or Color3.fromRGB(200,200,200) end), 
				Font = Enum.Font.Code, TextSize = 16, TextXAlignment = "Left", TextTruncate = "AtEnd"
			},

			-- Nút bấm
			CyberButton(scope, {
				Text = btnText,
				Color = btnColor,
				Size = UDim2.new(0, 90, 0, 35), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
				Disabled = isEquipped, -- Disable nút Active
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
	local WalletList = scope:Computed(function(use)
		local list = {}
		-- [FIX] Thêm NO_DATA vào danh sách hiển thị nếu chưa có
		local hasNoData = false
		for _, title in ipairs(use(props.UnlockedList)) do
			if title == "NO_DATA" then hasNoData = true end
			if GetAchType(title) == "Wallet" then table.insert(list, title) end
		end
		-- Nếu người chơi có NO_DATA (từ DataService), ta cho nó hiện ở cột này hoặc cột riêng
		if hasNoData then table.insert(list, 1, "NO_DATA") end
		return list
	end)

	local WinList = scope:Computed(function(use)
		local list = {}
		for _, title in ipairs(use(props.UnlockedList)) do
			if GetAchType(title) == "Wins" then table.insert(list, title) end
		end
		return list
	end)

	return scope:New "ScreenGui" {
		Name = "UI_Achievement", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			CyberButton(scope, {
				Text = "🏆", Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0, 20, 0.5, -60),
				Color = Color3.fromRGB(170, 0, 255), OnClick = props.OnToggle
			}),

			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.7, 0.65), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(15, 10, 20),
				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },
					scope:New "UIStroke" { Thickness = 3, [Fusion.Children] = { scope:New "UIGradient" { Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 100))}, Rotation = 60 } } },
					scope:New "ImageLabel" { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Image = "rbxassetid://6071575925", ImageColor3 = Color3.fromRGB(170, 0, 255), ImageTransparency = 0.95, ScaleType = "Tile", TileSize = UDim2.new(0, 40, 0, 40), [Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 16) } } },

					scope:New "TextLabel" {
						Text = "HALL OF FAME", Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(220, 100, 255), Font = Enum.Font.GothamBlack, TextSize = 30,
						TextXAlignment = "Center", Position = UDim2.new(0, 0, 0, 10)
					},
					CyberButton(scope, { Text = "✕", Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -25, 0, 15), AnchorPoint = Vector2.new(1,0), Color = Color3.fromRGB(255, 50, 80), OnClick = props.OnClose }),

					scope:New "Frame" {
						Size = UDim2.new(1, -40, 1, -90), Position = UDim2.new(0, 20, 0, 70),
						BackgroundTransparency = 1,
						[Fusion.Children] = {
							scope:New "UIListLayout" { FillDirection = "Horizontal", Padding = UDim.new(0, 20), HorizontalAlignment = "Center" },

							-- CỘT WEALTH
							scope:New "Frame" {
								Size = UDim2.new(0.5, -10, 1, 0), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.5,
								[Fusion.Children] = {
									scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
									scope:New "TextLabel" {
										Text = "WEALTH 💰", Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1,
										TextColor3 = Color3.fromRGB(255, 200, 0), Font = Enum.Font.GothamBold, TextSize = 18
									},
									scope:New "ScrollingFrame" {
										Size = UDim2.new(1, -10, 1, -50), Position = UDim2.new(0, 5, 0, 40),
										BackgroundTransparency = 1, AutomaticCanvasSize = "Y", CanvasSize = UDim2.new(),
										ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(255, 200, 0),
										[Fusion.Children] = {
											scope:New "UIListLayout" { Padding = UDim.new(0, 8) },
											scope:ForValues(WalletList, function(use, inner, title)
												return RenderAchievementItem(inner, title, props)
											end)
										}
									}
								}
							},

							-- CỘT COMBAT
							scope:New "Frame" {
								Size = UDim2.new(0.5, -10, 1, 0), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.5,
								[Fusion.Children] = {
									scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
									scope:New "TextLabel" {
										Text = "COMBAT ⚔️", Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1,
										TextColor3 = Color3.fromRGB(255, 50, 50), Font = Enum.Font.GothamBold, TextSize = 18
									},
									scope:New "ScrollingFrame" {
										Size = UDim2.new(1, -10, 1, -50), Position = UDim2.new(0, 5, 0, 40),
										BackgroundTransparency = 1, AutomaticCanvasSize = "Y", CanvasSize = UDim2.new(),
										ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(255, 50, 50),
										[Fusion.Children] = {
											scope:New "UIListLayout" { Padding = UDim.new(0, 8) },
											scope:ForValues(WinList, function(use, inner, title)
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