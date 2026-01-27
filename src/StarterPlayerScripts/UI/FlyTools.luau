local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Value = Fusion.Value
local Computed = Fusion.Computed

-- Màu sắc (Giữ theme Sci-Fi)
local COLORS = {
	SLATE_900 = Color3.fromRGB(15, 23, 42),
	CYAN_400 = Color3.fromRGB(34, 211, 238),
	CYAN_900 = Color3.fromRGB(22, 78, 99),
}

-- Component nút bấm riêng cho Fly Tools
local function FlyButton(scope: any, props: {OnClick: () -> ()})
	local isHovered = Value(scope, false)
	
	return New(scope, "TextButton") ({
		Name = "FlyToggleButton",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Computed(scope, function(use)
			return use(isHovered) and COLORS.CYAN_900 or COLORS.SLATE_900
		end),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 2,
		BorderColor3 = COLORS.CYAN_400,
		Text = "",
		AutoButtonColor = false,
		
		[OnEvent "MouseEnter"] = function() isHovered:set(true) end,
		[OnEvent "MouseLeave"] = function() isHovered:set(false) end,
		[OnEvent "MouseButton1Click"] = props.OnClick,
		
		[Children] = {
			New(scope, "UICorner") ({ CornerRadius = UDim.new(0, 6) }),
			
			New(scope, "TextLabel") ({
				Text = "✈️ FLY MODE (F)",
				Font = Enum.Font.SciFi,
				TextColor3 = COLORS.CYAN_400,
				TextSize = 22,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				TextStrokeTransparency = 0.8
			})
		}
	})
end

-- Main Component
return function(props)
	local scope = Fusion.scoped(Fusion)
	local FlyController = Knit.GetController("FlyController")

	local gui = New(scope, "ScreenGui") ({
		Name = "FlyToolsHUD",
		ResetOnSpawn = false,
		DisplayOrder = 20, -- Luôn nằm trên các UI khác
		
		[Children] = {
			New(scope, "Frame") ({
				Name = "Container",
				-- Vị trí: Bên trái, nằm dưới Menu Sidebar (Sidebar thường kết thúc ở 0.7Y)
				Position = UDim2.fromScale(0.02, 0.75), 
				Size = UDim2.fromOffset(200, 50),
				BackgroundTransparency = 1,
				
				[Children] = {
					FlyButton(scope, {
						OnClick = function()
							if FlyController then
								FlyController:Toggle()
							end
						end
					})
				}
			})
		}
	})
	
	gui.Destroying:Connect(function() scope:doCleanup() end)
	return gui
end