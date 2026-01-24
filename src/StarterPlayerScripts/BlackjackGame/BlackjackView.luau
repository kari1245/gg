local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local BlackjackView = {}
local Theme = GameConfig.CyberTheme

-- Card component - Cyber minimal
local function Card(scope, card)
	local isRed = card.Suit == "Hearts" or card.Suit == "Diamonds"
	local cardColor = isRed and Theme.GlitchRed or Theme.NeonCyan
	local displayText = card.Suit == "Hidden" and "?" or (card.Rank .. "\n" .. card.Suit:sub(1, 1))
	
	return scope:New "Frame" {
		Size = UDim2.fromScale(0.08, 1),
		BackgroundColor3 = Theme.DarkBg,
		[Fusion.Children] = {
			scope:New "UIAspectRatioConstraint" { AspectRatio = 0.65 },
			scope:New "UICorner" { CornerRadius = UDim.new(0.1, 0) },
			scope:New "UIStroke" { Color = cardColor, Thickness = 2 },
			scope:New "TextLabel" {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = displayText,
				TextColor3 = cardColor,
				Font = Enum.Font.Code,
				TextScaled = true,
				[Fusion.Children] = scope:New "UIPadding" {
					PaddingTop = UDim.new(0.1, 0),
					PaddingBottom = UDim.new(0.1, 0),
					PaddingLeft = UDim.new(0.1, 0),
					PaddingRight = UDim.new(0.1, 0)
				}
			}
		}
	}
end

-- Button component - Cyber minimal
local function Button(scope, props)
	local hover = scope:Value(false)
	local disabled = props.Disabled or scope:Value(false)
	
	return scope:New "TextButton" {
		Size = props.Size or UDim2.fromScale(0.2, 0.1),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = scope:Computed(function(use)
			return use(disabled) and Theme.MidBg or (props.Color or Theme.NeonCyan)
		end),
		BackgroundTransparency = scope:Computed(function(use) return use(hover) and 0 or 0.3 end),
		Text = props.Text or "",
		TextColor3 = scope:Computed(function(use)
			return use(disabled) and Color3.fromRGB(80, 80, 80) or Color3.new(0, 0, 0)
		end),
		Font = Enum.Font.Code,
		TextScaled = true,
		Active = scope:Computed(function(use) return not use(disabled) end),
		[Fusion.OnEvent "Activated"] = function()
			if not Fusion.peek(disabled) and props.OnClick then
				props.OnClick()
			end
		end,
		[Fusion.OnEvent "MouseEnter"] = function() if not Fusion.peek(disabled) then hover:set(true) end end,
		[Fusion.OnEvent "MouseLeave"] = function() hover:set(false) end,
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0.2, 0) },
			scope:New "UIStroke" { 
				Color = scope:Computed(function(use)
					return use(disabled) and Theme.MidBg or (props.Color or Theme.NeonCyan)
				end),
				Thickness = 2
			},
			scope:New "UIPadding" {
				PaddingTop = UDim.new(0.15, 0),
				PaddingBottom = UDim.new(0.15, 0),
				PaddingLeft = UDim.new(0.05, 0),
				PaddingRight = UDim.new(0.05, 0)
			}
		}
	}
end

function BlackjackView.New(scope, props)
	return scope:New "ScreenGui" {
		Name = "BlackjackUI",
		ResetOnSpawn = false,
		DisplayOrder = 50,
		[Fusion.Children] = scope:New "Frame" {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = scope:Computed(function(use) return use(props.IsSitting) end),
			[Fusion.Children] = {
				-- Main Panel
				scope:New "Frame" {
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromScale(0.7, 0.85),
					BackgroundColor3 = Theme.DarkBg,
					BackgroundTransparency = 0.1,
					[Fusion.Children] = {
						scope:New "UICorner" { CornerRadius = UDim.new(0.03, 0) },
						scope:New "UIStroke" { Color = Theme.NeonCyan, Thickness = 3 },
						
						-- Title
						scope:New "TextLabel" {
							Position = UDim2.fromScale(0.5, 0.05),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Size = UDim2.fromScale(0.6, 0.08),
							BackgroundTransparency = 1,
							Text = "◈ BLACKJACK ◈",
							TextColor3 = Theme.NeonCyan,
							Font = Enum.Font.Code,
							TextScaled = true
						},
						
						-- Close Button
						scope:New "TextButton" {
							Position = UDim2.fromScale(0.95, 0.05),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Size = UDim2.fromScale(0.05, 0.08),
							BackgroundColor3 = Theme.GlitchRed,
							Text = "✕",
							TextColor3 = Color3.new(1, 1, 1),
							Font = Enum.Font.Code,
							TextScaled = true,
							[Fusion.OnEvent "Activated"] = props.OnLeave,
							[Fusion.Children] = {
								scope:New "UICorner" { CornerRadius = UDim.new(0.3, 0) },
								scope:New "UIStroke" { Color = Theme.GlitchRed, Thickness = 2 }
							}
						},
						
						-- BET SCREEN
						scope:New "Frame" {
							Position = UDim2.fromScale(0.5, 0.5),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Size = UDim2.fromScale(0.8, 0.7),
							BackgroundTransparency = 1,
							Visible = scope:Computed(function(use) return use(props.GameState) == "WAITING_BET" end),
							[Fusion.Children] = {
								-- Bet Label
								scope:New "TextLabel" {
									Position = UDim2.fromScale(0.5, 0.2),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Size = UDim2.fromScale(0.5, 0.1),
									BackgroundTransparency = 1,
									Text = "PLACE YOUR BET",
									TextColor3 = Theme.NeonOrange,
									Font = Enum.Font.Code,
									TextScaled = true
								},
								
								-- Bet Input
								scope:New "TextBox" {
									Position = UDim2.fromScale(0.5, 0.35),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Size = UDim2.fromScale(0.4, 0.12),
									BackgroundColor3 = Theme.MidBg,
									Text = scope:Computed(function(use) return "$" .. tostring(use(props.BetInput)) end),
									TextColor3 = Color3.new(1, 1, 1),
									Font = Enum.Font.Code,
									TextScaled = true,
									PlaceholderText = "$50",
								ClearTextOnFocus = false,
								[Fusion.OnChange "Text"] = function(newText)
									local cleaned = newText:gsub("%$", "")
									local val = tonumber(cleaned)
									if val then
										props.BetInput:set(math.clamp(val, 50, 50000))
									end
									end,
									[Fusion.Children] = {
										scope:New "UICorner" { CornerRadius = UDim.new(0.2, 0) },
										scope:New "UIStroke" { Color = Theme.NeonOrange, Thickness = 2 },
										scope:New "UIPadding" {
											PaddingLeft = UDim.new(0.1, 0),
											PaddingRight = UDim.new(0.1, 0)
										}
									}
								},
								
								-- Confirm Button
								Button(scope, {
									Position = UDim2.fromScale(0.5, 0.5),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Size = UDim2.fromScale(0.3, 0.12),
									Text = "CONFIRM",
									Color = Theme.NeonGreen,
									OnClick = props.OnPlaceBet
								})
							}
						},
						
						-- GAME SCREEN
						scope:New "Frame" {
							Position = UDim2.fromScale(0.5, 0.55),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Size = UDim2.fromScale(0.95, 0.82),
							BackgroundTransparency = 1,
							Visible = scope:Computed(function(use)
								local s = use(props.GameState)
								return s ~= "WAITING_BET"
							end),
							[Fusion.Children] = {
								-- Dealer Section
								scope:New "Frame" {
									Position = UDim2.fromScale(0.5, 0.15),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Size = UDim2.fromScale(0.9, 0.22),
									BackgroundColor3 = Theme.MidBg,
									BackgroundTransparency = 0.4,
									[Fusion.Children] = {
										scope:New "UICorner" { CornerRadius = UDim.new(0.1, 0) },
										scope:New "UIStroke" { Color = Theme.GlitchRed, Thickness = 2 },
										
										-- Dealer Label
										scope:New "TextLabel" {
											Position = UDim2.fromScale(0.5, 0.2),
											AnchorPoint = Vector2.new(0.5, 0.5),
											Size = UDim2.fromScale(0.8, 0.25),
											BackgroundTransparency = 1,
											Text = scope:Computed(function(use)
												local d = use(props.Dealer)
												return "DEALER [" .. (d.Score or 0) .. "]"
											end),
											TextColor3 = Theme.GlitchRed,
											Font = Enum.Font.Code,
											TextScaled = true
										},
										
										-- Dealer Cards
										scope:New "Frame" {
											Position = UDim2.fromScale(0.5, 0.65),
											AnchorPoint = Vector2.new(0.5, 0.5),
											Size = UDim2.fromScale(0.95, 0.6),
											BackgroundTransparency = 1,
											[Fusion.Children] = {
												scope:New "UIListLayout" {
													FillDirection = Enum.FillDirection.Horizontal,
													HorizontalAlignment = Enum.HorizontalAlignment.Center,
													Padding = UDim.new(0.02, 0)
												},
												scope:ForValues(
												scope:Computed(function(use) 
													local dealer = use(props.Dealer)
													if dealer and dealer.Hand and type(dealer.Hand) == "table" then
														return dealer.Hand
													end
													return {}
												end),
													function(use, scope, card) return Card(scope, card) end
												)
											}
										}
									}
								},
								
								-- Player Section
								scope:New "Frame" {
									Position = UDim2.fromScale(0.5, 0.45),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Size = UDim2.fromScale(0.9, 0.22),
									BackgroundColor3 = Theme.MidBg,
									BackgroundTransparency = 0.4,
									[Fusion.Children] = {
										scope:New "UICorner" { CornerRadius = UDim.new(0.1, 0) },
										scope:New "UIStroke" { Color = Theme.NeonGreen, Thickness = 2 },
										
										-- Player Label
										scope:New "TextLabel" {
											Position = UDim2.fromScale(0.5, 0.2),
											AnchorPoint = Vector2.new(0.5, 0.5),
											Size = UDim2.fromScale(0.8, 0.25),
											BackgroundTransparency = 1,
											Text = scope:Computed(function(use)
												local h = use(props.MyHand)
												local b = use(props.BetInput)
												return "YOU [" .. (h.Score or 0) .. "] [$" .. (b or 0) .. "]"
											end),
											TextColor3 = Theme.NeonGreen,
											Font = Enum.Font.Code,
											TextScaled = true
										},
										
										-- Player Cards
										scope:New "Frame" {
											Position = UDim2.fromScale(0.5, 0.65),
											AnchorPoint = Vector2.new(0.5, 0.5),
											Size = UDim2.fromScale(0.95, 0.6),
											BackgroundTransparency = 1,
											[Fusion.Children] = {
												scope:New "UIListLayout" {
													FillDirection = Enum.FillDirection.Horizontal,
													HorizontalAlignment = Enum.HorizontalAlignment.Center,
													Padding = UDim.new(0.02, 0)
												},
												scope:ForValues(
												scope:Computed(function(use) 
													local myHand = use(props.MyHand)
													if myHand and myHand.Hand and type(myHand.Hand) == "table" then
														return myHand.Hand
													end
													return {}
												end),
													function(use, scope, card) return Card(scope, card) end
												)
											}
										}
									}
								},
								
								-- Action Buttons
								scope:New "Frame" {
									Position = UDim2.fromScale(0.5, 0.75),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Size = UDim2.fromScale(0.9, 0.35),
									BackgroundTransparency = 1,
									[Fusion.Children] = {
										Button(scope, {
											Position = UDim2.fromScale(0.2, 0.3),
											AnchorPoint = Vector2.new(0.5, 0.5),
											Size = UDim2.fromScale(0.25, 0.25),
											Text = "HIT",
											Color = Theme.NeonGreen,
											OnClick = props.OnHit,
											Disabled = scope:Computed(function(use) 
												return use(props.GameState) ~= "PLAYER_TURN"
											end)
										}),
										Button(scope, {
											Position = UDim2.fromScale(0.5, 0.3),
											AnchorPoint = Vector2.new(0.5, 0.5),
											Size = UDim2.fromScale(0.25, 0.25),
											Text = "STAND",
											Color = Theme.NeonOrange,
											OnClick = props.OnStand,
											Disabled = scope:Computed(function(use) 
												return use(props.GameState) ~= "PLAYER_TURN"
											end)
										}),
										Button(scope, {
											Position = UDim2.fromScale(0.8, 0.3),
											AnchorPoint = Vector2.new(0.5, 0.5),
											Size = UDim2.fromScale(0.25, 0.25),
											Text = "LEAVE",
											Color = Theme.GlitchRed,
											OnClick = props.OnLeave
										})
									}
								},
								
								-- Result Display
								scope:New "Frame" {
									Position = UDim2.fromScale(0.5, 0.5),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Size = UDim2.fromScale(0.6, 0.15),
									BackgroundColor3 = Theme.DarkBg,
									Visible = scope:Computed(function(use) return use(props.GameState) == "FINISHED" end),
									ZIndex = 10,
									[Fusion.Children] = {
										scope:New "UICorner" { CornerRadius = UDim.new(0.15, 0) },
										scope:New "UIStroke" { Color = Theme.NeonPink, Thickness = 3 },
										scope:New "TextLabel" {
											Size = UDim2.fromScale(1, 1),
											BackgroundTransparency = 1,
											Text = scope:Computed(function(use) return use(props.Result) end),
											TextColor3 = Theme.NeonPink,
											Font = Enum.Font.Code,
											TextScaled = true,
											ZIndex = 10,
											[Fusion.Children] = scope:New "UIPadding" {
												PaddingLeft = UDim.new(0.1, 0),
												PaddingRight = UDim.new(0.1, 0)
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
end

return BlackjackView
