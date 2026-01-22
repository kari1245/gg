local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local EconomyView = {}

function EconomyView.New(scope, props)
	return scope:New "ScreenGui" {
		Name = "UI_Economy",
		ResetOnSpawn = false,
		DisplayOrder = 10, -- Thấp hơn các bảng Popup

		[Fusion.Children] = {
			scope:New "Frame" {
				Name = "MoneyHUD",
				Size = UDim2.new(0, 220, 0, 90),
				Position = UDim2.new(0, 20, 1, -110),
				BackgroundColor3 = Color3.fromRGB(10, 15, 20),
				BackgroundTransparency = 0.2,

				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
					scope:New "UIStroke" {
						Color = Color3.fromRGB(0, 255, 150),
						Thickness = 2,
						Transparency = 0.5
					},
					scope:New "UIPadding" { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 15) },
					scope:New "UIListLayout" { FillDirection = "Vertical", Padding = UDim.new(0, 5) },

					-- Wallet Display
					scope:New "Frame" {
						Size = UDim2.new(1, -15, 0, 30),
						BackgroundTransparency = 1,
						[Fusion.Children] = {
							scope:New "UIListLayout" { FillDirection = "Horizontal", Padding = UDim.new(0, 10), VerticalAlignment = "Center" },
							scope:New "TextLabel" {
								Text = "💳", TextSize = 24, BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 30)
							},
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) return "$" .. (use(props.Wallet) or 0) end),
								TextColor3 = Color3.fromRGB(0, 255, 150),
								Font = Enum.Font.Code, TextSize = 22,
								AutomaticSize = "X", Size = UDim2.fromOffset(0, 30), BackgroundTransparency = 1,
								TextXAlignment = "Left"
							}
						}
					},

					-- Vault Display
					scope:New "Frame" {
						Size = UDim2.new(1, -15, 0, 30),
						BackgroundTransparency = 1,
						[Fusion.Children] = {
							scope:New "UIListLayout" { FillDirection = "Horizontal", Padding = UDim.new(0, 10), VerticalAlignment = "Center" },
							scope:New "TextLabel" {
								Text = "🏦", TextSize = 24, BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 30)
							},
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) return "$" .. (use(props.Vault) or 0) end),
								TextColor3 = Color3.fromRGB(255, 200, 0),
								Font = Enum.Font.Code, TextSize = 22,
								AutomaticSize = "X", Size = UDim2.fromOffset(0, 30), BackgroundTransparency = 1,
								TextXAlignment = "Left"
							}
						}
					}
				}
			}
		}
	}
end

return EconomyView