local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local NftEarningView = {}
local Theme = GameConfig.CyberTheme
local EarningConfig = GameConfig.NftEarning

-- Cyber Button
local function CyberButton(scope, props)
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 40, 1)

	return scope:New "TextButton" {
		Text = "", Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = Theme.DarkBg,
		BackgroundTransparency = props.Disabled and 0.7 or 0.2,
		AutoButtonColor = false,
		[Fusion.OnEvent "MouseEnter"] = function() if not props.Disabled then isHover:set(true) end end,
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		[Fusion.OnEvent "Activated"] = function() if not props.Disabled and props.OnClick then props.OnClick() end end,

		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" {
				Thickness = 2.5,
				Color = props.Color or Theme.NeonCyan,
				Transparency = 0
			},
			scope:New "ImageLabel" {
				Size = UDim2.fromScale(1.15, 1.15), Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
				Image = "rbxassetid://5028857084",
				ImageColor3 = props.Color or Theme.NeonCyan,
				ImageTransparency = 0.65, ZIndex = -1
			},
			scope:New "TextLabel" {
				Text = props.Text or "", Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
				TextColor3 = props.Color or Theme.NeonCyan,
			Font = Enum.Font.Code, TextSize = 16,
				TextStrokeTransparency = 0.5, ZIndex = 2,
				[Fusion.Children] = {
					scope:New "UIPadding" {
						PaddingLeft = UDim.new(0.1, 0),
						PaddingRight = UDim.new(0.1, 0),
						PaddingTop = UDim.new(0.2, 0),
						PaddingBottom = UDim.new(0.2, 0)
					}
				}
			}
		}
	}
end

-- NFT Card Component
-- NFT Card with dynamic EQUIP/UNEQUIP button
local function NftCard(scope, nft, props)
	local rarityData = GameConfig.NftRarities[nft.Rarity]
	local hourlyRate = EarningConfig.Earning[nft.Rarity].HourlyRate
	-- Generate display name from rarity + shortened hash
	local displayName = rarityData.Name .. " #" .. string.sub(nft.Hash, 1, 6)
	local isEquipped = nft.IsEquipped
	
	return scope:New "Frame" {
		Size = UDim2.new(1, -10, 0, 80),
		BackgroundColor3 = isEquipped and Theme.MidBg or Theme.DarkBg,
		BackgroundTransparency = 0.2,
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" {
				Color = rarityData.Color,
				Thickness = isEquipped and 3 or 2,
				Transparency = isEquipped and 0 or 0.3
			},
			
			-- NFT Info
			scope:New "TextLabel" {
				Text = displayName,
				Position = UDim2.fromOffset(10, 5),
				Size = UDim2.new(1, -140, 0, 22),
				BackgroundTransparency = 1,
				TextColor3 = rarityData.Color,
				Font = Enum.Font.Code,
				TextSize = 14,
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left
			},
			
			scope:New "TextLabel" {
				Text = rarityData.Name .. (isEquipped and " [EQUIPPED]" or ""),
				Position = UDim2.fromOffset(10, 32),
				Size = UDim2.new(0.5, 0, 0, 18),
				BackgroundTransparency = 1,
				TextColor3 = isEquipped and Theme.NeonGreen or rarityData.Color,
				Font = Enum.Font.Code,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left
			},
			
			-- Passive Income
			scope:New "TextLabel" {
				Text = "◈ $"..hourlyRate.."/h" .. (isEquipped and " [ACTIVE]" or " [IDLE]"),
				Position = UDim2.fromOffset(10, 54),
				Size = UDim2.new(0.5, 0, 0, 18),
				BackgroundTransparency = 1,
				TextColor3 = isEquipped and Theme.NeonGreen or Theme.GridColor,
				Font = Enum.Font.Code,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left
			},
			
			-- EQUIP/UNEQUIP Button
			CyberButton(scope, {
				Text = isEquipped and "▼ UNEQUIP" or "▲ EQUIP",
				Size = UDim2.fromOffset(100, 30),
				Position = UDim2.new(1, -110, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Color = isEquipped and Theme.GlitchRed or Theme.NeonCyan,
				OnClick = function() props.OnToggleEquip(nft.Hash, isEquipped) end
			})
		}
	}
end

function NftEarningView.New(scope, props)
	return scope:New "ScreenGui" {
		Name = "UI_NftEarning", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			-- Sidebar Button
			CyberButton(scope, {
				Text = "◆ NFT",
				Size = UDim2.fromScale(0.065, 0.09),
				Position = UDim2.fromScale(0.015, 0.53),
				Color = Theme.NeonPurple,
				OnClick = props.OnToggle
			}),

			-- Main Panel
			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.9, 0.8),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Theme.DarkBg,
				BackgroundTransparency = 0.1,

				[Fusion.Children] = {
					scope:New "UIAspectRatioConstraint" { AspectRatio = 1.5 },
					scope:New "UICorner" { CornerRadius = UDim.new(0, 20) },
					scope:New "UIStroke" {
						Thickness = 3.5,
						Color = Theme.NeonPurple,
						Transparency = 0
					},

					-- Grid Background
					scope:New "ImageLabel" {
						Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
						Image = "rbxassetid://6071575925",
						ImageColor3 = Theme.NeonPurple, ImageTransparency = 0.91,
						ScaleType = "Tile", TileSize = UDim2.fromOffset(45, 45),
						ZIndex = 0,
						[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 20) } }
					},

					-- Header
					scope:New "TextLabel" {
						Text = "◢ NFT EARNING SYSTEM ◣",
						Size = UDim2.new(1, 0, 0.08, 0),
						Position = UDim2.fromScale(0, 0.02),
						BackgroundTransparency = 1,
						TextColor3 = Theme.NeonPurple,
						Font = Enum.Font.Code,
						TextSize = 22,
						TextScaled = true,
						TextStrokeTransparency = 0.3,
						ZIndex = 2
					},

					-- Close Button
					CyberButton(scope, {
						Text = "✕",
						Size = UDim2.fromOffset(40, 40),
						Position = UDim2.new(1, -50, 0, 20),
						AnchorPoint = Vector2.new(0, 0),
						Color = Theme.GlitchRed,
						OnClick = props.OnClose
					}),

					-- NFT List Label
					scope:New "TextLabel" {
						Text = "💎 ALL NFTs (Sorted by Rarity) - Equip to Auto-Earn",
						Position = UDim2.fromScale(0.02, 0.12),
						Size = UDim2.new(0.96, 0, 0.06, 0),
						BackgroundTransparency = 1,
						TextColor3 = Theme.NeonPurple,
						Font = Enum.Font.Code,
						TextSize = 14,
						TextScaled = true,
						TextXAlignment = Enum.TextXAlignment.Left
					},

					-- NFT List (Scrollable)
					scope:New "ScrollingFrame" {
						Position = UDim2.fromScale(0.02, 0.19),
						Size = UDim2.new(0.96, 0, 0.77, 0),
						BackgroundColor3 = Theme.MidBg,
						BackgroundTransparency = 0.5,
						BorderSizePixel = 0,
						ScrollBarThickness = 8,
						[Fusion.Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
							scope:New "UIListLayout" {
								Padding = UDim.new(0, 8),
								SortOrder = Enum.SortOrder.LayoutOrder,
								HorizontalAlignment = Enum.HorizontalAlignment.Center
							},
							scope:New "UIPadding" {
								PaddingTop = UDim.new(0, 10),
								PaddingBottom = UDim.new(0, 10)
							},
							
							-- All NFTs sorted by rarity
							scope:ForValues(props.AllNfts, function(use, scope, nft)
								return NftCard(scope, nft, {
									OnToggleEquip = props.OnToggleEquip
								})
							end)
						}
					}
				}
			}
		}
	}
end

return NftEarningView
