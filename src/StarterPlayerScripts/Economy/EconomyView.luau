local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local EconomyView = {}

function EconomyView.New(scope, props)
	-- Hiệu ứng Gradient cho viền chạy chạy (Optional animation could go here)

	return scope:New "ScreenGui" {
		Name = "UI_Economy", ResetOnSpawn = false, DisplayOrder = 10,
		[Fusion.Children] = {
			scope:New "Frame" {
				Name = "HoloCard",
				Size = UDim2.new(0, 240, 0, 85),
				Position = UDim2.new(0, 20, 1, -105),
				BackgroundColor3 = Color3.fromRGB(10, 10, 15),
				BackgroundTransparency = 0.3,

				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },

					-- Viền Gradient Neon
					scope:New "UIStroke" {
						Thickness = 2,
						Transparency = 0,
						[Fusion.Children] = {
							scope:New "UIGradient" {
								Color = ColorSequence.new{
									ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)), -- Cyan
									ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))  -- Purple
								},
								Rotation = 45
							}
						}
					},

					-- Họa tiết lưới mờ (Tech Grid)
					scope:New "ImageLabel" {
						Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
						Image = "rbxassetid://6071575925", -- Grid texture
						ImageColor3 = Color3.fromRGB(0, 255, 255), ImageTransparency = 0.9,
						ScaleType = "Tile", TileSize = UDim2.new(0, 30, 0, 30),
						[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 12) } }
					},

					-- Nội dung
					scope:New "Frame" {
						Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
						[Fusion.Children] = {
							scope:New "UIPadding" { PaddingLeft = UDim.new(0, 15), PaddingTop = UDim.new(0, 10) },
							scope:New "UIListLayout" { FillDirection = "Vertical", Padding = UDim.new(0, 2) },

							-- Wallet
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) return "💳 " .. (use(props.Wallet) or 0) end),
								TextColor3 = Color3.fromRGB(0, 255, 255),
								Font = Enum.Font.GothamBold, TextSize = 20,
								Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1, TextXAlignment = "Left",
								[Fusion.Children] = {
									scope:New "UIStroke" { Thickness = 1, Color = Color3.fromRGB(0, 100, 100), Transparency = 0.5 } -- Chữ có viền nhẹ
								}
							},

							-- Vault
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) return "🏦 " .. (use(props.Vault) or 0) end),
								TextColor3 = Color3.fromRGB(255, 200, 50),
								Font = Enum.Font.GothamBold, TextSize = 20,
								Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1, TextXAlignment = "Left",
								[Fusion.Children] = {
									scope:New "UIStroke" { Thickness = 1, Color = Color3.fromRGB(100, 80, 0), Transparency = 0.5 }
								}
							}
						}
					}
				}
			}
		}
	}
end

return EconomyView