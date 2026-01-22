local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local AchievementView = {}

local function CyberButton(scope, props)
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 40, 1)
	return scope:New "TextButton" {
		Text = props.Text or "", Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = Color3.fromRGB(20, 25, 35), BackgroundTransparency = 0.2,
		TextColor3 = props.Color or Color3.fromRGB(200, 0, 255), Font = Enum.Font.GothamBold, TextSize = 16,
		[Fusion.OnEvent "MouseEnter"] = function() isHover:set(true) end,
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		[Fusion.OnEvent "Activated"] = props.OnClick,
		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(0,6) },
			scope:New "UIStroke" { Color = props.Color or Color3.fromRGB(200, 0, 255), Thickness = 2, Transparency = scope:Computed(function(use) return use(isHover) and 0 or 0.6 end) }
		}
	}
end

function AchievementView.New(scope, props)
	return scope:New "ScreenGui" {
		Name = "UI_Achievement", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			CyberButton(scope, {
				Text = "🏆", Size = UDim2.fromOffset(60, 60),
				Position = UDim2.new(0, 20, 0.5, -60),
				Color = Color3.fromRGB(200, 0, 255),
				OnClick = props.OnToggle
			}),

			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.5, 0.6), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(15, 20, 25), BackgroundTransparency = 0.1,
				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },
					scope:New "UIStroke" { Color = Color3.fromRGB(200, 0, 255), Thickness = 2 },

					scope:New "TextLabel" {
						Text = "HALL OF FAME", Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(200, 0, 255), Font = Enum.Font.GothamBlack, TextSize = 30,
						Position = UDim2.new(0, 20, 0, 0), TextXAlignment = "Left"
					},
					CyberButton(scope, {
						Text = "✕", Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -20, 0, 10), AnchorPoint = Vector2.new(1,0),
						Color = Color3.fromRGB(255, 50, 50), OnClick = props.OnClose
					}),

					scope:New "ScrollingFrame" {
						Size = UDim2.new(1, -40, 1, -80), Position = UDim2.new(0, 20, 0, 80),
						BackgroundTransparency = 1, AutomaticCanvasSize = "Y", CanvasSize = UDim2.new(),
						ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(200, 0, 255),
						[Fusion.Children] = {
							scope:New "UIListLayout" { Padding = UDim.new(0, 8) },
							scope:ForValues(props.UnlockedList, function(use, inner, title)
								local isEquipped = use(props.CurrentTitle) == title
								return inner:New "Frame" {
									Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Color3.fromRGB(25, 30, 40),
									[Fusion.Children] = {
										inner:New "UICorner" { CornerRadius = UDim.new(0,6) },
										inner:New "UIStroke" { Color = Color3.fromRGB(200, 0, 255), Transparency = 0.5 },
										inner:New "TextLabel" {
											Text = title, Size = UDim2.fromScale(0.7, 1), BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0),
											TextColor3 = Color3.new(1,1,1), Font = Enum.Font.Code, TextSize = 18, TextXAlignment = "Left"
										},
										CyberButton(inner, {
											Text = isEquipped and "EQUIPPED" or "EQUIP",
											Size = UDim2.new(0, 100, 0, 35), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
											Color = isEquipped and Color3.fromRGB(100,100,100) or Color3.fromRGB(255,200,0),
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