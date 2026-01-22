local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local InventoryView = {}

-- Copy hàm CyberButton từ ShopView sang đây, nhưng đổi default color nếu thích
local function CyberButton(scope, props)
	-- ... (Logic animation giữ nguyên) ...
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 40, 1)

	return scope:New "TextButton" {
		Text = "", -- Nút cha không có text
		-- ... (Các thuộc tính khác giữ nguyên) ...
		Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = Color3.fromRGB(20, 25, 35),
		BackgroundTransparency = props.Disabled and 0.5 or 0,
		AutoButtonColor = false,
		[Fusion.OnEvent "MouseEnter"] = function() if not props.Disabled then isHover:set(true) end end,
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		[Fusion.OnEvent "Activated"] = function() if not props.Disabled then props.OnClick() end end,

		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" {
				Thickness = 2, Transparency = 0,
				[Fusion.Children] = {
					scope:New "UIGradient" {
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, props.Color or Color3.fromRGB(0, 255, 100)),
							ColorSequenceKeypoint.new(1, Color3.new(1,1,1))
						},
						Rotation = 90
					}
				}
			},
			scope:New "TextLabel" {
				-- [FIX] Thêm or ""
				Text = props.Text or "",
				Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
				TextColor3 = props.Color or Color3.fromRGB(0, 255, 100),
				Font = Enum.Font.GothamBlack, TextSize = 16,
				ZIndex = 2
			}
		}
	}
end

function InventoryView.New(scope, props)
	return scope:New "ScreenGui" {
		Name = "UI_Inventory", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			CyberButton(scope, {
				Text = "🎒", Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0, 20, 0.5, 0),
				Color = Color3.fromRGB(0, 255, 100), OnClick = props.OnToggle
			}),

			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.6, 0.7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(15, 18, 25),
				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },
					scope:New "UIStroke" { Thickness = 3, [Fusion.Children] = { scope:New "UIGradient" { Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 100)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 50))}, Rotation = 60 } } },
					scope:New "ImageLabel" { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Image = "rbxassetid://6071575925", ImageColor3 = Color3.fromRGB(0, 255, 100), ImageTransparency = 0.95, ScaleType = "Tile", TileSize = UDim2.new(0, 40, 0, 40), [Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 16) } } },

					scope:New "TextLabel" {
						Text = "INVENTORY", Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(0, 255, 100), Font = Enum.Font.GothamBlack, TextSize = 36,
						TextXAlignment = "Left", [Fusion.Children] = { scope:New "UIPadding" { PaddingLeft = UDim.new(0, 30) } }
					},
					CyberButton(scope, { Text = "✕", Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -25, 0, 15), AnchorPoint = Vector2.new(1,0), Color = Color3.fromRGB(255, 80, 80), OnClick = props.OnClose }),

					scope:New "ScrollingFrame" {
						Size = UDim2.new(1, -40, 1, -90), Position = UDim2.new(0, 20, 0, 80),
						BackgroundTransparency = 1, AutomaticCanvasSize = "Y", CanvasSize = UDim2.new(),
						ScrollBarThickness = 6, ScrollBarImageColor3 = Color3.fromRGB(0, 255, 100),
						[Fusion.Children] = {
							scope:New "UIGridLayout" { CellSize = UDim2.new(0, 120, 0, 120), CellPadding = UDim2.new(0, 10, 0, 10) },
							scope:ForPairs(props.Cosmetics, function(use, inner, itemId, _)
								local isEquipped = use(props.EquippedItem) == itemId
								return itemId, inner:New "Frame" {
									BackgroundColor3 = Color3.fromRGB(25, 30, 40),
									[Fusion.Children] = {
										inner:New "UICorner" { CornerRadius = UDim.new(0,8) },
										inner:New "UIStroke" { Color = isEquipped and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(60, 70, 80), Thickness = isEquipped and 2 or 1 },
										inner:New "TextLabel" { Text = itemId, Size = UDim2.new(1,0,0.3,0), Position = UDim2.fromScale(0,0.6), BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 14 },
										CyberButton(inner, {
											Text = isEquipped and "ON" or "EQ", Size = UDim2.new(0, 50, 0, 30), Position = UDim2.new(1, -5, 0, 5), AnchorPoint = Vector2.new(1,0),
											Color = isEquipped and Color3.fromRGB(255,200,0) or Color3.fromRGB(100,100,100),
											OnClick = function() props.OnEquip(itemId) end
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

return InventoryView