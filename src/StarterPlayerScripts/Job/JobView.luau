local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local JobView = {}
local Theme = GameConfig.CyberTheme

-- Mining Button với animation
local function MineButton(scope, props)
	local isHover = scope:Value(false)
	local isPressed = scope:Value(false)
	local scale = scope:Spring(
		scope:Computed(function(use) 
			if use(isPressed) then return 0.92
			elseif use(isHover) then return 1.05
			else return 1 end
		end), 
		50, 0.8
	)
	local rotation = scope:Spring(
		scope:Computed(function(use) return use(isPressed) and 5 or 0 end),
		40, 0.9
	)

	return scope:New "TextButton" {
		Text = "",
		Size = UDim2.fromScale(0.25, 0.25),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.MidBg,
		BackgroundTransparency = 0.1,
		[Fusion.OnEvent "Activated"] = props.OnClick,
		[Fusion.OnEvent "MouseButton1Down"] = function() isPressed:set(true) end,
		[Fusion.OnEvent "MouseButton1Up"] = function() isPressed:set(false) end,
		[Fusion.OnEvent "MouseEnter"] = function() isHover:set(true) end,
		[Fusion.OnEvent "MouseLeave"] = function() 
			isHover:set(false)
			isPressed:set(false)
		end,
		[Fusion.Children] = {
			scope:New "UIAspectRatioConstraint" { AspectRatio = 1 },
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },
			scope:New "UIStroke" { 
				Thickness = 4, 
				Color = props.CanMine and Theme.NeonCyan or Color3.fromRGB(100, 100, 100),
				Transparency = 0
			},
			
			-- Pickaxe Icon
			scope:New "TextLabel" {
				Text = "⛏",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				TextColor3 = props.CanMine and Theme.NeonCyan or Color3.fromRGB(150, 150, 150),
				TextSize = 80,
				Font = Enum.Font.Code,
				TextStrokeTransparency = 0.5,
				Rotation = rotation,
				ZIndex = 2
			},
			
			-- Glow effect
			scope:New "ImageLabel" {
				Size = UDim2.fromScale(1.3, 1.3),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = "rbxassetid://4724678792",
				ImageColor3 = Theme.NeonCyan,
				ImageTransparency = scope:Computed(function(use) 
					return use(props.CanMine) and 0.6 or 0.9
				end),
				ZIndex = 0
			}
		}
	}
end

function JobView.New(scope, props)
	print("⛏️ [JobView] Creating view with props:", props)
	
	return scope:New "ScreenGui" {
		Name = "UI_Mining", ResetOnSpawn = false, DisplayOrder = 50,
		Enabled = scope:Computed(function(use) return use(props.IsWorking) end),

		[Fusion.Children] = {
			-- Main Mining Window
			scope:New "Frame" {
				Name = "MiningWindow",
				Size = UDim2.fromScale(0.6, 0.5),
				Position = UDim2.fromScale(0.5, 0.5), 
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Theme.DarkBg,
				BackgroundTransparency = 0.1,

				[Fusion.Children] = {
					scope:New "UIAspectRatioConstraint" { AspectRatio = 1.2 },
					scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },
					scope:New "UIStroke" { 
						Color = Theme.NeonCyan, 
						Thickness = 3,
						Transparency = 0
					},
					
					-- Header
					scope:New "TextLabel" {
						Text = "◢ MINING ◣",
						Size = UDim2.new(1, 0, 0.12, 0),
						Position = UDim2.fromScale(0, 0.05),
						BackgroundTransparency = 1,
						TextColor3 = Theme.NeonCyan,
						Font = Enum.Font.Code,
						TextScaled = true,
						ZIndex = 10
					},
					
					-- Stats
					scope:New "TextLabel" {
						Text = scope:Computed(function(use)
							return string.format("▸ MINED: %d | EARNED: $%d", 
								use(props.TotalMined), 
								use(props.TotalEarned))
						end),
						Size = UDim2.new(1, 0, 0.1, 0),
						Position = UDim2.fromScale(0, 0.22),
						BackgroundTransparency = 1,
						TextColor3 = Theme.NeonGreen,
						Font = Enum.Font.Code,
						TextScaled = true,
						ZIndex = 10
					},
					
					-- Toggle Auto-Mine Button
					scope:New "TextButton" {
						Text = scope:Computed(function(use) 
							return use(props.IsAutoMining) and "⛏ AUTO-MINING..." or "⛏ START AUTO-MINE"
						end),
						Size = UDim2.fromScale(0.7, 0.15),
						Position = UDim2.fromScale(0.5, 0.55),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = scope:Computed(function(use)
							return use(props.IsAutoMining) and Theme.GlitchRed or Theme.NeonCyan
						end),
						BackgroundTransparency = 0.3,
						TextColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.Code,
						TextScaled = true,
						ZIndex = 10,
						[Fusion.OnEvent "Activated"] = props.OnToggleAutoMine,
						[Fusion.Children] = {
							scope:New "UIAspectRatioConstraint" { AspectRatio = 4.5 },
							scope:New "UICorner" { CornerRadius = UDim.new(0.2, 0) },
							scope:New "UIStroke" {
								Color = scope:Computed(function(use)
									return use(props.IsAutoMining) and Theme.GlitchRed or Theme.NeonCyan
								end),
								Thickness = 3
							}
						}
					},
					
					-- Status Text
					scope:New "TextLabel" {
						Text = scope:Computed(function(use) return use(props.StatusText) end),
						Size = UDim2.new(1, 0, 0.06, 0),
						Position = UDim2.fromScale(0, 0.78),
						BackgroundTransparency = 1,
						TextColor3 = Theme.NeonCyan,
						Font = Enum.Font.Code,
						TextScaled = true,
						ZIndex = 10
					},
					
					-- Exit Button
					scope:New "TextButton" {
						Text = "✕ EXIT",
						Size = UDim2.new(0.9, 0, 0.1, 0),
						Position = UDim2.fromScale(0.5, 0.92),
						AnchorPoint = Vector2.new(0.5, 1),
						BackgroundColor3 = Theme.GlitchRed,
						BackgroundTransparency = 0.3,
						TextColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.Code,
						TextScaled = true,
						ZIndex = 10,
						[Fusion.OnEvent "Activated"] = props.OnExit,
						[Fusion.Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
							scope:New "UIStroke" {
								Color = Theme.GlitchRed,
								Thickness = 2
							}
						}
					}
				}
			}
		}
	}
end

return JobView