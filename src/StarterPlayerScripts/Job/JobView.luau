local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local JobView = {}

-- Helper tạo nút lệnh
local function TerminalButton(scope, props)
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.02 or 1 end), 40, 1)

	return scope:New "TextButton" {
		Text = props.Text or "",
		Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = props.Color or Color3.fromRGB(0, 255, 100),
		BackgroundTransparency = 0.2,
		TextColor3 = Color3.new(0,0,0), Font = Enum.Font.Code, TextSize = 20,
		[Fusion.OnEvent "Activated"] = props.OnClick,
		[Fusion.OnEvent "MouseEnter"] = function() isHover:set(true) end,
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 4) },
			scope:New "UIStroke" { Thickness = 2, Color = props.Color or Color3.fromRGB(0, 255, 100), Transparency = 0.5 }
		}
	}
end

function JobView.New(scope, props)
	local inputText = scope:Value("")

	-- Hàm xử lý nộp bài
	local function doSubmit()
		props.OnSubmit(Fusion.peek(inputText))
		inputText:set("") -- Xóa input sau khi nộp
	end

	return scope:New "ScreenGui" {
		Name = "UI_Job", ResetOnSpawn = false, DisplayOrder = 20,
		Enabled = scope:Computed(function(use) return use(props.IsWorking) end),

		[Fusion.Children] = {
			-- Khung Terminal Chính
			scope:New "Frame" {
				Name = "TerminalWindow",
				Size = UDim2.fromOffset(500, 350), -- Kích thước cố định cho chuẩn
				Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(5, 10, 5),
				BackgroundTransparency = 0.1,

				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
					scope:New "UIStroke" { Color = Color3.fromRGB(0, 255, 0), Thickness = 2 },
					scope:New "UIPadding" { PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20), PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20) },

					-- Layout dọc: Header -> Target -> Input -> Button
					scope:New "UIListLayout" {
						FillDirection = "Vertical", HorizontalAlignment = "Center", 
						SortOrder = "LayoutOrder", Padding = UDim.new(0, 15)
					},

					-- 1. Header
					scope:New "TextLabel" {
						LayoutOrder = 1,
						Text = "/// SYSTEM_OVERRIDE_V4.0 ///",
						Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(0, 255, 0), Font = Enum.Font.Code, TextSize = 22,
					},

					-- 2. Target Box (Mã cần nhập)
					scope:New "Frame" {
						LayoutOrder = 2,
						Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = Color3.fromRGB(0, 20, 0),
						[Fusion.Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(0, 6) },
							scope:New "UIStroke" { Color = Color3.fromRGB(0, 150, 0), Thickness = 1 },
							scope:New "TextLabel" {
								Text = "DECRYPT_HASH:", Size = UDim2.new(1,0,0.3,0), BackgroundTransparency = 1,
								TextColor3 = Color3.fromRGB(0, 150, 0), Font = Enum.Font.Code, TextSize = 14
							},
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) return use(props.CurrentWord) end),
								Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0, 0.1), BackgroundTransparency = 1,
								TextColor3 = Color3.fromRGB(50, 255, 50), Font = Enum.Font.RobotoMono, TextSize = 40,
								TextStrokeTransparency = 0.8, TextStrokeColor3 = Color3.fromRGB(0, 255, 0)
							}
						}
					},

					-- 3. Input Field
					scope:New "TextBox" {
						LayoutOrder = 3,
						Text = "", PlaceholderText = "> ENTER_KEY...",
						Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = 24,
						[Fusion.OnEvent "FocusLost"] = function(enter) if enter then doSubmit() end end,
						[Fusion.Out "Text"] = inputText,
						[Fusion.Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(0, 6) },
							scope:New "UIStroke" { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.8, Thickness = 1 }
						}
					},

					-- 4. Submit Button (Mới)
					TerminalButton(scope, {
						LayoutOrder = 4,
						Text = ">> EXECUTE_PROTOCOL <<",
						Size = UDim2.new(1, 0, 0, 50),
						Color = Color3.fromRGB(0, 255, 100),
						OnClick = doSubmit
					})
				}
			}
		}
	}
end

return JobView