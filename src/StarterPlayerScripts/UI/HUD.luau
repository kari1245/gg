local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Lazy load FlyController để tránh vòng lặp require
local Controllers = script.Parent.Parent.Controllers
local FlyController -- Sẽ require khi cần

local HUD = {}
local COLORS = {
	SLATE_900 = Color3.fromRGB(15, 23, 42),
	CYAN_400 = Color3.fromRGB(34, 211, 238),
	CYAN_900 = Color3.fromRGB(22, 78, 99),
}

-- Hàm tạo nút Menu (Private helper)
local function CreateMenuButton(parent, onClick)
	local btn = Instance.new("TextButton")
	btn.Name = "ToggleMenuBtn"
	btn.Text = "MENU"
	btn.Font = Enum.Font.SciFi
	btn.TextScaled = true
	btn.TextColor3 = COLORS.CYAN_400
	btn.AnchorPoint = Vector2.new(0, 0.5)
	btn.Position = UDim2.fromScale(0.01, 0.5)
	btn.Size = UDim2.fromScale(0.08, 0.06) -- Nhỏ gọn hơn
	btn.BackgroundColor3 = COLORS.SLATE_900
	btn.BorderSizePixel = 2
	btn.BorderColor3 = COLORS.CYAN_400
	btn.Parent = parent

	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0.2, 0)
	
	-- Animation đơn giản
	btn.MouseEnter:Connect(function() btn.BackgroundColor3 = COLORS.CYAN_900 end)
	btn.MouseLeave:Connect(function() btn.BackgroundColor3 = COLORS.SLATE_900 end)
	btn.Activated:Connect(onClick)
	
	return btn
end

-- Hàm tạo Fly Tool (Private helper)
local function CreateFlyIndicator(parent)
	local container = Instance.new("Frame")
	container.Name = "FlyTool"
	container.Position = UDim2.fromScale(0.01, 0.85) -- Chuyển xuống góc dưới trái
	container.Size = UDim2.fromOffset(180, 40)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(1, 1)
	btn.BackgroundColor3 = COLORS.SLATE_900
	btn.BackgroundTransparency = 0.3
	btn.BorderSizePixel = 1
	btn.BorderColor3 = COLORS.CYAN_400
	btn.Text = "✈️ FLY MODE [F]"
	btn.TextColor3 = COLORS.CYAN_400
	btn.Font = Enum.Font.SciFi
	btn.TextSize = 18
	btn.Parent = container
	
	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0, 4)

	btn.Activated:Connect(function()
		if not FlyController then FlyController = require(Controllers.FlyController) end
		FlyController:Toggle()
	end)
end

function HUD.Mount(menuApi)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainHUD"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 5
	screenGui.Parent = playerGui
	
	-- 1. Create Menu Button
	CreateMenuButton(screenGui, function()
		if menuApi then menuApi.Toggle() end
	end)

	-- 2. Create Fly Indicator
	CreateFlyIndicator(screenGui)

	return screenGui
end

return HUD