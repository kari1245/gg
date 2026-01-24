local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local InventoryView = {}
local Theme = GameConfig.CyberTheme

local function CyberButton(scope, props)
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 40, 1)
	
	return scope:New "TextButton" {
		Text = "", Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = Theme.DarkBg, BackgroundTransparency = props.Disabled and 0.7 or 0.2,
		AutoButtonColor = false,
		[Fusion.OnEvent "MouseEnter"] = function() if not props.Disabled then isHover:set(true) end end,
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		[Fusion.OnEvent "Activated"] = function() if not props.Disabled and props.OnClick then props.OnClick() end end,
		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" { Thickness = 2.5, Color = props.Color or Theme.NeonGreen, Transparency = 0 },
			scope:New "ImageLabel" {
				Size = UDim2.fromScale(1.15, 1.15), Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
				Image = "rbxassetid://5028857084", ImageColor3 = props.Color or Theme.NeonGreen,
				ImageTransparency = 0.65, ZIndex = -1
			},
			scope:New "TextLabel" { 
				Text = props.Text or "", Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, 
				TextColor3 = props.Color or Theme.NeonGreen, Font = Enum.Font.Code, TextSize = 16,
				TextStrokeTransparency = 0.5, ZIndex = 2 
			}
		}
	}
end

function InventoryView.New(scope, props)
	local inspectItem = scope:Value(nil)

	return scope:New "ScreenGui" {
		Name = "UI_Inventory", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			CyberButton(scope, {
				Text = "▦ INV", Size = UDim2.new(0.065, 0, 0.09, 0), Position = UDim2.new(0.015, 0, 0.33, 0),
				Color = Theme.NeonGreen, OnClick = props.OnToggle
			}),

			-- INVENTORY MODAL
			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.65, 0.75), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Theme.DarkBg,
				BackgroundTransparency = 0.1,
				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 20) },

					-- Grid background
					scope:New "ImageLabel" {
						Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
						Image = "rbxassetid://6071575925", ImageColor3 = Theme.NeonGreen, ImageTransparency = 0.90,
						ScaleType = "Tile", TileSize = UDim2.fromOffset(45, 45), ZIndex = 0,
						[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 20) } }
					},

					-- Header
					scope:New "TextLabel" { 
						Text = "◢◤ YOUR WALLET ◥◣", 
						Size = UDim2.new(0.6, 0, 0.095, 0), BackgroundTransparency = 1, 
						TextColor3 = Theme.NeonGreen, Font = Enum.Font.Code, TextScaled = true,
						TextStrokeTransparency = 0.4, TextStrokeColor3 = Theme.NeonCyan,
						ZIndex = 2
					},
					
					-- Total NFT Value
					scope:New "TextLabel" { 
						Text = scope:Computed(function(use)
							local list = use(props.NftList)
							local total = 0
							for _, item in list do
								total += item.Price or 0
							end
							local formatted
							if total >= 1e10 then
								if total >= 1e12 then formatted = string.format("%.2fT", total/1e12)
								elseif total >= 1e9 then formatted = string.format("%.2fB", total/1e9)
								elseif total >= 1e6 then formatted = string.format("%.2fM", total/1e6)
								else formatted = string.format("%.2fK", total/1e3) end
							else
								formatted = tostring(total):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
							end
							return "◈ TOTAL: $" .. formatted
						end),
						Size = UDim2.new(0.38, 0, 0.095, 0), Position = UDim2.new(0.61, 0, 0, 0), BackgroundTransparency = 1, 
						TextColor3 = Theme.GoldYellow, Font = Enum.Font.Code, TextScaled = true,
						TextStrokeTransparency = 0.4, TextStrokeColor3 = Theme.GoldYellow,
						ZIndex = 2
					},
					
					CyberButton(scope, { 
						Text = "✕", Size = UDim2.new(0.065, 0, 0.09, 0), Position = UDim2.new(0.98, 0, 0.015, 0), 
						AnchorPoint = Vector2.new(1,0), Color = Theme.GlitchRed, OnClick = props.OnClose 
					}),

					scope:New "ScrollingFrame" {
						Size = UDim2.new(1, -45, 1, -95), Position = UDim2.fromOffset(22, 82),
						BackgroundTransparency = 1, AutomaticCanvasSize = "Y", CanvasSize = UDim2.new(),
						ScrollBarThickness = 8, ScrollBarImageColor3 = Theme.NeonGreen,
						[Fusion.Children] = {
							scope:New "UIGridLayout" { 
								CellSize = UDim2.fromScale(0.27, 0.16), 
								CellPadding = UDim2.fromOffset(15, 15) 
							},
							scope:ForValues(props.NftList, function(use, inner, item)
								local color = GameConfig.NftRarities[item.Rarity].Color
								local formattedPrice
								local price = item.Price or 0
								if price >= 1e10 then
									if price >= 1e12 then formattedPrice = string.format("%.1fT", price/1e12)
									elseif price >= 1e9 then formattedPrice = string.format("%.1fB", price/1e9)
									elseif price >= 1e6 then formattedPrice = string.format("%.1fM", price/1e6)
									else formattedPrice = string.format("%.1fK", price/1e3) end
								else
									formattedPrice = tostring(price):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
								end
								return inner:New "TextButton" {
									BackgroundColor3 = Theme.MidBg,
									BackgroundTransparency = 0.3,
									AutoButtonColor = false,
									[Fusion.OnEvent "Activated"] = function() inspectItem:set(item) end,
									[Fusion.Children] = {
										inner:New "UICorner" { CornerRadius = UDim.new(0, 12) },
										inner:New "UIStroke" { Color = color, Thickness = 3 },
										inner:New "ImageLabel" {
											Size = UDim2.fromScale(1.08, 1.08), Position = UDim2.fromScale(0.5, 0.5),
											AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
											Image = "rbxassetid://5028857084", ImageColor3 = color,
											ImageTransparency = 0.75, ZIndex = 0
										},
										inner:New "TextLabel" { 
											Text = "▸ " .. string.sub(item.Hash, 1, 6) .. "...", 
											Size = UDim2.new(1, 0, 0.5, 0), BackgroundTransparency = 1, 
											TextColor3 = color, Font = Enum.Font.Code, TextScaled = true,
											TextStrokeTransparency = 0.6, ZIndex = 2
										},
										inner:New "TextLabel" { 
											Text = "$" .. formattedPrice, 
											Size = UDim2.new(1, 0, 0.4, 0), Position = UDim2.new(0, 0, 0.57, 0), BackgroundTransparency = 1, 
											TextColor3 = Theme.GoldYellow, Font = Enum.Font.Code, TextScaled = true,
											TextStrokeTransparency = 0.6, ZIndex = 2
										}
									}
								}
							end)
						}
					}
				}
			},
			
			-- INSPECT MODAL
			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(inspectItem) ~= nil end),
				Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.3, ZIndex = 10,
				[Fusion.Children] = {
					scope:New "Frame" {
						Size = UDim2.fromScale(0.65, 0.42), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Theme.DarkBg,
						BackgroundTransparency = 0.1,
						[Fusion.Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },
							scope:New "UIAspectRatioConstraint" { AspectRatio = 1.4 },
							scope:New "UIStroke" { 
								Color = scope:Computed(function(use)
									local item = use(inspectItem)
									return item and (GameConfig.NftRarities[item.Rarity] or {}).Color or Theme.NeonGreen
								end),
								Thickness = 4
							},
							
							-- Grid background
							scope:New "ImageLabel" {
								Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
								Image = "rbxassetid://6071575925",
								ImageColor3 = scope:Computed(function(use)
									local item = use(inspectItem)
									return item and (GameConfig.NftRarities[item.Rarity] or {}).Color or Theme.NeonGreen
								end),
								ImageTransparency = 0.9, ScaleType = "Tile", TileSize = UDim2.fromOffset(40, 40),
								ZIndex = 0,
								[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 16) } }
							},
							
							-- Header
							scope:New "TextLabel" {
								Text = "◢ NFT DATA ◣",
								Size = UDim2.new(1, 0, 0.17, 0), BackgroundTransparency = 1,
								TextColor3 = Theme.NeonGreen, Font = Enum.Font.Code, TextScaled = true,
								TextStrokeTransparency = 0.5, ZIndex = 2
							},
							
							-- Hash
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) 
									local item = use(inspectItem)
									return item and ("▸ HASH:\n" .. item.Hash) or "" 
								end),
								Size = UDim2.new(0.9, 0, 0.37, 0), Position = UDim2.new(0.05, 0, 0.2, 0),
								BackgroundTransparency = 1, 
								TextColor3 = scope:Computed(function(use)
									local item = use(inspectItem)
									return item and (GameConfig.NftRarities[item.Rarity] or {}).Color or Theme.NeonGreen
								end),
								Font = Enum.Font.Code, TextScaled = true, TextWrapped = true,
								TextXAlignment = "Left", TextYAlignment = "Top",
								TextStrokeTransparency = 0.7, ZIndex = 2
							},
							
							-- Rarity
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) 
									local item = use(inspectItem)
									return item and ("◤ " .. item.Rarity:upper() .. " ◥") or "" 
								end),
								Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.fromScale(0, 0.59),
								BackgroundTransparency = 1,
								TextColor3 = scope:Computed(function(use)
									local item = use(inspectItem)
									return item and (GameConfig.NftRarities[item.Rarity] or {}).Color or Theme.NeonGreen
								end),
								Font = Enum.Font.GothamBlack, TextScaled = true,
								TextStrokeTransparency = 0.3, ZIndex = 2
							},
							
							-- Price
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) 
									local item = use(inspectItem)
									if not item then return "" end
									local price = item.Price or 0
									local formatted
									if price >= 1e10 then
										if price >= 1e12 then formatted = string.format("%.2fT", price/1e12)
										elseif price >= 1e9 then formatted = string.format("%.2fB", price/1e9)
										elseif price >= 1e6 then formatted = string.format("%.2fM", price/1e6)
										else formatted = string.format("%.2fK", price/1e3) end
									else
										formatted = tostring(price):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
									end
									return "◈ VALUE: $" .. formatted
								end),
								Size = UDim2.new(1, 0, 0.11, 0), Position = UDim2.fromScale(0, 0.71),
								BackgroundTransparency = 1,
								TextColor3 = Theme.GoldYellow,
								Font = Enum.Font.Code, TextScaled = true,
								TextStrokeTransparency = 0.4, ZIndex = 2
							},
							
							CyberButton(scope, {
							Text = "◆ CLOSE", Size = UDim2.fromScale(0.35, 0.1), Position = UDim2.fromScale(0.325, 0.82),
								Color = Theme.GlitchRed,
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