local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local ShopView = {}

-- [CYBER BUTTON]
local function CyberButton(scope, props)
	local isHover = scope:Value(false)

	-- Animation Scale
	local scale = scope:Spring(scope:Computed(function(use)
		return use(isHover) and 1.05 or 1
	end), 40, 1)

	return scope:New "TextButton" {
		Text = props.Text or "",
		Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = Color3.fromRGB(20, 25, 35),
		BackgroundTransparency = props.Disabled and 0.5 or 0.2,
		TextColor3 = props.Color or Color3.fromRGB(0, 255, 255),
		Font = Enum.Font.GothamBold, TextSize = 16,
		AutoButtonColor = false,

		[Fusion.OnEvent "MouseEnter"] = function() if not props.Disabled then isHover:set(true) end end,
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		[Fusion.OnEvent "Activated"] = function() if not props.Disabled and props.OnClick then props.OnClick() end end,

		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 6) },
			scope:New "UIStroke" {
				Color = props.Color or Color3.fromRGB(0, 255, 255),
				Thickness = 2,
				Transparency = scope:Computed(function(use) return use(isHover) and 0 or 0.6 end)
			}
		}
	}
end

function ShopView.New(scope, props)
	return scope:New "ScreenGui" {
		Name = "UI_Shop", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			-- Sidebar Button
			CyberButton(scope, {
				Text = "🛒", Size = UDim2.fromOffset(60, 60),
				Position = UDim2.new(0, 20, 0.5, 60),
				Color = Color3.fromRGB(0, 150, 255),
				OnClick = props.OnToggle
			}),

			-- Main Modal
			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.6, 0.7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(15, 20, 25),
				BackgroundTransparency = 0.1,

				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },
					scope:New "UIStroke" { Color = Color3.fromRGB(0, 150, 255), Thickness = 2 },

					-- Header
					scope:New "TextLabel" {
						Text = "CYBER STORE",
						Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(0, 150, 255),
						Font = Enum.Font.GothamBlack, TextSize = 32,
						Position = UDim2.new(0, 20, 0, 0), TextXAlignment = "Left"
					},

					-- Close Button
					CyberButton(scope, {
						Text = "✕", Size = UDim2.fromOffset(40, 40),
						Position = UDim2.new(1, -20, 0, 10), AnchorPoint = Vector2.new(1,0),
						Color = Color3.fromRGB(255, 50, 50),
						OnClick = props.OnClose
					}),

					-- Item Grid
					scope:New "ScrollingFrame" {
						Size = UDim2.new(1, -40, 1, -80), Position = UDim2.new(0, 20, 0, 80),
						BackgroundTransparency = 1, AutomaticCanvasSize = "Y", CanvasSize = UDim2.new(),
						ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255),
						[Fusion.Children] = {
							scope:New "UIGridLayout" { CellSize = UDim2.new(0, 150, 0, 180), CellPadding = UDim2.new(0, 15, 0, 15) },
							scope:ForValues(props.DailyItems, function(use, inner, itemId)
								local itemInfo = GameConfig.GetItemInfo(itemId)
								local price = GameConfig.GetPrice(itemId)
								local owned = use(props.OwnedItems)[itemId] == true

								return inner:New "Frame" {
									BackgroundColor3 = Color3.fromRGB(25, 30, 40),
									[Fusion.Children] = {
										inner:New "UICorner" { CornerRadius = UDim.new(0, 8) },
										inner:New "UIStroke" { Color = Color3.fromRGB(50, 60, 80), Thickness = 1 },

										-- Item Name
										inner:New "TextLabel" {
											Text = itemInfo.Name, Size = UDim2.new(1,0,0.2,0), BackgroundTransparency = 1,
											TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 14,
											Position = UDim2.new(0,0,0.1,0)
										},

										-- Buy Button
										CyberButton(inner, {
											Text = owned and "OWNED" or "$"..price,
											Size = UDim2.new(0.8, 0, 0, 35), Position = UDim2.new(0.5, 0, 0.85, 0), AnchorPoint = Vector2.new(0.5, 0.5),
											Color = owned and Color3.fromRGB(100,100,100) or Color3.fromRGB(0, 255, 100),
											Disabled = owned,
											OnClick = function() if not owned then props.OnBuy(itemId) end end
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

return ShopView