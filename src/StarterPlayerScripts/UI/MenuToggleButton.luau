local TweenService = game:GetService("TweenService")

local MenuToggleButton = {}

local COLORS = {
	CYAN_400 = Color3.fromRGB(34, 211, 238),
	SLATE_900 = Color3.fromRGB(15, 23, 42),
}

function MenuToggleButton.New(onClick)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD_MenuButton"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 5

	local btn = Instance.new("TextButton")
	btn.Name = "ToggleMenuBtn"
	btn.Text = "MENU"
	btn.Font = Enum.Font.SciFi
	btn.TextScaled = true
	btn.TextColor3 = COLORS.CYAN_400
	btn.AnchorPoint = Vector2.new(0, 0.5)
	btn.Position = UDim2.fromScale(0.01, 0.5)
	btn.Size = UDim2.fromScale(0.1, 0.08)
	btn.BackgroundColor3 = COLORS.SLATE_900
	btn.BorderSizePixel = 2
	btn.BorderColor3 = COLORS.CYAN_400
	btn.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = btn

	local scale = Instance.new("UIScale")
	scale.Parent = btn

	-- Animations
	btn.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.2), {Scale = 1.1}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.2), {Scale = 1}):Play()
	end)

	btn.Activated:Connect(onClick)

	return screenGui
end

return MenuToggleButton