local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local JobView = {}

function JobView.New(scope, props)
	local inputText = scope:Value("")

	return scope:New "ScreenGui" {
		Name = "UI_Job", ResetOnSpawn = false, DisplayOrder = 20,
		Enabled = scope:Computed(function(use) return use(props.IsWorking) end),

		[Fusion.Children] = {
			scope:New "Frame" {
				Size = UDim2.fromScale(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(0, 5, 0), BackgroundTransparency = 0.1,

				[Fusion.Children] = {
					scope:New "UIStroke" { Color = Color3.fromRGB(0, 255, 50), Thickness = 2 },
					scope:New "TextLabel" {
						Text = "> ROOT_ACCESS_TERMINAL", Position = UDim2.new(0,15,0,10), Size = UDim2.new(1,-30,0,30),
						TextColor3 = Color3.fromRGB(0, 255, 50), Font = Enum.Font.Code, TextXAlignment = "Left", TextSize = 18
					},

					-- Target Code
					scope:New "TextLabel" {
						Text = scope:Computed(function(use) return "TARGET_HASH: " .. use(props.CurrentWord) end),
						Size = UDim2.fromScale(1, 0.2), Position = UDim2.fromScale(0, 0.4),
						TextColor3 = Color3.fromRGB(255, 50, 50), Font = Enum.Font.Code, TextSize = 36
					},

					-- Input Field
					scope:New "TextBox" {
						Text = "", PlaceholderText = "ENTER_DECRYPT_KEY...",
						Size = UDim2.new(0.8, 0, 0, 60), Position = UDim2.fromScale(0.5, 0.7), AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(0, 20, 0), TextColor3 = Color3.fromRGB(0, 255, 50),
						Font = Enum.Font.Code, TextSize = 28,
						[Fusion.OnEvent "FocusLost"] = function(enter)
							if enter then
								props.OnSubmit(Fusion.peek(inputText))
								inputText:set("")
							end
						end,
						[Fusion.Out "Text"] = inputText,
						[Fusion.Children] = { scope:New "UIStroke" { Color = Color3.fromRGB(0, 255, 50), Transparency = 0.5 } }
					}
				}
			}
		}
	}
end

return JobView