local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local InventoryView = {}

local function CyberButton(scope, props)
	-- ... (Copy hàm CyberButton y hệt ShopView)
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 40, 1)
	return scope:New "TextButton" {
		Text = "", Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = Color3.fromRGB(20, 25, 35), BackgroundTransparency = props.Disabled and 0.5 or 0,
		[Fusion.OnEvent "MouseEnter"] = function() if not props.Disabled then isHover:set(true) end end,
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		[Fusion.OnEvent "Activated"] = function() if not props.Disabled and props.OnClick then props.OnClick() end end,
		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale }, scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" { Thickness = 2, Transparency = 0, [Fusion.Children] = { scope:New "UIGradient" { Color = ColorSequence.new{ColorSequenceKeypoint.new(0, props.Color or Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.new(0,0,0))}, Rotation = 90 } } },
			scope:New "TextLabel" { Text = props.Text or "", Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, TextColor3 = props.Color, Font = Enum.Font.GothamBlack, TextSize = 14, ZIndex = 2 }
		}
	}
end

function InventoryView.New(scope, props)
	local inspectItem = scope:Value(nil)

	return scope:New "ScreenGui" {
		Name = "UI_Inventory", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			CyberButton(scope, {
				Text = "🎒", Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0, 20, 0.5, 0),
				Color = Color3.fromRGB(0, 255, 100), OnClick = props.OnToggle
			}),

			-- INVENTORY MODAL
			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.6, 0.7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(15, 18, 25),
				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },
					scope:New "UIStroke" { Thickness = 3, Color = Color3.fromRGB(0, 255, 100) },

					scope:New "TextLabel" { Text = "YOUR WALLET", Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(0, 255, 100), Font = Enum.Font.GothamBlack, TextSize = 36 },
					CyberButton(scope, { Text = "✕", Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -25, 0, 15), AnchorPoint = Vector2.new(1,0), Color = Color3.fromRGB(255, 80, 80), OnClick = props.OnClose }),

					scope:New "ScrollingFrame" {
						Size = UDim2.new(1, -40, 1, -90), Position = UDim2.new(0, 20, 0, 80),
						BackgroundTransparency = 1, AutomaticCanvasSize = "Y", CanvasSize = UDim2.new(),
						[Fusion.Children] = {
							scope:New "UIGridLayout" { CellSize = UDim2.new(0, 150, 0, 100), CellPadding = UDim2.new(0, 10, 0, 10) },
							scope:ForValues(props.NftList, function(use, inner, item)
								local color = GameConfig.NftRarities[item.Rarity].Color
								return inner:New "TextButton" {
									BackgroundColor3 = Color3.fromRGB(25, 30, 40), AutoButtonColor = false,
									[Fusion.OnEvent "Activated"] = function() inspectItem:set(item) end,
									[Fusion.Children] = {
										inner:New "UICorner" { CornerRadius = UDim.new(0,8) },
										inner:New "UIStroke" { Color = color, Thickness = 2 },
										inner:New "TextLabel" { Text = string.sub(item.Hash, 1, 6).."...", Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, TextColor3 = color, Font = Enum.Font.Code, TextSize = 18 }
									}
								}
							end)
						}
					}
				}
			},
			
			-- INSPECT MODAL (Tương tự Shop nhưng không có nút mua)
			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(inspectItem) ~= nil end),
				Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.5, ZIndex = 10,
				[Fusion.Children] = {
					scope:New "Frame" {
						Size = UDim2.fromOffset(400, 250), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(15, 20, 25),
						[Fusion.Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
							scope:New "UIStroke" { Color = Color3.fromRGB(0, 255, 100), Thickness = 2 },
							
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) local item = use(inspectItem); return item and ("HASH: " .. item.Hash) or "" end),
								Size = UDim2.new(0.9, 0, 0, 100), Position = UDim2.new(0.05, 0, 0.1, 0),
								BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(0, 255, 100), Font = Enum.Font.Code, TextSize = 24, TextWrapped = true
							},
							
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) local item = use(inspectItem); return item and ("RARITY: " .. item.Rarity:upper()) or "" end),
								Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromScale(0, 0.6),
								BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBlack, TextSize = 20
							},
							
							CyberButton(scope, {
								Text = "CLOSE", Size = UDim2.new(0.3, 0, 0, 40), Position = UDim2.new(0.35, 0, 0.8, 0),
								Color = Color3.fromRGB(255, 255, 255),
								OnClick = function() inspectItem:set(nil) end
							})
						}
					}
				}
			}
		}
	}
end

return InventoryView