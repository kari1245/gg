local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local ShopView = {}

local function CyberButton(scope, props)
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 40, 1)

	return scope:New "TextButton" {
		Text = "", 
		Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = Color3.fromRGB(20, 25, 35),
		BackgroundTransparency = props.Disabled and 0.5 or 0,
		AutoButtonColor = false,
		[Fusion.OnEvent "MouseEnter"] = function() if not props.Disabled then isHover:set(true) end end,
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		[Fusion.OnEvent "Activated"] = function() if not props.Disabled and props.OnClick then props.OnClick() end end,

		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" {
				Thickness = 2, Transparency = 0,
				[Fusion.Children] = {
					scope:New "UIGradient" {
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, props.Color or Color3.fromRGB(0, 255, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
						},
						Rotation = 90
					}
				}
			},
			scope:New "TextLabel" {
				-- [FIX] Thêm or "" để tránh lỗi nil
				Text = props.Text or "",
				Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
				TextColor3 = props.Color or Color3.fromRGB(0, 255, 255),
				Font = Enum.Font.GothamBlack, TextSize = 16,
				ZIndex = 2
			}
		}
	}
end

-- ... (Phần còn lại của ShopView giữ nguyên) ...
function ShopView.New(scope, props)
	return scope:New "ScreenGui" {
		Name = "UI_Shop", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			CyberButton(scope, {
				Text = "🛒", Size = UDim2.fromOffset(60, 60),
				Position = UDim2.new(0, 20, 0.5, 60),
				Color = Color3.fromRGB(0, 200, 255),
				OnClick = props.OnToggle
			}),

			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.65, 0.75), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(15, 18, 25),

				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },
					scope:New "UIStroke" {
						Thickness = 3,
						[Fusion.Children] = {
							scope:New "UIGradient" {
								Color = ColorSequence.new{
									ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
									ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 50, 150))
								},
								Rotation = 60
							}
						}
					},
					scope:New "ImageLabel" {
						Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
						Image = "rbxassetid://6071575925", ImageColor3 = Color3.fromRGB(0, 150, 255), ImageTransparency = 0.95,
						ScaleType = "Tile", TileSize = UDim2.new(0, 40, 0, 40),
						[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 16) } }
					},

					scope:New "TextLabel" {
						Text = "CYBER STORE",
						Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(0, 255, 255),
						Font = Enum.Font.GothamBlack, TextSize = 36,
						[Fusion.Children] = {
							scope:New "UIPadding" { PaddingLeft = UDim.new(0, 30) },
							scope:New "UIStroke" { Thickness = 2, Color = Color3.fromRGB(0, 100, 255), Transparency = 0.8 }
						},
						TextXAlignment = "Left"
					},

					CyberButton(scope, {
						Text = "✕", Size = UDim2.fromOffset(40, 40),
						Position = UDim2.new(1, -25, 0, 15), AnchorPoint = Vector2.new(1,0),
						Color = Color3.fromRGB(255, 80, 80),
						OnClick = props.OnClose
					}),

					scope:New "ScrollingFrame" {
						Size = UDim2.new(1, -40, 1, -90), Position = UDim2.new(0, 20, 0, 80),
						BackgroundTransparency = 1, AutomaticCanvasSize = "Y", CanvasSize = UDim2.new(),
						ScrollBarThickness = 6, ScrollBarImageColor3 = Color3.fromRGB(0, 255, 255),
						[Fusion.Children] = {
							scope:New "UIGridLayout" { CellSize = UDim2.new(0, 160, 0, 200), CellPadding = UDim2.new(0, 15, 0, 15) },

							scope:ForValues(props.DailyItems, function(use, inner, itemId)
								local itemInfo = GameConfig.GetItemInfo(itemId)
								local price = GameConfig.GetPrice(itemId)
								local owned = use(props.OwnedItems)[itemId] == true

								return inner:New "Frame" {
									BackgroundColor3 = Color3.fromRGB(25, 30, 40),
									[Fusion.Children] = {
										inner:New "UICorner" { CornerRadius = UDim.new(0, 10) },
										inner:New "UIStroke" { Color = Color3.fromRGB(50, 60, 80), Thickness = 1 },

										inner:New "TextLabel" {
											Text = itemInfo.Name, Size = UDim2.new(1,0,0.2,0), BackgroundTransparency = 1,
											TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 16,
											Position = UDim2.new(0,0,0.05,0)
										},

										inner:New "ImageLabel" {
											Image = itemInfo.Image or "",
											Size = UDim2.fromScale(0.5, 0.4), Position = UDim2.fromScale(0.5, 0.4), AnchorPoint = Vector2.new(0.5, 0.5),
											BackgroundTransparency = 1, ImageColor3 = Color3.new(1,1,1)
										},

										CyberButton(inner, {
											Text = owned and "OWNED" or "$"..price,
											Size = UDim2.new(0.85, 0, 0, 40), Position = UDim2.new(0.5, 0, 0.88, 0), AnchorPoint = Vector2.new(0.5, 0.5),
											Color = owned and Color3.fromRGB(150,150,150) or Color3.fromRGB(0, 255, 100),
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