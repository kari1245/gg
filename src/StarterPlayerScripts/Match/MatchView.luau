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
		Size = UDim2.new(1, 0, 0, 220),
		BackgroundColor3 = Theme.DarkBg,
		BackgroundTransparency = 0.3,
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" { Color = borderColor, Thickness = 2, Transparency = 0 },

			-- Player info header
			scope:New "Frame" {
				Size = UDim2.new(1, 0, 0, 50),
				BackgroundTransparency = 1,
				[Fusion.Children] = {
					scope:New "TextLabel" {
						Text = name,
						Position = UDim2.fromScale(0.5, 0.2),
						AnchorPoint = Vector2.new(0.5, 0),
						Size = UDim2.new(0.9, 0, 0, 16),
						BackgroundTransparency = 1,
						TextColor3 = Theme.NeonCyan,
						Font = Enum.Font.Code,
						TextSize = 12,
						TextTruncate = Enum.TextTruncate.AtEnd
					},
					scope:New "TextLabel" {
						Text = "$"..bet.." | "..score.." | "..state,
						Position = UDim2.fromScale(0.5, 0.7),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.new(0.9, 0, 0, 14),
						BackgroundTransparency = 1,
						TextColor3 = (score > 21 and Theme.GlitchRed or Theme.NeonOrange),
						Font = Enum.Font.Code,
						TextSize = 10
					}
				}
			},

			-- Cards display
			scope:New "Frame" {
				Name = "CardsContainer",
				Position = UDim2.fromOffset(0, 55),
				Size = UDim2.new(1, 0, 1, -60),
				BackgroundTransparency = 1,
				[Fusion.Children] = {
					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Top,
						Padding = UDim.new(0, 4)
					},
					scope:ForValues(
						scope:Computed(function(use) return hand end),
						function(use, scope, cardData)
							return scope:New "Frame" {
								Size = UDim2.new(0.85, 0, 0, 32),
								BackgroundColor3 = Theme.MidBg,
								BackgroundTransparency = 0.2,
								[Fusion.Children] = {
									scope:New "UICorner" { CornerRadius = UDim.new(0, 4) },
									scope:New "UIStroke" { 
										Color = (cardData.Suit == "Hearts" or cardData.Suit == "Diamonds") and Theme.GlitchRed or Theme.NeonCyan, 
										Thickness = 1 
									},
									scope:New "TextLabel" {
										Text = cardData.Rank .. (cardData.Suit ~= "Hidden" and " " .. cardData.Suit:sub(1,1) or " ?"),
										Size = UDim2.fromScale(1, 1),
										BackgroundTransparency = 1,
										TextColor3 = (cardData.Suit == "Hearts" or cardData.Suit == "Diamonds") and Theme.GlitchRed or Color3.new(1, 1, 1),
										Font = Enum.Font.Code,
										TextSize = 14
									}
								}
							}
						end
					)
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
		[Fusion.Children] = {
			scope:New "Frame" {
				Name = "MainContainer",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Visible = scope:Computed(function(use) return use(IsSitting) end),
				[Fusion.Children] = {
					scope:New "Frame" { -- Game Panel
						Name = "GamePanel",
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.new(0.68, 0, 0.88, 0),
						BackgroundColor3 = Theme.DarkBg,
						BackgroundTransparency = 0.15,
						[Fusion.Children] = {
							scope:New "UIAspectRatioConstraint" { AspectRatio = 1.75 },
							scope:New "UICorner" { CornerRadius = UDim.new(0, 15) },
							scope:New "UIStroke" { Color = Theme.NeonCyan, Thickness = 3 },
							scope:New "ImageLabel" {
								Size = UDim2.fromScale(1.1, 1.1),
								Position = UDim2.fromScale(0.5, 0.5),
								AnchorPoint = Vector2.new(0.5, 0.5),
								BackgroundTransparency = 1,
								Image = "rbxassetid://4724678792",
								ImageColor3 = Theme.NeonCyan,
								ImageTransparency = 0.92,
								ZIndex = 0
							},
							-- Header
							scope:New "TextLabel" {
								Name = "Header",
								Position = UDim2.fromScale(0.5, 0.03),
								AnchorPoint = Vector2.new(0.5, 0),
								Size = UDim2.new(0.8, 0, 0.08, 0),
								BackgroundTransparency = 1,
								Text = "◢ BLACKJACK TABLE ◣",
								TextColor3 = Theme.NeonCyan,
								Font = Enum.Font.Code,
								TextScaled = true,
								TextStrokeTransparency = 0.3,
								ZIndex = 2
							},
							
							-- Close button (red circle at top-right)
							scope:New "TextButton" {
								Name = "CloseButton",
								Position = UDim2.new(1, -15, 0, 15),
								AnchorPoint = Vector2.new(1, 0),
								Size = UDim2.fromOffset(45, 45),
								BackgroundColor3 = Theme.GlitchRed,
								BackgroundTransparency = 0.2,
								Text = "✕",
								TextColor3 = Color3.new(1, 1, 1),
								Font = Enum.Font.Code,
								TextSize = 24,
								TextStrokeTransparency = 0.5,
								ZIndex = 10,
								[Fusion.OnEvent "Activated"] = props.OnLeave,
								[Fusion.Children] = {
									scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },
									scope:New "UIStroke" { 
										Color = Theme.GlitchRed, 
										Thickness = 2
									}
								}
							},
							
							-- Lobby Screen
							scope:New "Frame" {
								Name = "LobbyScreen",
								Position = UDim2.fromScale(0.5, 0.5),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Size = UDim2.new(0.9, 0, 0.8, 0),
								BackgroundTransparency = 1,
								Visible = scope:Computed(function(use)
									local state = use(GameState)
									return state == "WAITING_BET" or state == "MATCHMAKING"
								end),
								[Fusion.Children] = {
									-- Bet Section
									scope:New "Frame" {
										Name = "BetSection",
										Position = UDim2.fromScale(0.5, 0.25),
										AnchorPoint = Vector2.new(0.5, 0.5),
										Size = UDim2.new(0.7, 0, 0.3, 0),
										BackgroundColor3 = Theme.MidBg,
										BackgroundTransparency = 0.3,
										[Fusion.Children] = {
											scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
											scope:New "UIStroke" { Color = Theme.NeonOrange, Thickness = 2 },

											scope:New "TextLabel" {
												Text = "◢ PLACE YOUR BET ◣",
												Position = UDim2.fromScale(0, 0.1),
												Size = UDim2.new(1, 0, 0.2, 0),
												BackgroundTransparency = 1,
												TextColor3 = Theme.NeonOrange,
												Font = Enum.Font.Code,
												TextScaled = true
											},

											scope:New "Frame" {
												Position = UDim2.fromScale(0.1, 0.45),
												Size = UDim2.new(0.8, 0, 0.25, 0),
												BackgroundTransparency = 1,
												[Fusion.Children] = {
													scope:New "UIListLayout" {
														FillDirection = Enum.FillDirection.Horizontal,
														HorizontalAlignment = Enum.HorizontalAlignment.Center,
														Padding = UDim.new(0, 10)
													},
													scope:New "TextBox" {
														Size = UDim2.new(0.5, 0, 1, 0),
														BackgroundColor3 = Theme.DarkBg,
														BackgroundTransparency = 0.3,
														Text = scope:Computed(function(use) return "$" .. tostring(use(BetInput)) end),
														TextColor3 = Color3.new(1, 1, 1),
														Font = Enum.Font.Code,
														TextScaled = true,
														PlaceholderText = "$50",
														[Fusion.OnEvent "FocusLost"] = function(text)
															local cleaned = text:gsub("%$", "")
															local val = tonumber(cleaned) or 50
															BetInput:set(math.clamp(val, 50, 50000))
														end,
														[Fusion.Children] = {
															scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
															scope:New "UIStroke" { Color = Theme.NeonOrange, Thickness = 2 }
														}
													},
													CasinoButton(scope, {
														Text = "✓ CONFIRM",
														Size = UDim2.new(0.4, 0, 1, 0),
														Color = Theme.NeonGreen,
														OnClick = props.OnPlaceBet
													})
												}
											}
										}
									},

									-- Players Waiting
									scope:New "Frame" {
										Name = "WaitingPlayers",
										Position = UDim2.fromScale(0.5, 0.65),
										AnchorPoint = Vector2.new(0.5, 0.5),
										Size = UDim2.new(0.85, 0, 0.5, 0),
										BackgroundColor3 = Theme.MidBg,
										BackgroundTransparency = 0.4,
										[Fusion.Children] = {
											scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },
											scope:New "UIStroke" { Color = Theme.NeonPurple, Thickness = 2 },

											scope:New "TextLabel" {
												Text = scope:Computed(function(use)
													local lobby = use(LobbyPlayers)
													local max = use(MaxPlayers)
													local state = use(GameState)
													if state == "MATCHMAKING" then
														local timer = use(CountdownTimer)
														return "◢ MATCHING... ["..timer.."s] ◣ ("..#lobby.."/"..max..")"
													end
													return "◢ WAITING ROOM ◣ ("..#lobby.."/"..max..")"
												end),
												Position = UDim2.fromScale(0, 0.05),
												Size = UDim2.new(1, 0, 0.15, 0),
												BackgroundTransparency = 1,
												TextColor3 = scope:Computed(function(use)
													return use(GameState) == "MATCHMAKING" and Theme.NeonMagenta or Theme.NeonPurple
												end),
												Font = Enum.Font.Code,
												TextScaled = true
											},

											scope:New "ScrollingFrame" {
												Position = UDim2.fromScale(0.05, 0.25),
												Size = UDim2.new(0.9, 0, 0.55, 0),
												BackgroundTransparency = 1,
												BorderSizePixel = 0,
												ScrollBarThickness = 4,
												[Fusion.Children] = {
													scope:New "UIListLayout" {
														Padding = UDim.new(0, 8),
														HorizontalAlignment = Enum.HorizontalAlignment.Center
													},
													scope:ForValues(
														scope:Computed(function(use) return use(LobbyPlayers) end),
														function(use, scope, playerData)
															local playerName = type(playerData) == "string" and playerData or playerData.Name or "Unknown"
															return scope:New "TextLabel" {
																Size = UDim2.new(0.9, 0, 0, 35),
																BackgroundColor3 = Theme.DarkBg,
																BackgroundTransparency = 0.3,
																Text = "◆ " .. playerName,
																TextColor3 = Theme.NeonCyan,
																Font = Enum.Font.Code,
																TextSize = 18,
																[Fusion.Children] = {
																	scope:New "UICorner" { CornerRadius = UDim.new(0, 6) },
																	scope:New "UIStroke" { Color = Theme.NeonCyan, Thickness = 1 }
																}
															}
														end
													)
												}
											}
										}
									}
								}
							},
							-- Game Screen
							scope:New "Frame" {
								Name = "GameScreen",
								Position = UDim2.fromScale(0.5, 0.54),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Size = UDim2.new(0.96, 0, 0.84, 0),
								BackgroundTransparency = 1,
								Visible = scope:Computed(function(use)
									local state = use(GameState)
									return state == "DEALING" or state == "PLAYER_TURN" or state == "DEALER_TURN" or state == "FINISHED"
								end),
								[Fusion.Children] = {
									-- Dealer Zone
									scope:New "Frame" {
										Name = "DealerZone",
										Position = UDim2.fromScale(0, 0),
										Size = UDim2.new(1, 0, 0.28, 0),
										BackgroundColor3 = Theme.MidBg,
										BackgroundTransparency = 0.35,
										[Fusion.Children] = {
											scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },
											scope:New "UIStroke" { Color = Theme.GlitchRed, Thickness = 2 },
											scope:New "TextLabel" {
												Text = scope:Computed(function(use)
													local d = use(Dealer)
													return "◢ DEALER [SCORE: "..(d.Score or 0).."] ◣"
												end),
												Position = UDim2.fromScale(0.02, 0.08),
												Size = UDim2.new(0.96, 0, 0.18, 0),
												BackgroundTransparency = 1,
												TextColor3 = Theme.GlitchRed,
												Font = Enum.Font.Code,
												TextScaled = true
											},
											scope:New "Frame" {
												Name = "DealerCards",
												Position = UDim2.fromScale(0.02, 0.32),
												Size = UDim2.new(0.96, 0, 0.62, 0),
												BackgroundTransparency = 1,
												[Fusion.Children] = {
													scope:New "UIListLayout" {
														FillDirection = Enum.FillDirection.Horizontal,
														HorizontalAlignment = Enum.HorizontalAlignment.Center,
														Padding = UDim.new(0, 8)
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

									-- My Hand Zone
									scope:New "Frame" {
										Name = "MyHandZone",
										Position = UDim2.fromScale(0, 0.32),
										Size = UDim2.new(1, 0, 0.32, 0),
										BackgroundColor3 = Theme.MidBg,
										BackgroundTransparency = 0.35,
										[Fusion.Children] = {
											scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },
											scope:New "UIStroke" { Color = Theme.NeonGreen, Thickness = 2 },
											scope:New "TextLabel" {
												Text = scope:Computed(function(use)
													local hand = use(MyHand)
													return "◢ YOUR HAND [SCORE: "..(hand.Score or 0).."] [BET: $"..(hand.Bet or 0).."] ◣"
												end),
												Position = UDim2.fromScale(0.02, 0.08),
												Size = UDim2.new(0.96, 0, 0.18, 0),
												BackgroundTransparency = 1,
												TextColor3 = Theme.NeonGreen,
												Font = Enum.Font.Code,
												TextScaled = true
											},
											scope:New "Frame" {
												Name = "MyCards",
												Position = UDim2.fromScale(0.02, 0.32),
												Size = UDim2.new(0.96, 0, 0.62, 0),
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
									},

									-- Bottom Section: Other Players + Actions
									scope:New "Frame" {
										Name = "BottomSection",
										Position = UDim2.fromScale(0, 0.68),
										Size = UDim2.new(1, 0, 0.32, 0),
										BackgroundTransparency = 1,
										[Fusion.Children] = {
											-- Other Players (Left)
											scope:New "ScrollingFrame" {
												Name = "OtherPlayers",
												Position = UDim2.fromScale(0, 0),
												Size = UDim2.new(0.68, 0, 1, 0),
												BackgroundColor3 = Theme.MidBg,
												BackgroundTransparency = 0.4,
												BorderSizePixel = 0,
												ScrollBarThickness = 4,
												AutomaticCanvasSize = Enum.AutomaticSize.X,
												CanvasSize = UDim2.fromScale(0, 0),
												[Fusion.Children] = {
													scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },
													scope:New "UIStroke" { Color = Theme.NeonPurple, Thickness = 2 },
													scope:New "UIListLayout" {
														Padding = UDim.new(0, 8),
														FillDirection = Enum.FillDirection.Horizontal,
														VerticalAlignment = Enum.VerticalAlignment.Center,
														HorizontalAlignment = Enum.HorizontalAlignment.Left
													},
													scope:New "UIPadding" {
														PaddingLeft = UDim.new(0, 8),
														PaddingRight = UDim.new(0, 8)
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

											-- Action Panel (Right)
											scope:New "Frame" {
												Name = "ActionPanel",
												Position = UDim2.fromScale(0.7, 0),
												Size = UDim2.new(0.3, 0, 1, 0),
												BackgroundColor3 = Theme.MidBg,
												BackgroundTransparency = 0.3,
												[Fusion.Children] = {
													scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },
													scope:New "UIStroke" { Color = Theme.NeonCyan, Thickness = 2 },
													scope:New "TextLabel" {
														Text = scope:Computed(function(use)
															local myTurn = use(IsMyTurn)
															local timer = use(CountdownTimer)
															if myTurn and timer > 0 then
																return "YOUR TURN ["..timer.."s]"
															end
															return "ACTIONS"
														end),
														Position = UDim2.fromScale(0, 0.08),
														Size = UDim2.new(1, 0, 0.18, 0),
														BackgroundTransparency = 1,
														TextColor3 = scope:Computed(function(use)
															return use(IsMyTurn) and Theme.NeonGreen or Theme.NeonCyan
														end),
														Font = Enum.Font.Code,
														TextScaled = true
													},
													scope:New "Frame" {
														Position = UDim2.fromScale(0.1, 0.32),
														Size = UDim2.new(0.8, 0, 0.62, 0),
														BackgroundTransparency = 1,
														[Fusion.Children] = {
															scope:New "UIListLayout" {
																FillDirection = Enum.FillDirection.Vertical,
																HorizontalAlignment = Enum.HorizontalAlignment.Center,
																Padding = UDim.new(0, 6)
															},
															CasinoButton(scope, {
																Text = "▸ HIT",
																Size = UDim2.new(1, 0, 0.28, 0),
																Color = Theme.NeonGreen,
																OnClick = props.OnHit,
																Order = 1,
																Disabled = scope:Computed(function(use) return not use(IsMyTurn) end)
															}),
															CasinoButton(scope, {
																Text = "■ STAND",
																Size = UDim2.new(1, 0, 0.28, 0),
																Color = Theme.NeonOrange,
																OnClick = props.OnStand,
																Order = 2,
																Disabled = scope:Computed(function(use) return not use(IsMyTurn) end)
															}),
															CasinoButton(scope, {
																Text = "✕ LEAVE",
																Size = UDim2.new(1, 0, 0.28, 0),
																Color = Theme.GlitchRed,
																OnClick = props.OnLeave,
																Order = 3,
																Disabled = scope:Value(false)
															})
														}
													}
												}
											}
										}
									},

									-- Result Display Overlay
									scope:New "Frame" {
										Name = "ResultDisplay",
										Position = UDim2.fromScale(0.5, 0.5),
										AnchorPoint = Vector2.new(0.5, 0.5),
										Size = UDim2.new(0.7, 0, 0.2, 0),
										BackgroundColor3 = Theme.DarkBg,
										BackgroundTransparency = 0.1,
										Visible = scope:Computed(function(use)
											return use(GameState) == "FINISHED"
										end),
										ZIndex = 30,
										[Fusion.Children] = {
											scope:New "UICorner" { CornerRadius = UDim.new(0, 15) },
											scope:New "UIStroke" { Color = Theme.NeonPink, Thickness = 4 },
											scope:New "ImageLabel" {
												Size = UDim2.fromScale(1.05, 1.05),
												Position = UDim2.fromScale(0.5, 0.5),
												AnchorPoint = Vector2.new(0.5, 0.5),
												BackgroundTransparency = 1,
												Image = "rbxassetid://5028857084",
												ImageColor3 = Theme.NeonPink,
												ImageTransparency = 0.5,
												ZIndex = 29
											},
											scope:New "TextLabel" {
												Text = scope:Computed(function(use) return use(Result) end),
												Size = UDim2.fromScale(1, 1),
												BackgroundTransparency = 1,
												TextColor3 = Theme.NeonPink,
												Font = Enum.Font.Code,
												TextScaled = true,
												TextStrokeTransparency = 0,
												ZIndex = 30
											}
										}
									}
								}
							}
						}
					}, -- End GamePanel
					
					scope:New "Frame" { -- Players Panel
						Name = "PlayersPanel",
						Position = UDim2.fromScale(0.99, 0.5),
						AnchorPoint = Vector2.new(1, 0.5),
						Size = UDim2.new(0.18, 0, 0.88, 0),
						BackgroundColor3 = Theme.DarkBg,
						BackgroundTransparency = 0.15,
						Visible = scope:Computed(function(use)
							local state = use(GameState)
							return state == "DEALING" or state == "PLAYER_TURN" or state == "DEALER_TURN" or state == "FINISHED"
						end),
						[Fusion.Children] = {
							scope:New "UIAspectRatioConstraint" { AspectRatio = 0.45 },
							scope:New "UICorner" { CornerRadius = UDim.new(0, 15) },
							scope:New "UIStroke" { Color = Theme.NeonPurple, Thickness = 3 },

							-- Header
							scope:New "TextLabel" {
								Position = UDim2.fromScale(0.5, 0.05),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Size = UDim2.new(0.9, 0, 0.08, 0),
								BackgroundTransparency = 1,
								Text = "◢ PLAYERS ◣",
								TextColor3 = Theme.NeonPurple,
								Font = Enum.Font.Code,
								TextScaled = true,
								TextStrokeTransparency = 0.3
							},

							-- Players List
							scope:New "ScrollingFrame" {
								Position = UDim2.fromScale(0.05, 0.12),
								Size = UDim2.new(0.9, 0, 0.83, 0),
								BackgroundTransparency = 1,
								BorderSizePixel = 0,
								ScrollBarThickness = 4,
								AutomaticCanvasSize = Enum.AutomaticSize.Y,
								CanvasSize = UDim2.fromScale(0, 0),
								[Fusion.Children] = {
									scope:New "UIListLayout" {
										Padding = UDim.new(0, 10),
										HorizontalAlignment = Enum.HorizontalAlignment.Center
									},
									scope:ForValues(
										scope:Computed(function(use)
											return use(Players)
										end),
										function(use, scope, playerData)
											return PlayerPanel(scope, playerData, playerData.IsCurrent or false)
										end
									)
								}
							}
						}
					}
				}
			}
		}
	}
end

return MatchView