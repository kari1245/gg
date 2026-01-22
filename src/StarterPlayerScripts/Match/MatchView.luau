local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local MatchView = {}

local function Card(scope, data, isPlayer)
	local txt = data.Rank .. (data.Suit ~= "Hidden" and data.Suit:sub(1,1) or "")
	local color = (data.Suit == "Hearts" or data.Suit == "Diamonds") and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 255, 255)
	if data.Suit == "Hidden" then txt = "?"; color = Color3.fromRGB(0, 255, 100) end

	return scope:New "Frame" {
		Size = UDim2.new(0, 70, 0, 100), BackgroundColor3 = Color3.fromRGB(20, 25, 30),
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 6) },
			scope:New "UIStroke" { Color = color, Thickness = 2 },
			scope:New "TextLabel" {
				Text = txt, Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
				TextColor3 = color, Font = Enum.Font.RobotoMono, TextSize = 32
			}
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
					-- Dealer Area
					scope:New "Frame" {
						Position = UDim2.fromScale(0.5, 0.15), Size = UDim2.fromScale(0.6, 0.2), AnchorPoint = Vector2.new(0.5,0), BackgroundTransparency=1,
						[Fusion.Children] = {
							scope:New "UIListLayout" { FillDirection = "Horizontal", HorizontalAlignment = "Center", Padding = UDim.new(0,15) },
							scope:ForValues(props.DealerHand, function(use, inner, card) return Card(inner, card, false) end)
						}
					},

					-- Player Area
					scope:New "Frame" {
						Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.6, 0.2), AnchorPoint = Vector2.new(0.5,0), BackgroundTransparency=1,
						[Fusion.Children] = {
							scope:New "UIListLayout" { FillDirection = "Horizontal", HorizontalAlignment = "Center", Padding = UDim.new(0,15) },
							scope:ForValues(props.PlayerHand, function(use, inner, card) return Card(inner, card, true) end)
						}
					},

					-- Controls
					scope:New "Frame" {
						Position = UDim2.fromScale(0.5, 0.85), Size = UDim2.fromScale(0.5, 0.1), AnchorPoint = Vector2.new(0.5,0), BackgroundTransparency=1,
						[Fusion.Children] = {
							scope:New "UIListLayout" { FillDirection = "Horizontal", HorizontalAlignment = "Center", Padding = UDim.new(0,20) },

							scope:New "TextBox" {
								Text = props.BetInput, Size = UDim2.new(0, 120, 0, 50), BackgroundColor3 = Color3.fromRGB(10,15,20),
								TextColor3 = Color3.new(1,1,1), Font = Enum.Font.Code, TextSize = 24,
								[Fusion.OnChange "Text"] = function(txt) local num = tonumber(txt); if num then props.BetInput:set(num) end end,
								[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0,8) }, scope:New "UIStroke" { Color = Color3.new(1,1,1), Thickness = 2 } }
							},

							scope:New "TextButton" {
								Text = "HIT", Size = UDim2.new(0, 120, 0, 50), BackgroundColor3 = Color3.fromRGB(0, 150, 255),
								Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = Color3.new(1,1,1),
								[Fusion.OnEvent "Activated"] = props.OnHit,
								[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0,8) } }
							},
							scope:New "TextButton" {
								Text = "STAND", Size = UDim2.new(0, 120, 0, 50), BackgroundColor3 = Color3.fromRGB(255, 50, 50),
								Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = Color3.new(1,1,1),
								[Fusion.OnEvent "Activated"] = props.OnStand,
								[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0,8) } }
							},
							scope:New "TextButton" {
								Text = "START", Size = UDim2.new(0, 120, 0, 50), BackgroundColor3 = Color3.fromRGB(0, 255, 100),
								Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = Color3.new(0,0,0),
								[Fusion.OnEvent "Activated"] = props.OnStart,
								[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0,8) } }
							}
						}
					},

					-- Result Text
					scope:New "TextLabel" {
						Text = scope:Computed(function(use) return use(props.Result) end),
						Size = UDim2.fromScale(1, 0.1), Position = UDim2.fromScale(0, 0.35), BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(255, 200, 0), Font = Enum.Font.GothamBlack, TextSize = 48,
						TextStrokeTransparency = 0.5
					}
				}
			}
		}
	}
end

return MatchView