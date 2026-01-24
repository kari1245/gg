local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local MiniGameView = {}
local Theme = GameConfig.CyberTheme

-- Cyber Button Component
local function CyberButton(scope, props)
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 40, 1)

	return scope:New "TextButton" {
		Text = "", Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		BackgroundColor3 = Theme.DarkBg,
		BackgroundTransparency = 0.2,
		AutoButtonColor = false,
		[Fusion.OnEvent "MouseEnter"] = function() isHover:set(true) end,
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		[Fusion.OnEvent "Activated"] = function() if props.OnClick then props.OnClick() end end,

		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" {
				Thickness = 2.5,
				Color = props.Color or Theme.NeonCyan,
				Transparency = 0
			},
			scope:New "ImageLabel" {
				Size = UDim2.fromScale(1.15, 1.15), Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
				Image = "rbxassetid://5028857084",
				ImageColor3 = props.Color or Theme.NeonCyan,
				ImageTransparency = 0.65, ZIndex = -1
			},
			scope:New "TextLabel" {
				Text = props.Text or "", Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
				TextColor3 = props.Color or Theme.NeonCyan,
				Font = Enum.Font.Code, TextSize = props.TextSize or 16,
				TextStrokeTransparency = 0.5, ZIndex = 2,
				[Fusion.Children] = props.Icon and {
					scope:New "TextLabel" {
						Text = props.Icon,
						Size = UDim2.fromScale(0.3, 0.3),
						Position = UDim2.fromScale(0.15, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						TextColor3 = props.Color or Theme.NeonCyan,
						Font = Enum.Font.Code,
						TextSize = 32,
						TextStrokeTransparency = 0.3,
						ZIndex = 3
					}
				} or nil
			}
		}
	}
end

-- Game Card Component
local function GameCard(scope, props)
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 35, 0.9)
	
	return scope:New "TextButton" {
		Text = "",
		Size = UDim2.new(1, 0, 0, 100), -- Fixed height giống Achievement items
		BackgroundColor3 = Theme.DarkBg,
		BackgroundTransparency = 0.15,
		AutoButtonColor = false,
		LayoutOrder = props.LayoutOrder,
		[Fusion.OnEvent "MouseEnter"] = function() isHover:set(true) end,
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		[Fusion.OnEvent "Activated"] = function() if props.OnClick then props.OnClick() end end,
		
		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
			scope:New "UIStroke" {
				Thickness = 2.5,
				Color = props.Color or Theme.NeonCyan,
				Transparency = 0
			},
			
			-- Glow effect
			scope:New "ImageLabel" {
				Size = UDim2.fromScale(1.15, 1.15),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = "rbxassetid://5028857084",
				ImageColor3 = props.Color or Theme.NeonCyan,
				ImageTransparency = 0.7,
				ZIndex = 0
			},
			
			-- Icon
			scope:New "TextLabel" {
				Text = props.Icon or "🎮",
				Size = UDim2.fromScale(0.35, 0.5),
				Position = UDim2.fromScale(0.2, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				TextColor3 = props.Color or Theme.NeonCyan,
				Font = Enum.Font.Code,
				TextScaled = true,
				TextStrokeTransparency = 0.3,
				ZIndex = 2
			},
			
			-- Title
			scope:New "TextLabel" {
				Text = props.Title or "GAME",
				Size = UDim2.fromScale(0.5, 0.35),
				Position = UDim2.fromScale(0.65, 0.35),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				TextColor3 = props.Color or Theme.NeonCyan,
				Font = Enum.Font.Code,
				TextSize = 22,
				TextStrokeTransparency = 0.5,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2
			},
			
			-- Description
			scope:New "TextLabel" {
				Text = props.Description or "Play now",
				Size = UDim2.fromScale(0.5, 0.25),
				Position = UDim2.fromScale(0.65, 0.65),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				TextColor3 = Theme.GridColor,
				Font = Enum.Font.Code,
				TextSize = 14,
				TextStrokeTransparency = 0.7,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2
			}
		}
	}
end

function MiniGameView.New(scope, props)
	local IsOpen = props.IsOpen
	
	-- Right side toggle button
	local toggleButton = CyberButton(scope, {
		Text = "◆ GME",
		Size = UDim2.new(0.065, 0, 0.09, 0),
		Position = UDim2.fromScale(0.92, 0.57),
		Color = Theme.NeonPurple,
		OnClick = props.OnToggle
	})
	
	-- Main panel
	local panel = scope:New "Frame" {
		Name = "MiniGamePanel",
		Size = UDim2.fromScale(0.75, 0.75),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.DarkBg,
		BackgroundTransparency = 0.05,
		Visible = scope:Computed(function(use) return use(IsOpen) end),
		ZIndex = 200,
		
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
			scope:New "UIStroke" {
				Color = Theme.NeonPurple,
				Thickness = 3,
				Transparency = 0
			},
			
			-- Glow border
			scope:New "ImageLabel" {
				Size = UDim2.fromScale(1.05, 1.05),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = "rbxassetid://5028857084",
				ImageColor3 = Theme.NeonPurple,
				ImageTransparency = 0.6,
				ZIndex = 0
			},
			
			-- Nền Grid
			scope:New "ImageLabel" {
				Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
				Image = "rbxassetid://6071575925", 
				ImageColor3 = Theme.NeonPurple, ImageTransparency = 0.91,
				ScaleType = "Tile", TileSize = UDim2.fromOffset(45, 45),
				ZIndex = 0,
				[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 12) } }
			},
			
			-- Title
			scope:New "TextLabel" {
				Text = "◢◤ MINI GAMES ◥◣",
				Size = UDim2.new(1, 0, 0.12, 0),
				BackgroundTransparency = 1,
				TextColor3 = Theme.NeonPurple,
				Font = Enum.Font.Code,
				TextSize = 28,
				TextScaled = true,
				TextStrokeTransparency = 0.3,
				ZIndex = 3
			},
			
			-- Close button
			CyberButton(scope, {
				Text = "✕",
				Size = UDim2.fromScale(0.08, 0.1),
				Position = UDim2.fromScale(0.96, 0.04),
				AnchorPoint = Vector2.new(1, 0),
				Color = Theme.GlitchRed,
				OnClick = props.OnClose
			}),
			
			-- Games container
			scope:New "ScrollingFrame" {
				Size = UDim2.fromScale(0.94, 0.82),
				Position = UDim2.fromScale(0.5, 0.56),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				ScrollBarThickness = 8,
				ScrollBarImageColor3 = Theme.NeonPurple,
				CanvasSize = UDim2.fromScale(0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ZIndex = 2,
				
				[Fusion.Children] = {
					scope:New "UIListLayout" {
						Padding = UDim.new(0.03, 0),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder
					},
					scope:New "UIPadding" {
						PaddingTop = UDim.new(0.02, 0),
						PaddingBottom = UDim.new(0.02, 0)
					},
					
					-- Blackjack Game Card
					GameCard(scope, {
						Icon = "♠",
						Title = "BLACKJACK",
						Description = "Beat the dealer • Win 21",
						Color = Theme.NeonCyan,
						LayoutOrder = 1,
						OnClick = props.OnPlayBlackjack
					}),
					
					-- Roulette - Coming soon
					GameCard(scope, {
						Icon = "⚪",
						Title = "ROULETTE",
						Description = "Coming Soon...",
						Color = Theme.GridColor,
						LayoutOrder = 2,
						OnClick = function() end
					}),
					
					-- Slots - Coming soon
					GameCard(scope, {
						Icon = "🎰",
						Title = "SLOTS",
						Description = "Coming Soon...",
						Color = Theme.GridColor,
						LayoutOrder = 3,
						OnClick = function() end
					}),
					
					-- Poker - Coming soon
					GameCard(scope, {
						Icon = "♦",
						Title = "POKER",
						Description = "Coming Soon...",
						Color = Theme.GridColor,
						LayoutOrder = 4,
						OnClick = function() end
					})
				}
			}
		}
	}
	
	return scope:New "ScreenGui" {
		Name = "MiniGameUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		[Fusion.Children] = { toggleButton, panel }
	}
end

return MiniGameView
