local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local BankView = {}

local function CyberButton(scope, props)
	-- (Copy lại logic CyberButton ở trên, đổi default color thành Gold)
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 40, 1)
	return scope:New "TextButton" {
		Text = props.Text or "", Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = Color3.fromRGB(20, 25, 35), BackgroundTransparency = 0.2,
		TextColor3 = props.Color or Color3.fromRGB(255, 200, 0), Font = Enum.Font.GothamBold, TextSize = 16,
		[Fusion.OnEvent "MouseEnter"] = function() isHover:set(true) end,
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		[Fusion.OnEvent "Activated"] = props.OnClick,
		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(0,6) },
			scope:New "UIStroke" { Color = props.Color or Color3.fromRGB(255, 200, 0), Thickness = 2, Transparency = scope:Computed(function(use) return use(isHover) and 0 or 0.6 end) }
		}
	}
end

function BankView.New(scope, props)
	return scope:New "ScreenGui" {
		Name = "UI_Bank", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			CyberButton(scope, {
				Text = "🏦", Size = UDim2.fromOffset(60, 60),
				Position = UDim2.new(0, 20, 0.5, -120), -- Trên cùng
				Color = Color3.fromRGB(255, 200, 0),
				OnClick = props.OnToggle
			}),

			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.4, 0.5), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(15, 20, 25), BackgroundTransparency = 0.1,
				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },
					scope:New "UIStroke" { Color = Color3.fromRGB(255, 200, 0), Thickness = 2 },

					scope:New "TextLabel" {
						Text = "SECURE VAULT", Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(255, 200, 0), Font = Enum.Font.GothamBlack, TextSize = 30,
						Position = UDim2.new(0, 20, 0, 0), TextXAlignment = "Left"
					},
					CyberButton(scope, {
						Text = "✕", Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -20, 0, 10), AnchorPoint = Vector2.new(1,0),
						Color = Color3.fromRGB(255, 50, 50), OnClick = props.OnClose
					}),

					scope:New "TextBox" {
						Text = props.AmountInput, PlaceholderText = "ENTER AMOUNT...",
						Size = UDim2.new(0.8, 0, 0, 50), Position = UDim2.fromScale(0.5, 0.35), AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(5, 10, 15), TextColor3 = Color3.fromRGB(255, 255, 255),
						Font = Enum.Font.Code, TextSize = 24, ClearTextOnFocus = false,
						[Fusion.OnChange "Text"] = function(txt) local num = txt:gsub("%D", ""); props.AmountInput:set(num) end,
						[Fusion.Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(0,8) },
							scope:New "UIStroke" { Color = Color3.fromRGB(255, 200, 0), Transparency = 0.5 }
						}
					},

					CyberButton(scope, {
						Text = "DEPOSIT", Size = UDim2.new(0.35, 0, 0, 50), Position = UDim2.new(0.3, 0, 0.65, 0), AnchorPoint = Vector2.new(0.5, 0.5),
						Color = Color3.fromRGB(0, 255, 100), OnClick = props.OnDeposit
					}),
					CyberButton(scope, {
						Text = "WITHDRAW", Size = UDim2.new(0.35, 0, 0, 50), Position = UDim2.new(0.7, 0, 0.65, 0), AnchorPoint = Vector2.new(0.5, 0.5),
						Color = Color3.fromRGB(255, 50, 50), OnClick = props.OnWithdraw
					})
				}
			}
		}
	}
end

return BankView