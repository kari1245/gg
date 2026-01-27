local FlyTools = {}

local COLORS = {
	SLATE_900 = Color3.fromRGB(15, 23, 42),
	CYAN_400 = Color3.fromRGB(34, 211, 238),
	CYAN_900 = Color3.fromRGB(22, 78, 99),
}

function FlyTools.New(onClick)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FlyToolsHUD"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 20

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Position = UDim2.fromScale(0.02, 0.75)
	container.Size = UDim2.fromOffset(200, 50)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	local btn = Instance.new("TextButton")
	btn.Name = "FlyToggleButton"
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundColor3 = COLORS.SLATE_900
	btn.BackgroundTransparency = 0.2
	btn.BorderSizePixel = 2
	btn.BorderColor3 = COLORS.CYAN_400
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	local label = Instance.new("TextLabel")
	label.Text = "✈️ FLY MODE (F)"
	label.Font = Enum.Font.SciFi
	label.TextColor3 = COLORS.CYAN_400
	label.TextSize = 22
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.TextStrokeTransparency = 0.8
	label.Parent = btn

	-- Hover Logic
	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = COLORS.CYAN_900
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = COLORS.SLATE_900
	end)
	
	btn.MouseButton1Click:Connect(onClick)

	return screenGui
end

return FlyTools