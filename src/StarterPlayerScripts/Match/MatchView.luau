local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local MatchView = {}

-- Helper Card
local function Card(scope, data)
	local txt = data.Rank .. (data.Suit ~= "Hidden" and data.Suit:sub(1,1) or "")
	local isRed = (data.Suit == "Hearts" or data.Suit == "Diamonds")
	local color = isRed and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(20, 20, 20)
	local bg = Color3.fromRGB(240, 240, 240)
	local border = Color3.fromRGB(20,20,20)

	if data.Suit == "Hidden" then 
		txt = "?"; color = Color3.fromRGB(255, 200, 0); bg = Color3.fromRGB(20, 20, 25); border = Color3.fromRGB(255, 200, 0)
	end

	return scope:New "Frame" {
		Size = UDim2.new(0, 70, 0, 100), BackgroundColor3 = bg,
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 6) },
			scope:New "UIStroke" { Color = border, Thickness = 2 },
			scope:New "TextLabel" {
				Text = txt, Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
				TextColor3 = color, Font = Enum.Font.Bodoni, TextSize = 32
			}
		}
	}
end

-- Helper Button
local function CasinoButton(scope, props)
	local isHover = scope:Value(false)
	return scope:New "TextButton" {
		Text = props.Text or "", Size = props.Size, LayoutOrder = props.Order,
		BackgroundColor3 = props.Color, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 18,
		[Fusion.OnEvent "Activated"] = props.OnClick,
		[Fusion.OnEvent "MouseEnter"] = function() isHover:set(true) end,
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIScale" { Scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 40, 1) }
		}
	}
end

function MatchView.New(scope, props)
	return scope:New "ScreenGui" {
		Name = "UI_Match", ResetOnSpawn = false, DisplayOrder = 20,
		Enabled = scope:Computed(function(use) return use(props.IsSitting) end),

		[Fusion.Children] = {
			scope:New "Frame" {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
				[Fusion.Children] = {

					-- 1. Dealer Zone (Top)
					scope:New "Frame" {
						Position = UDim2.fromScale(0.5, 0.1), Size = UDim2.fromScale(0.5, 0.25), AnchorPoint = Vector2.new(0.5,0),
						BackgroundTransparency = 1,
						[Fusion.Children] = {
							scope:New "TextLabel" {
								Text = "DEALER", Position = UDim2.fromScale(0.5, -0.2), AnchorPoint = Vector2.new(0.5,0),
								BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 100, 100), Font = Enum.Font.Code, TextSize = 18
							},
							scope:New "UIListLayout" { FillDirection = "Horizontal", HorizontalAlignment = "Center", Padding = UDim.new(0,10) },
							scope:ForValues(props.DealerHand, function(use, inner, card) return Card(inner, card) end)
						}
					},

					-- 2. Result Text (Center Overlay)
					scope:New "TextLabel" {
						Text = scope:Computed(function(use) return use(props.Result) end),
						Size = UDim2.fromScale(1, 0.1), Position = UDim2.fromScale(0.5, 0.4), AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 215, 0), Font = Enum.Font.GothamBlack, TextSize = 50,
						TextStrokeTransparency = 0, TextStrokeColor3 = Color3.new(0,0,0), ZIndex = 5
					},

					-- 3. Player Zone (Middle)
					scope:New "Frame" {
						Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.5, 0.25), AnchorPoint = Vector2.new(0.5,0),
						BackgroundTransparency = 1,
						[Fusion.Children] = {
							scope:New "TextLabel" {
								Text = "YOU", Position = UDim2.fromScale(0.5, -0.2), AnchorPoint = Vector2.new(0.5,0),
								BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(100, 255, 100), Font = Enum.Font.Code, TextSize = 18
							},
							scope:New "UIListLayout" { FillDirection = "Horizontal", HorizontalAlignment = "Center", Padding = UDim.new(0,10) },
							scope:ForValues(props.PlayerHand, function(use, inner, card) return Card(inner, card) end)
						}
					},

					-- 4. Control Panel (Bottom)
					scope:New "Frame" {
						Name = "ControlPanel",
						Position = UDim2.fromScale(0.5, 0.95), Size = UDim2.new(0, 500, 0, 80), AnchorPoint = Vector2.new(0.5, 1),
						BackgroundColor3 = Color3.fromRGB(10, 10, 15), BackgroundTransparency = 0.1,

						[Fusion.Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
							scope:New "UIStroke" { Color = Color3.fromRGB(50, 50, 70), Thickness = 2 },
							scope:New "UIPadding" { PaddingTop = UDim.new(0,15), PaddingBottom = UDim.new(0,15), PaddingLeft = UDim.new(0,20), PaddingRight = UDim.new(0,20) },

							scope:New "UIListLayout" { FillDirection = "Horizontal", HorizontalAlignment = "Center", Padding = UDim.new(0, 15), VerticalAlignment = "Center" },

							-- Bet Input Area
							scope:New "Frame" {
								LayoutOrder = 1, Size = UDim2.new(0, 140, 1, 0), BackgroundTransparency = 1,
								[Fusion.Children] = {
									scope:New "UIListLayout" { FillDirection = "Vertical", Padding = UDim.new(0,5) },
									scope:New "TextLabel" { Text = "BET AMOUNT", Size = UDim2.new(1,0,0,15), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150,150,150), Font = Enum.Font.GothamBold, TextSize = 10 },
									scope:New "TextBox" {
										Text = props.BetInput, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(0,0,0),
										TextColor3 = Color3.fromRGB(255,255,255), Font = Enum.Font.Code, TextSize = 18,
										[Fusion.OnChange "Text"] = function(txt) local num = tonumber(txt); if num then props.BetInput:set(num) end end,
										[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0,4) }, scope:New "UIStroke" { Color = Color3.fromRGB(100,100,100) } }
									}
								}
							},

							-- Divider
							scope:New "Frame" { LayoutOrder = 2, Size = UDim2.new(0, 2, 0.8, 0), BackgroundColor3 = Color3.fromRGB(50,50,50) },

							-- Actions
							CasinoButton(scope, { Order=3, Text = "DEAL", Size = UDim2.new(0, 80, 0, 45), Color = Color3.fromRGB(0, 200, 100), OnClick = props.OnStart }),
							CasinoButton(scope, { Order=4, Text = "HIT", Size = UDim2.new(0, 80, 0, 45), Color = Color3.fromRGB(0, 150, 255), OnClick = props.OnHit }),
							CasinoButton(scope, { Order=5, Text = "STAND", Size = UDim2.new(0, 80, 0, 45), Color = Color3.fromRGB(255, 50, 50), OnClick = props.OnStand }),
						}
					}
				}
			}
		}
	}
end

return MatchView