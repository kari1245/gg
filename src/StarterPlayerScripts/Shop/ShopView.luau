local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local ShopView = {}
local Theme = GameConfig.CyberTheme

-- Cyber Button với hiệu ứng neon và glitch
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
			-- [FIX 2] Dùng peek để check đúng giá trị
			if not Fusion.peek(props.Disabled) then isHover:set(true) end 
		end,
		
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		
		[Fusion.OnEvent "Activated"] = function() 
			-- [FIX 3] QUAN TRỌNG NHẤT: Dùng peek để lấy giá trị boolean
			local isDisabled = Fusion.peek(props.Disabled)
			
			if not isDisabled and props.OnClick then 
				props.OnClick() -- Gọi hàm mua
			end 
		end,
		
		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" {
				Thickness = 2.5,
				Color = props.Color or Theme.NeonCyan,
				Transparency = 0,
				[Fusion.Children] = {
					scope:New "UIGradient" {
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, props.Color or Theme.NeonCyan),
							ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)),
							ColorSequenceKeypoint.new(1, props.Color or Theme.NeonCyan)
						},
						Rotation = 90
					}
				}
			},
			-- Neon glow shadow
			scope:New "ImageLabel" {
				Size = UDim2.fromScale(1.2, 1.2), Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
				Image = "rbxassetid://5028857084", ImageColor3 = props.Color or Theme.NeonCyan,
				ImageTransparency = 0.6, ZIndex = -1
			},
			scope:New "TextLabel" {
				Text = props.Text or "",
				Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
				TextColor3 = props.Color or Theme.NeonCyan,
				Font = Enum.Font.Code, TextSize = 16,
				TextStrokeTransparency = 0.5,
				TextStrokeColor3 = props.Color or Theme.NeonCyan,
				ZIndex = 2
			}
		}
	}
end

function ShopView.New(scope, props)
	local inspectItem = scope:Value(nil)
	
	return scope:New "ScreenGui" {
		Name = "UI_Shop", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			CyberButton(scope, {
				Text = "◢ NFT", Size = UDim2.new(0.065, 0, 0.09, 0), Position = UDim2.new(0.015, 0, 0.23, 0),
				Color = Theme.NeonCyan, OnClick = props.OnToggle
			}),

			-- SHOP MODAL với holographic effect
			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.75, 0.75), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Theme.DarkBg,
				BackgroundTransparency = 0.1,
				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 20) },
					scope:New "UIAspectRatioConstraint" { AspectRatio = 1.0 },
					scope:New "UIStroke" { Thickness = 3, Color = Theme.NeonCyan, Transparency = 0 },
					
					-- Grid pattern background
					scope:New "ImageLabel" {
						Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, ZIndex = 0,
						Image = "rbxassetid://6071575925",
						ImageColor3 = Theme.GridColor, ImageTransparency = 0.92,
						ScaleType = "Tile", TileSize = UDim2.fromOffset(50, 50),
						[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 20) } }
					},
					
					-- Header với glitch effect
					scope:New "TextLabel" { 
						Text = "◢◤ NFT MARKETPLACE ◥◣", 
						Size = UDim2.new(1, 0, 0.09, 0), BackgroundTransparency = 1, 
						TextColor3 = Theme.NeonCyan, 
						Font = Enum.Font.Code, TextScaled = true,
						TextStrokeTransparency = 0.3,
						TextStrokeColor3 = Theme.NeonMagenta,
						ZIndex = 2
					},
					CyberButton(scope, { Text = "✕", Size = UDim2.new(0.065, 0, 0.09, 0), Position = UDim2.new(0.98, 0, 0.015, 0), AnchorPoint = Vector2.new(1,0), Color = Theme.GlitchRed, OnClick = props.OnClose }),

					scope:New "ScrollingFrame" {
						Size = UDim2.new(1, -30, 1, -80), Position = UDim2.new(0, 15, 0, 70),
						BackgroundTransparency = 1, AutomaticCanvasSize = "Y", CanvasSize = UDim2.new(),
						ScrollBarThickness = 8, ScrollBarImageColor3 = Theme.NeonCyan,
						[Fusion.Children] = {
							scope:New "UIGridLayout" { CellSize = UDim2.fromScale(0.27, 0.18), CellPadding = UDim2.fromOffset(15, 15) },
							scope:ForValues(props.DailyItems, function(use, inner, item)
								local rarityInfo = GameConfig.NftRarities[item.Rarity] or GameConfig.NftRarities.Common
								local color = rarityInfo.Color
								local sold = item.Sold == true
								
								return inner:New "TextButton" {
									BackgroundColor3 = Theme.MidBg,
									BackgroundTransparency = 0.3,
									AutoButtonColor = false,
									[Fusion.OnEvent "Activated"] = function() inspectItem:set(item) end,
									[Fusion.Children] = {
										inner:New "UICorner" { CornerRadius = UDim.new(0, 12) },
										inner:New "UIStroke" { 
											Color = color, Thickness = 3, 
											Transparency = sold and 0.8 or 0 
										},
										-- Hologram glow
										inner:New "ImageLabel" {
											Size = UDim2.fromScale(1.1, 1.1), Position = UDim2.fromScale(0.5, 0.5),
											AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
											Image = "rbxassetid://5028857084", ImageColor3 = color,
											ImageTransparency = sold and 0.9 or 0.7, ZIndex = 0
										},
										-- Hash label
										inner:New "TextLabel" {
											Text = "► " .. string.sub(item.Hash, 1, 8) .. "...", 
												Size = UDim2.new(1, 0, 0.4, 0), Position = UDim2.fromScale(0, 0.15),
												BackgroundTransparency = 1, TextColor3 = color, 
												Font = Enum.Font.Code, TextScaled = true,
											TextStrokeTransparency = 0.6,
											ZIndex = 2
										},
										-- Price label
										inner:New "TextLabel" {
											Text = sold and "▼ SOLD OUT" or "▲ $"..item.Price,
												Size = UDim2.new(1, 0, 0.3, 0), Position = UDim2.fromScale(0, 0.6),
												BackgroundTransparency = 1, 
												TextColor3 = sold and Color3.fromRGB(100,100,100) or Theme.NeonGreen, 
												Font = Enum.Font.GothamBold, TextScaled = true,
											TextStrokeTransparency = sold and 1 or 0.5,
											ZIndex = 2
										}
									}
								}
							end)
						}
					}
				}
			},

			-- INSPECT MODAL - Holographic style
			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(inspectItem) ~= nil end),
				Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.3, ZIndex = 10,
				[Fusion.Children] = {
					scope:New "Frame" {
						Size = UDim2.fromScale(0.7, 0.5), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Theme.DarkBg,
						BackgroundTransparency = 0.1,
						[Fusion.Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },
							scope:New "UIAspectRatioConstraint" { AspectRatio = 1.3 },
							scope:New "UIStroke" { 
								Color = scope:Computed(function(use)
									local item = use(inspectItem)
									return item and (GameConfig.NftRarities[item.Rarity] or {}).Color or Theme.NeonCyan
								end),
								Thickness = 4
							},
							
							-- Grid background
							scope:New "ImageLabel" {
								Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
								Image = "rbxassetid://6071575925",
								ImageColor3 = scope:Computed(function(use)
									local item = use(inspectItem)
									return item and (GameConfig.NftRarities[item.Rarity] or {}).Color or Theme.GridColor
								end),
								ImageTransparency = 0.9,
								ScaleType = "Tile", TileSize = UDim2.fromOffset(40, 40),
								ZIndex = 0,
								[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 16) } }
							},
							
							-- Header
							scope:New "TextLabel" {
								Text = "◢ NFT DATA ◣",
								Size = UDim2.new(1, 0, 0.14, 0), Position = UDim2.fromScale(0, 0.02),
								BackgroundTransparency = 1, TextColor3 = Theme.NeonCyan,
								Font = Enum.Font.Code, TextScaled = true,
								TextStrokeTransparency = 0.5,
								ZIndex = 2
							},
							
							-- Hash text
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) 
									local item = use(inspectItem)
									return item and ("► HASH:\n" .. item.Hash) or "" 
								end),
								Size = UDim2.new(0.9, 0, 0.31, 0), Position = UDim2.new(0.05, 0, 0.2, 0),
								BackgroundTransparency = 1, 
								TextColor3 = scope:Computed(function(use)
									local item = use(inspectItem)
									return item and (GameConfig.NftRarities[item.Rarity] or {}).Color or Theme.NeonCyan
								end),
								Font = Enum.Font.Code, TextScaled = true, TextWrapped = true,
								TextXAlignment = "Left", TextYAlignment = "Top",
								TextStrokeTransparency = 0.7,
								ZIndex = 2
							},
							
							-- Rarity badge
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) 
									local item = use(inspectItem)
									return item and ("◤ " .. item.Rarity:upper() .. " ◥") or "" 
								end),
								Size = UDim2.new(0.8, 0, 0.11, 0), Position = UDim2.fromScale(0.1, 0.55),
								BackgroundTransparency = 1,
								TextColor3 = scope:Computed(function(use)
									local item = use(inspectItem)
									return item and (GameConfig.NftRarities[item.Rarity] or {}).Color or Color3.new(1,1,1)
								end), 
								Font = Enum.Font.GothamBlack, TextScaled = true,
								TextStrokeTransparency = 0.3,
								ZIndex = 2
							},

							-- Buy button với cyber glow
							CyberButton(scope, {
								Text = scope:Computed(function(use) 
									local item = use(inspectItem)
									return item and (item.Sold and "▼ SOLD" or "▲ BUY ($"..item.Price..")") or ""
								end),
								Size = UDim2.new(0.5, 0, 0, 55), Position = UDim2.new(0.25, 0, 0.72, 0),
								Color = Theme.NeonGreen,
								Disabled = scope:Computed(function(use) local item = use(inspectItem); return item and item.Sold end),
								OnClick = function() 
									local item = Fusion.peek(inspectItem)
									if item and not item.Sold then 
										props.OnBuy(item.Hash) 
										inspectItem:set(nil)
									end
								end
							}),
							
							CyberButton(scope, {
								Text = "✕ CLOSE", Size = UDim2.new(0.3, 0, 0, 35), Position = UDim2.new(0.35, 0, 0.9, 0),
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

return ShopView