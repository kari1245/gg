local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local BankView = {}
local Theme = GameConfig.CyberTheme

-- Cyber Button với gold theme
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
				Color = props.Color or GameConfig.Colors.Gold,
				Transparency = 0
			},
			scope:New "ImageLabel" {
				Size = UDim2.fromScale(1.15, 1.15), Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
				Image = "rbxassetid://5028857084",
				ImageColor3 = props.Color or GameConfig.Colors.Gold,
				ImageTransparency = 0.65, ZIndex = -1
			},
			scope:New "TextLabel" {
				Text = props.Text or "", Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
				TextColor3 = props.Color or GameConfig.Colors.Gold,
				Font = Enum.Font.Code, TextSize = 16,
				TextStrokeTransparency = 0.5, ZIndex = 2
			}
		}
	}
end

function BankView.New(scope, props)
	return scope:New "ScreenGui" {
		Name = "UI_Bank", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			-- Nút Sidebar
			CyberButton(scope, {
					Text = "◆ VLT", Size = UDim2.fromScale(0.065, 0.09),
					Position = UDim2.fromScale(0.015, 0.43),
					Color = GameConfig.Colors.Gold,
					OnClick = props.OnToggle
				}),

				scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
			Size = UDim2.fromScale(0.75, 0.6), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Theme.DarkBg,
				BackgroundTransparency = 0.1,

				[Fusion.Children] = {
					scope:New "UIAspectRatioConstraint" { AspectRatio = 1.6 },
					scope:New "UICorner" { CornerRadius = UDim.new(0, 20) },
					scope:New "UIStroke" {
						Thickness = 3.5,
						Color = GameConfig.Colors.Gold,
						Transparency = 0
					},

					-- Nền Grid
					scope:New "ImageLabel" {
						Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
						Image = "rbxassetid://6071575925", 
						ImageColor3 = GameConfig.Colors.Gold, ImageTransparency = 0.91,
						ScaleType = "Tile", TileSize = UDim2.fromOffset(45, 45),
						ZIndex = 0,
						[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 20) } }
					},

					-- Tiêu đề
					scope:New "TextLabel" {
						Text = "◢◤ SECURE VAULT ◥◣", 
						Size = UDim2.new(1, 0, 0.15, 0), BackgroundTransparency = 1,
						TextColor3 = GameConfig.Colors.Gold, 
						Font = Enum.Font.Code, TextSize = 28,
						TextScaled = true,
						TextStrokeTransparency = 0.4,
						ZIndex = 2
					},

					-- Nút Đóng
					CyberButton(scope, {
						Text = "✕", Size = UDim2.fromScale(0.08, 0.1),
						Position = UDim2.fromScale(0.96, 0.04), AnchorPoint = Vector2.new(1,0),
						Color = Theme.GlitchRed, OnClick = props.OnClose
					}),

					-- Input Box cyber style
					scope:New "TextBox" {
						Text = props.AmountInput, PlaceholderText = "▸ ENTER AMOUNT...",
						Size = UDim2.new(0.88, 0, 0.13, 0), Position = UDim2.fromScale(0.5, 0.4), AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Theme.MidBg, 
						BackgroundTransparency = 0.3,
						TextColor3 = GameConfig.Colors.Gold,
						PlaceholderColor3 = Color3.fromRGB(150, 120, 0),
						Font = Enum.Font.Code, TextSize = 24,
						TextScaled = true,
						ClearTextOnFocus = false,
						[Fusion.OnChange "Text"] = function(txt) local num = txt:gsub("%D", ""); props.AmountInput:set(num) end,
						[Fusion.Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
							scope:New "UIStroke" { 
								Color = GameConfig.Colors.Gold, 
								Thickness = 2.5,
								Transparency = 0.3
							}
						}
					},

					-- Nút Hành Động
					CyberButton(scope, {
						Text = "▲ DEPOSIT", Size = UDim2.new(0.38, 0, 0.11, 0), Position = UDim2.fromScale(0.28, 0.75), AnchorPoint = Vector2.new(0.5, 0.5),
						Color = Theme.NeonGreen, OnClick = props.OnDeposit
					}),
					CyberButton(scope, {
						Text = "▼ WITHDRAW", Size = UDim2.new(0.38, 0, 0.11, 0), Position = UDim2.fromScale(0.72, 0.75), AnchorPoint = Vector2.new(0.5, 0.5),
						Color = Theme.GlitchRed, OnClick = props.OnWithdraw
					})
				}
			}
		}
	}
end

return BankView