local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local EconomyView = {}
local Theme = GameConfig.CyberTheme

function EconomyView.New(scope, props)
	return scope:New "ScreenGui" {
		Name = "UI_Economy", ResetOnSpawn = false, DisplayOrder = 10,
		[Fusion.Children] = {
			scope:New "Frame" {
				Name = "MoneyCard",
				Size = UDim2.fromScale(0.18, 0.14),
				Position = UDim2.fromScale(0.015, 0.84),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Theme.DarkBg,
				BackgroundTransparency = 0.15,

				[Fusion.Children] = {
					scope:New "UIAspectRatioConstraint" { AspectRatio = 1.3 },
					scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
					scope:New "UIStroke" {
						Thickness = 2.5,
						Color = Theme.NeonCyan,
						Transparency = 0
					},

					-- Grid background
					scope:New "ImageLabel" {
						Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
						Image = "rbxassetid://6071575925",
						ImageColor3 = Theme.NeonCyan, ImageTransparency = 0.9,
						ScaleType = "Tile", TileSize = UDim2.fromOffset(30, 30),
						ZIndex = 0,
						[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 12) } }
					},

					-- Content
					scope:New "Frame" {
						Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2,
						[Fusion.Children] = {
							scope:New "UIPadding" { 
								PaddingLeft = UDim.new(0.05, 0), 
								PaddingRight = UDim.new(0.05, 0),
								PaddingTop = UDim.new(0.15, 0),
								PaddingBottom = UDim.new(0.1, 0)
							},
							scope:New "UIListLayout" { 
								FillDirection = "Vertical", 
								Padding = UDim.new(0.08, 0),
								HorizontalAlignment = "Center"
							},

							-- Wallet
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) return "▸ $" .. (use(props.Wallet) or 0) end),
								TextColor3 = Theme.NeonCyan,
								Font = Enum.Font.Code, TextScaled = true,
								Size = UDim2.new(1, 0, 0.35, 0), BackgroundTransparency = 1,
								TextStrokeTransparency = 0.5,
								ZIndex = 3
							},

							-- Vault
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) return "▼ $" .. (use(props.Vault) or 0) end),
								TextColor3 = Theme.NeonPink,
								Font = Enum.Font.Code, TextScaled = true,
								Size = UDim2.new(1, 0, 0.35, 0), BackgroundTransparency = 1,
								TextStrokeTransparency = 0.5,
								ZIndex = 3
							}
						}
					}
				}
			}
		}
	}
end

return EconomyView