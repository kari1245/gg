local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local AchievementView = {}

-- [[ NÚT BẤM CYBER (PURPLE THEME) ]]
local function CyberButton(scope, props)
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 40, 1)
	return scope:New "TextButton" {
		Text = "", Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = Color3.fromRGB(25, 20, 35),
		BackgroundTransparency = props.Disabled and 0.5 or 0, AutoButtonColor = false,
		[Fusion.OnEvent "MouseEnter"] = function() if not props.Disabled then isHover:set(true) end end,
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		[Fusion.OnEvent "Activated"] = function() if not props.Disabled and props.OnClick then props.OnClick() end end,
		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale }, scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" { Thickness = 2, Transparency = 0, [Fusion.Children] = {
				scope:New "UIGradient" {
					Color = ColorSequence.new{ColorSequenceKeypoint.new(0, props.Color or Color3.fromRGB(170, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255))},
					Rotation = 90
				}
			}},
			scope:New "TextLabel" { Text = props.Text or "", Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, TextColor3 = props.Color or Color3.fromRGB(220, 100, 255), Font = Enum.Font.GothamBlack, TextSize = 16, ZIndex = 2 }
		}
	}
end

function AchievementView.New(scope, props)
	return scope:New "ScreenGui" {
		Name = "UI_Achievement", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			CyberButton(scope, {
				Text = "🏆", Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0, 20, 0.5, -60),
				Color = Color3.fromRGB(170, 0, 255), OnClick = props.OnToggle
			}),

			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.55, 0.65), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(15, 10, 20),
				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },
					scope:New "UIStroke" { Thickness = 3, [Fusion.Children] = { scope:New "UIGradient" { Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 100))}, Rotation = 60 } } },
					scope:New "ImageLabel" { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Image = "rbxassetid://6071575925", ImageColor3 = Color3.fromRGB(170, 0, 255), ImageTransparency = 0.95, ScaleType = "Tile", TileSize = UDim2.new(0, 40, 0, 40), [Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 16) } } },

					scope:New "TextLabel" {
						Text = "HALL OF FAME", Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(220, 100, 255), Font = Enum.Font.GothamBlack, TextSize = 32,
						TextXAlignment = "Left", [Fusion.Children] = { scope:New "UIPadding" { PaddingLeft = UDim.new(0, 30) } }
					},
					CyberButton(scope, { Text = "✕", Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -25, 0, 15), AnchorPoint = Vector2.new(1,0), Color = Color3.fromRGB(255, 50, 80), OnClick = props.OnClose }),

					scope:New "ScrollingFrame" {
						Size = UDim2.new(1, -40, 1, -90), Position = UDim2.new(0, 20, 0, 80),
						BackgroundTransparency = 1, AutomaticCanvasSize = "Y", CanvasSize = UDim2.new(),
						ScrollBarThickness = 6, ScrollBarImageColor3 = Color3.fromRGB(170, 0, 255),
						[Fusion.Children] = {
							scope:New "UIListLayout" { Padding = UDim.new(0, 10) },
							scope:ForValues(props.UnlockedList, function(use, inner, title)
								local isEquipped = use(props.CurrentTitle) == title
								return inner:New "Frame" {
									Size = UDim2.new(1, 0, 0, 55), BackgroundColor3 = Color3.fromRGB(30, 20, 40),
									[Fusion.Children] = {
										inner:New "UICorner" { CornerRadius = UDim.new(0, 10) },
										inner:New "UIStroke" { Color = Color3.fromRGB(100, 50, 150), Thickness = 1 },
										inner:New "TextLabel" {
											Text = title, Size = UDim2.fromScale(0.7, 1), BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 0),
											TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = "Left"
										},
										CyberButton(inner, {
											Text = isEquipped and "EQUIPPED" or "EQUIP",
											Size = UDim2.new(0, 120, 0, 35), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
											Color = isEquipped and Color3.fromRGB(150,150,150) or Color3.fromRGB(255, 200, 0),
											OnClick = function() if not isEquipped then props.OnEquip(title) end end
										})
									}
								}
							end)
						}
					}
				}
			}
		}
	}
end

return AchievementView