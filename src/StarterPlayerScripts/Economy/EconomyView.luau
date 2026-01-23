local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local EconomyView = {}
local Theme = GameConfig.CyberTheme

-- Format money with K, M, B notation only when exceeding 10 digits
local function FormatMoney(amount)
	-- Only abbreviate if 11+ digits (10 billion+)
	if amount >= 1e10 then
		if amount >= 1e9 then
			return string.format("%.2fB", amount / 1e9)
		elseif amount >= 1e6 then
			return string.format("%.2fM", amount / 1e6)
		elseif amount >= 1e3 then
			return string.format("%.1fK", amount / 1e3)
		end
	end
	
	-- For smaller numbers, add comma separators
	local formatted = tostring(amount)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

function EconomyView.New(scope, props)
	return scope:New "ScreenGui" {
		Name = "UI_Economy", ResetOnSpawn = false, DisplayOrder = 10,
		[Fusion.Children] = {
			scope:New "Frame" {
				Name = "MoneyCard",
				Size = UDim2.fromOffset(160, 85),
				Position = UDim2.new(0, 12, 1, -12),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Color3.fromRGB(8, 12, 18),
				BackgroundTransparency = 0.1,
				BorderSizePixel = 0,

				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
					scope:New "UIStroke" {
						Thickness = 1.5,
						Color = Theme.NeonCyan,
						Transparency = 0.4
					},
					
					scope:New "UIPadding" { 
						PaddingLeft = UDim.new(0, 10), 
						PaddingRight = UDim.new(0, 10),
						PaddingTop = UDim.new(0, 8),
						PaddingBottom = UDim.new(0, 8)
					},
					
					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Vertical,
						Padding = UDim.new(0, 4),
						SortOrder = Enum.SortOrder.LayoutOrder
					},
					
					-- Wallet
					scope:New "Frame" {
						Size = UDim2.new(1, 0, 0, 30),
						BackgroundTransparency = 1,
						LayoutOrder = 1,
						[Fusion.Children] = {
							scope:New "TextLabel" {
								Text = "▸ WALLET",
								Size = UDim2.new(1, 0, 0, 12),
								Position = UDim2.fromOffset(0, 0),
								BackgroundTransparency = 1,
								TextColor3 = Color3.fromRGB(120, 200, 255),
								Font = Enum.Font.Code,
								TextSize = 9,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextTransparency = 0.4
							},
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) 
									return "$" .. FormatMoney(use(props.Wallet) or 0) 
								end),
								Size = UDim2.new(1, 0, 0, 16),
								Position = UDim2.fromOffset(0, 14),
								BackgroundTransparency = 1,
								TextColor3 = Theme.NeonCyan,
								Font = Enum.Font.GothamBold,
								TextSize = 15,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextStrokeTransparency = 0.7
							}
						}
					},
					
					-- Vault
					scope:New "Frame" {
						Size = UDim2.new(1, 0, 0, 30),
						BackgroundTransparency = 1,
						LayoutOrder = 2,
						[Fusion.Children] = {
							scope:New "TextLabel" {
								Text = "▸ VAULT",
								Size = UDim2.new(1, 0, 0, 12),
								Position = UDim2.fromOffset(0, 0),
								BackgroundTransparency = 1,
								TextColor3 = Color3.fromRGB(255, 120, 200),
								Font = Enum.Font.Code,
								TextSize = 9,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextTransparency = 0.4
							},
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) 
									return "$" .. FormatMoney(use(props.Vault) or 0) 
								end),
								Size = UDim2.new(1, 0, 0, 16),
								Position = UDim2.fromOffset(0, 14),
								BackgroundTransparency = 1,
								TextColor3 = Theme.NeonPink,
								Font = Enum.Font.GothamBold,
								TextSize = 15,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextStrokeTransparency = 0.7
							}
						}
					}
				}
			}
		}
	}
end

return EconomyView