local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local BankView = {}

-- [[ NÚT BẤM CYBER (GOLD THEME) ]]
local function CyberButton(scope, props)
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 40, 1)

	return scope:New "TextButton" {
		Text = "", Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = Color3.fromRGB(25, 20, 10), -- Nền nâu đen
		BackgroundTransparency = props.Disabled and 0.5 or 0,
		AutoButtonColor = false,
		[Fusion.OnEvent "MouseEnter"] = function() if not props.Disabled then isHover:set(true) end end,
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		[Fusion.OnEvent "Activated"] = function() if not props.Disabled and props.OnClick then props.OnClick() end end,

		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },

			-- Viền Gradient Vàng
			scope:New "UIStroke" {
				Thickness = 2, Transparency = 0,
				[Fusion.Children] = {
					scope:New "UIGradient" {
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, props.Color or Color3.fromRGB(255, 215, 0)), -- Gold
							ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0))  -- Orange
						},
						Rotation = 45
					}
				}
			},

			scope:New "TextLabel" {
				Text = props.Text or "", Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
				TextColor3 = props.Color or Color3.fromRGB(255, 215, 0),
				Font = Enum.Font.GothamBlack, TextSize = 16, ZIndex = 2
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
				Text = "🏦", Size = UDim2.fromOffset(60, 60),
				Position = UDim2.new(0, 20, 0.5, -120),
				Color = Color3.fromRGB(255, 215, 0),
				OnClick = props.OnToggle
			}),

			-- Modal Chính
			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.45, 0.55), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(15, 12, 10),

				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },

					-- Viền Gradient Sang trọng
					scope:New "UIStroke" {
						Thickness = 3,
						[Fusion.Children] = {
							scope:New "UIGradient" {
								Color = ColorSequence.new{
									ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
									ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 69, 19))
								},
								Rotation = -45
							}
						}
					},

					-- Nền Grid
					scope:New "ImageLabel" {
						Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
						Image = "rbxassetid://6071575925", ImageColor3 = Color3.fromRGB(255, 200, 0), ImageTransparency = 0.95,
						ScaleType = "Tile", TileSize = UDim2.new(0, 40, 0, 40),
						[Fusion.Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 16) } }
					},

					-- Tiêu đề
					scope:New "TextLabel" {
						Text = "SECURE VAULT", Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(255, 215, 0), Font = Enum.Font.GothamBlack, TextSize = 32,
						TextXAlignment = "Left",
						[Fusion.Children] = { scope:New "UIPadding" { PaddingLeft = UDim.new(0, 30) } }
					},

					-- Nút Đóng
					CyberButton(scope, {
						Text = "✕", Size = UDim2.fromOffset(40, 40),
						Position = UDim2.new(1, -25, 0, 15), AnchorPoint = Vector2.new(1,0),
						Color = Color3.fromRGB(255, 80, 80), OnClick = props.OnClose
					}),

					-- Input Box (Style Két sắt)
					scope:New "TextBox" {
						Text = props.AmountInput, PlaceholderText = "ENTER AMOUNT...",
						Size = UDim2.new(0.85, 0, 0, 60), Position = UDim2.fromScale(0.5, 0.35), AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(5, 5, 5), TextColor3 = Color3.fromRGB(255, 215, 0),
						Font = Enum.Font.Code, TextSize = 28, ClearTextOnFocus = false,
						[Fusion.OnChange "Text"] = function(txt) local num = txt:gsub("%D", ""); props.AmountInput:set(num) end,
						[Fusion.Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },
							scope:New "UIStroke" { Color = Color3.fromRGB(100, 80, 0), Thickness = 2 }
						}
					},

					-- Nút Hành Động
					CyberButton(scope, {
						Text = "DEPOSIT", Size = UDim2.new(0.35, 0, 0, 50), Position = UDim2.new(0.3, 0, 0.7, 0), AnchorPoint = Vector2.new(0.5, 0.5),
						Color = Color3.fromRGB(0, 255, 100), OnClick = props.OnDeposit
					}),
					CyberButton(scope, {
						Text = "WITHDRAW", Size = UDim2.new(0.35, 0, 0, 50), Position = UDim2.new(0.7, 0, 0.7, 0), AnchorPoint = Vector2.new(0.5, 0.5),
						Color = Color3.fromRGB(255, 80, 80), OnClick = props.OnWithdraw
					})
				}
			}
		}
	}
end

return BankView