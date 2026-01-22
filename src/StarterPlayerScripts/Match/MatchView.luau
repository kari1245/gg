local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local MatchView = {}
local Theme = GameConfig.CyberTheme

-- Cyber Card component
local function Card(scope, data)
	local txt = data.Rank .. (data.Suit ~= "Hidden" and data.Suit:sub(1,1) or "")
	local isRed = (data.Suit == "Hearts" or data.Suit == "Diamonds")
	local color = isRed and Theme.GlitchRed or Color3.new(1, 1, 1)
	local bg = Theme.MidBg
	local border = isRed and Theme.GlitchRed or Theme.NeonCyan

	if data.Suit == "Hidden" then 
		txt = "?"
		color = Theme.NeonPurple
		bg = Theme.DarkBg
		border = Theme.NeonPurple
	end

	return scope:New "Frame" {
		Size = UDim2.fromOffset(70, 100),
		BackgroundColor3 = bg,
		BackgroundTransparency = 0.15,
		[Fusion.Children] = {
			scope:New "UIAspectRatioConstraint" { AspectRatio = 0.7 },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" { Color = border, Thickness = 2, Transparency = 0 },
			scope:New "ImageLabel" {
				Size = UDim2.fromScale(1.2, 1.2),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = "rbxassetid://4724678792",
				ImageColor3 = border,
				ImageTransparency = 0.7,
				ZIndex = 0
			},
			scope:New "TextLabel" {
				Text = txt, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
				TextColor3 = color, Font = Enum.Font.Code, TextSize = 42,
				TextStrokeTransparency = 0.5, ZIndex = 2
			}
		}
	}
end

-- Cyber Button
local function CasinoButton(scope, props)
	local isHover = scope:Value(false)
	local isPressed = scope:Value(false)
	local isDisabled = props.Disabled or scope:Value(false)
	
	local scale = scope:Spring(
		scope:Computed(function(use) 
			if use(isDisabled) then return 1
			elseif use(isPressed) then return 0.9
			elseif use(isHover) then return 1.08
			else return 1 end
		end), 45, 0.85
	)
	
	return scope:New "TextButton" {
		Text = props.Text or "", Size = props.Size, LayoutOrder = props.Order,
		BackgroundColor3 = scope:Computed(function(use)
			return use(isDisabled) and Theme.MidBg or (props.Color or Theme.NeonCyan)
		end),
		BackgroundTransparency = scope:Computed(function(use)
			return use(isDisabled) and 0.6 or 0.2
		end),
		TextColor3 = scope:Computed(function(use)
			return use(isDisabled) and Color3.fromRGB(100, 100, 100) or Color3.new(0, 0, 0)
		end),
		Font = Enum.Font.Code, TextSize = 20,
		TextStrokeTransparency = 0.8,
		Active = scope:Computed(function(use) return not use(isDisabled) end),
		[Fusion.OnEvent "Activated"] = function()
			if not Fusion.peek(isDisabled) and props.OnClick then
				props.OnClick()
			end
		end,
		[Fusion.OnEvent "MouseButton1Down"] = function() 
			if not Fusion.peek(isDisabled) then
				isPressed:set(true)
			end
		end,
		[Fusion.OnEvent "MouseButton1Up"] = function() isPressed:set(false) end,
		[Fusion.OnEvent "MouseEnter"] = function() 
			if not Fusion.peek(isDisabled) then
				isHover:set(true)
			end
		end,
		[Fusion.OnEvent "MouseLeave"] = function() 
			isHover:set(false)
			isPressed:set(false)
		end,
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" { 
				Color = scope:Computed(function(use)
					return use(isDisabled) and Theme.MidBg or (props.Color or Theme.NeonCyan)
				end),
				Thickness = 2.5, 
				Transparency = scope:Computed(function(use)
					return use(isDisabled) and 0.7 or 0
				end)
			},
			scope:New "UIScale" { Scale = scale }
		}
	}
end

-- Player Panel (hiển thị 1 player với bài và điểm)
local function PlayerPanel(scope, playerData, isCurrent)
	local hand = playerData.Hand or {}
	local score = playerData.Score or 0
	local name = playerData.Name or "?"
	local bet = playerData.Bet or 0
	local state = playerData.State or "WAITING"
	
	-- Border color based on state
	local borderColor = Theme.NeonCyan
	if isCurrent then borderColor = Theme.NeonGreen
	elseif state == "BUST" then borderColor = Theme.GlitchRed
	elseif state == "STAND" then borderColor = Theme.NeonPurple
	elseif state == "BLACKJACK" then borderColor = Theme.NeonOrange end
	
	return scope:New "Frame" {
		Size = UDim2.new(1, 0, 0, 140),
		BackgroundColor3 = Theme.DarkBg,
		BackgroundTransparency = 0.3,
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" { Color = borderColor, Thickness = 2, Transparency = 0 },
			
			-- Info panel (left)
			scope:New "Frame" {
				Size = UDim2.new(0, 150, 1, 0),
				BackgroundColor3 = Theme.MidBg,
				BackgroundTransparency = 0.5,
				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
					scope:New "TextLabel" {
						Text = name,
						Position = UDim2.fromOffset(10, 10),
						Size = UDim2.new(1, -20, 0, 25),
						BackgroundTransparency = 1,
						TextColor3 = Theme.NeonCyan,
						Font = Enum.Font.Code,
						TextSize = 18,
						TextXAlignment = Enum.TextXAlignment.Left
					},
					scope:New "TextLabel" {
						Text = "BET: $"..bet,
						Position = UDim2.fromOffset(10, 40),
						Size = UDim2.new(1, -20, 0, 20),
						BackgroundTransparency = 1,
						TextColor3 = Theme.NeonOrange,
						Font = Enum.Font.Code,
						TextSize = 14,
						TextXAlignment = Enum.TextXAlignment.Left
					},
					scope:New "TextLabel" {
						Text = "SCORE: "..score,
						Position = UDim2.fromOffset(10, 65),
						Size = UDim2.new(1, -20, 0, 30),
						BackgroundTransparency = 1,
						TextColor3 = (score > 21 and Theme.GlitchRed or Theme.NeonGreen),
						Font = Enum.Font.Code,
						TextSize = 20,
						TextXAlignment = Enum.TextXAlignment.Left
					},
					scope:New "TextLabel" {
						Text = state,
						Position = UDim2.fromOffset(10, 100),
						Size = UDim2.new(1, -20, 0, 20),
						BackgroundTransparency = 1,
						TextColor3 = borderColor,
						Font = Enum.Font.Code,
						TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left
					}
				}
			},
			
			-- Cards panel (right)
			scope:New "Frame" {
				Position = UDim2.fromOffset(160, 10),
				Size = UDim2.new(1, -170, 1, -20),
				BackgroundTransparency = 1,
				[Fusion.Children] = {
					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						Padding = UDim.new(0, 8)
					},
					scope:ForValues(hand, function(use, scope, cardData)
						return Card(scope, cardData)
					end)
				}
			}
		}
	}
end

function MatchView.New(scope, props)
	local IsSitting = props.IsSitting
	local GameState = props.GameState
	local Players = props.Players
	local Dealer = props.Dealer
	local Result = props.Result
	local BetInput = props.BetInput
	local LobbyPlayers = props.LobbyPlayers
	local MaxPlayers = props.MaxPlayers
	local CountdownTimer = props.CountdownTimer
	local MyHand = props.MyHand
	
	-- Tính toán xem có phải lượt của mình không
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local IsMyTurn = scope:Computed(function(use)
		local state = use(GameState)
		if state ~= "PLAYER_TURN" then return false end
		
		local players = use(Players)
		local currentIdx = use(props.CurrentPlayerIndex)
		
		if currentIdx > 0 and currentIdx <= #players then
			local currentPlayer = players[currentIdx]
			return currentPlayer and currentPlayer.Name == LocalPlayer.Name and currentPlayer.IsCurrent
		end
		
		return false
	end)
	
	return scope:New "ScreenGui" {
		Name = "MatchUI",
		ResetOnSpawn = false,
		DisplayOrder = 50,
		[Fusion.Children] = scope:New "Frame" {
			Name = "MainContainer",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = scope:Computed(function(use) return use(IsSitting) end),
			[Fusion.Children] = {
				-- [[ HEADER ]]
				scope:New "Frame" {
					Name = "Header",
					Position = UDim2.fromScale(0.5, 0.01),
					AnchorPoint = Vector2.new(0.5, 0),
					Size = UDim2.new(0.6, 0, 0, 40),
					BackgroundColor3 = Theme.DarkBg,
					BackgroundTransparency = 0.2,
					ZIndex = 10,
					[Fusion.Children] = {
						scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },
						scope:New "UIStroke" { Color = Theme.NeonCyan, Thickness = 2 },
						scope:New "TextLabel" {
							Text = "◢ BLACKJACK ◣",
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							TextColor3 = Theme.NeonCyan,
							Font = Enum.Font.Code,
							TextScaled = true,
							TextStrokeTransparency = 0.5
						}
					}
				},
				
				-- [[ LOBBY SCREEN ]]
				scope:New "Frame" {
					Name = "LobbyScreen",
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Theme.DarkBg,
					BackgroundTransparency = 0.5,
					Visible = scope:Computed(function(use)
						local state = use(GameState)
					return state == "WAITING_BET" or state == "MATCHMAKING"
					end),
					[Fusion.Children] = {
						scope:New "Frame" {
							Position = UDim2.fromScale(0.5, 0.45),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Size = UDim2.new(0.5, 0, 0.5, 0),
							BackgroundColor3 = Theme.MidBg,
							BackgroundTransparency = 0.2,
							[Fusion.Children] = {
								scope:New "UIAspectRatioConstraint" { AspectRatio = 1.0 },
								scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
								scope:New "UIStroke" { Color = Theme.NeonCyan, Thickness = 2 },
								
								scope:New "TextLabel" {
									Text = "◢ PLACE BET ◣",
									Size = UDim2.new(1, 0, 0.12, 0),
									Position = UDim2.fromScale(0, 0.05),
									BackgroundTransparency = 1,
									TextColor3 = Theme.NeonCyan,
									Font = Enum.Font.Code,
									TextScaled = true
								},
								
								scope:New "TextLabel" {
									Text = scope:Computed(function(use)
										local lobby = use(LobbyPlayers)
										local max = use(MaxPlayers)
										return "PLAYERS: "..#lobby.."/"..max
									end),
									Position = UDim2.fromScale(0, 0.2),
									Size = UDim2.new(1, 0, 0.08, 0),
									BackgroundTransparency = 1,
									TextColor3 = Theme.NeonGreen,
									Font = Enum.Font.Code,
									TextScaled = true
								},
								
								-- Bet input
								scope:New "Frame" {
									Position = UDim2.fromScale(0.1, 0.65),
									Size = UDim2.new(0.8, 0, 0.12, 0),
								BackgroundTransparency = 1,
								[Fusion.Children] = {
									scope:New "UIListLayout" {
										FillDirection = Enum.FillDirection.Horizontal,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
										VerticalAlignment = Enum.VerticalAlignment.Center,
										Padding = UDim.new(0, 10)
									},
									scope:New "TextLabel" {
										Text = "BET:",
										Size = UDim2.new(0.2, 0, 1, 0),
										BackgroundTransparency = 1,
										TextColor3 = Theme.NeonOrange,
										Font = Enum.Font.Code,
										TextScaled = true,
										TextXAlignment = Enum.TextXAlignment.Left
									},
									scope:New "TextBox" {
										Size = UDim2.new(0.45, 0, 1, 0),
										BackgroundColor3 = Theme.DarkBg,
										BackgroundTransparency = 0.3,
										Text = scope:Computed(function(use) return tostring(use(BetInput)) end),
										TextColor3 = Color3.new(1, 1, 1),
										Font = Enum.Font.Code,
										TextScaled = true,
										PlaceholderText = "50",
										[Fusion.OnEvent "FocusLost"] = function(text)
											local val = tonumber(text) or 50
											BetInput:set(math.clamp(val, 50, 50000))
										end,
										[Fusion.Children] = {
											scope:New "UICorner" { CornerRadius = UDim.new(0, 6) },
											scope:New "UIStroke" { Color = Theme.NeonOrange, Thickness = 2 }
										}
									},
									CasinoButton(scope, {
										Text = "PLACE BET",
										Size = UDim2.new(0.35, 0, 1, 0),
										Color = Theme.NeonGreen,
										OnClick = props.OnPlaceBet
									})
								}
							},
								
								scope:New "TextLabel" {
									Text = scope:Computed(function(use)
										local state = use(GameState)
										local timer = use(CountdownTimer)
										if state == "MATCHMAKING" then return "MATCHING... ["..timer.."s]"
										else return "" end
									end),
									Position = UDim2.fromScale(0, 0.85),
									Size = UDim2.new(1, 0, 0.08, 0),
									BackgroundTransparency = 1,
									TextColor3 = Theme.NeonMagenta,
									Font = Enum.Font.Code,
									TextScaled = true
								}
							}
						}
					}
				},
				
				-- [[ GAME SCREEN ]]
				scope:New "Frame" {
					Name = "GameScreen",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Visible = scope:Computed(function(use)
						local state = use(GameState)
						return state == "DEALING" or state == "PLAYER_TURN" or state == "DEALER_TURN" or state == "FINISHED"
					end),
					[Fusion.Children] = {
						-- Dealer Zone
						scope:New "Frame" {
							Name = "DealerZone",
							Position = UDim2.fromScale(0.5, 0.08),
							AnchorPoint = Vector2.new(0.5, 0),
							Size = UDim2.new(0.9, 0, 0.18, 0),
							BackgroundColor3 = Theme.DarkBg,
							BackgroundTransparency = 0.3,
							ZIndex = 2,
							[Fusion.Children] = {
								scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },
								scope:New "UIStroke" { Color = Theme.GlitchRed, Thickness = 2.5 },
								scope:New "TextLabel" {
									Text = scope:Computed(function(use)
										local d = use(Dealer)
										return "◢ DEALER_AI [SCORE: "..(d.Score or 0).."] ◣"
									end),
									Position = UDim2.fromScale(0, 0.05),
									Size = UDim2.new(1, 0, 0.2, 0),
									BackgroundTransparency = 1,
									TextColor3 = Theme.GlitchRed,
									Font = Enum.Font.Code,
									TextSize = 16,
									TextScaled = true,
									TextXAlignment = Enum.TextXAlignment.Left
								},
								scope:New "Frame" {
									Name = "DealerCards",
									Position = UDim2.fromScale(0.02, 0.3),
									Size = UDim2.new(0.96, 0, 0.65, 0),
									BackgroundTransparency = 1,
									[Fusion.Children] = {
										scope:New "UIListLayout" {
											FillDirection = Enum.FillDirection.Horizontal,
											Padding = UDim.new(0, 10)
										},
										scope:ForValues(
											scope:Computed(function(use) 
												local d = use(Dealer)
												return d.Hand or {}
											end),
											function(use, scope, cardData)
												return Card(scope, cardData)
										end
										)
									}
								}
							}
						},
						
						-- Players Zone (scrollable)
						scope:New "ScrollingFrame" {
							Name = "PlayersZone",
							Position = UDim2.fromScale(0.5, 0.28),
							AnchorPoint = Vector2.new(0.5, 0),
							Size = UDim2.new(0.9, 0, 0.22, 0),
							BackgroundColor3 = Theme.DarkBg,
							BackgroundTransparency = 0.5,
							BorderSizePixel = 0,
							ScrollBarThickness = 6,
							[Fusion.Children] = {
								scope:New "UIListLayout" {
									Padding = UDim.new(0, 10),
									SortOrder = Enum.SortOrder.LayoutOrder
								},
								scope:ForValues(
									scope:Computed(function(use)
										local allPlayers = use(Players)
										local filtered = {}
										for _, playerData in ipairs(allPlayers) do
											if playerData.Name ~= LocalPlayer.Name then
												table.insert(filtered, playerData)
											end
										end
										return filtered
									end),
									function(use, scope, playerData)
										return PlayerPanel(scope, playerData, playerData.IsCurrent or false)
									end
								)
							}
						},
						
						-- Result Display
						scope:New "Frame" {
							Name = "ResultDisplay",
							Position = UDim2.fromScale(0.5, 0.4),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Size = UDim2.new(0.7, 0, 0.15, 0),
							BackgroundColor3 = Theme.MidBg,
							BackgroundTransparency = 0.1,
							Visible = scope:Computed(function(use)
								return use(GameState) == "FINISHED"
							end),
							ZIndex = 20,
							[Fusion.Children] = {
								scope:New "UICorner" { CornerRadius = UDim.new(0, 15) },
								scope:New "UIStroke" { Color = Theme.NeonPink, Thickness = 4 },
								scope:New "TextLabel" {
									Text = scope:Computed(function(use) return use(Result) end),
									Size = UDim2.fromScale(1, 1),
									BackgroundTransparency = 1,
									TextColor3 = Theme.NeonPink,
									Font = Enum.Font.Code,
									TextSize = 28,
									TextScaled = true,
									TextStrokeTransparency = 0.2
								}
							}
						},
						
						-- Control Panel (bottom)
						scope:New "Frame" {
							Name = "ControlPanel",
							Position = UDim2.fromScale(0.5, 0.52),
							AnchorPoint = Vector2.new(0.5, 0),
							Size = UDim2.new(0.7, 0, 0.13, 0),
							BackgroundColor3 = Theme.MidBg,
							BackgroundTransparency = 0.2,
							ZIndex = 10,
							[Fusion.Children] = {
								scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
								scope:New "UIStroke" { Color = Theme.NeonCyan, Thickness = 3 },
								scope:New "TextLabel" {
									Text = scope:Computed(function(use)
										local myTurn = use(IsMyTurn)
										local timer = use(CountdownTimer)
										if myTurn and timer > 0 then
											return "◢ YOUR TURN ["..timer.."s] ◣"
										else
											return "◢ ACTIONS ◣"
										end
									end),
									Position = UDim2.fromScale(0, 0.05),
									Size = UDim2.new(1, 0, 0.25, 0),
									BackgroundTransparency = 1,
									TextColor3 = scope:Computed(function(use)
										return use(IsMyTurn) and Theme.NeonGreen or Theme.NeonCyan
									end),
									Font = Enum.Font.Code,
									TextSize = 14,
									TextScaled = true
								},
								scope:New "Frame" {
									Position = UDim2.fromScale(0.05, 0.35),
									Size = UDim2.new(0.9, 0, 0.6, 0),
									BackgroundTransparency = 1,
									[Fusion.Children] = {
										scope:New "UIListLayout" {
											FillDirection = Enum.FillDirection.Horizontal,
											HorizontalAlignment = Enum.HorizontalAlignment.Center,
											Padding = UDim.new(0, 15)
										},
										CasinoButton(scope, {
											Text = "HIT",
											Size = UDim2.new(0, 170, 1, 0),
											Color = Theme.NeonGreen,
											OnClick = props.OnHit,
											Order = 1,
											Disabled = scope:Computed(function(use) return not use(IsMyTurn) end)
										}),
										CasinoButton(scope, {
											Text = "STAND",
											Size = UDim2.new(0, 170, 1, 0),
											Color = Theme.NeonOrange,
											OnClick = props.OnStand,
											Order = 2,
											Disabled = scope:Computed(function(use) return not use(IsMyTurn) end)
										})
									}
								}
							}
						}
					}
				},
				
				-- [[ MY HAND ZONE - Always visible when in game ]]
				scope:New "Frame" {
					Name = "MyHandZone",
					Position = UDim2.fromScale(0.5, 0.67),
					AnchorPoint = Vector2.new(0.5, 0),
					Size = UDim2.new(0.9, 0, 0.18, 0),
					BackgroundColor3 = Theme.DarkBg,
					BackgroundTransparency = 0.25,
					Visible = scope:Computed(function(use)
						local state = use(GameState)
						return state ~= "WAITING_BET" and state ~= "MATCHMAKING"
					end),
					ZIndex = 15,
					[Fusion.Children] = {
						scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
						scope:New "UIStroke" { Color = Theme.NeonGreen, Thickness = 2 },
						scope:New "TextLabel" {
							Text = scope:Computed(function(use)
								local hand = use(MyHand)
								return "◢ YOUR HAND [SCORE: "..(hand.Score or 0).."] [BET: $"..(hand.Bet or 0).."] ◣"
							end),
							Position = UDim2.fromScale(0, 0.05),
							Size = UDim2.new(1, 0, 0.2, 0),
							BackgroundTransparency = 1,
							TextColor3 = Theme.NeonGreen,
							Font = Enum.Font.Code,
							TextSize = 14,
							TextScaled = true,
							TextXAlignment = Enum.TextXAlignment.Left
						},
						scope:New "Frame" {
							Name = "MyCards",
							Position = UDim2.fromScale(0.02, 0.3),
							Size = UDim2.new(0.96, 0, 0.65, 0),
							BackgroundTransparency = 1,
							[Fusion.Children] = {
								scope:New "UIListLayout" {
									FillDirection = Enum.FillDirection.Horizontal,
									HorizontalAlignment = Enum.HorizontalAlignment.Center,
									Padding = UDim.new(0, 8)
								},
								scope:ForValues(scope:Computed(function(use)
									local hand = use(MyHand)
									return hand.Hand or {}
								end), function(use, scope, cardData)
									return Card(scope, cardData)
								end)
							}
						}
					}
				}
			}
		}
	}
end

return MatchView