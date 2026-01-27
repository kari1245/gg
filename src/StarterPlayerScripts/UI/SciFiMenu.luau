local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local SciFiMenu = {}

local COLORS = {
	SLATE_900 = Color3.fromRGB(15, 23, 42),
	SLATE_700 = Color3.fromRGB(51, 65, 85),
	CYAN_400 = Color3.fromRGB(34, 211, 238),
	WHITE = Color3.fromRGB(255, 255, 255),
	TEXT_GRAY = Color3.fromRGB(148, 163, 184)
}

-- Private Helper: Tạo Tab
local function CreateTab(labelName, parent, onClick)
	local btn = Instance.new("TextButton")
	btn.Name = labelName
	btn.Size = UDim2.fromScale(1, 0.12)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Parent = parent

	local text = Instance.new("TextLabel")
	text.Text = labelName
	text.Font = Enum.Font.Code
	text.TextSize = 18
	text.TextColor3 = COLORS.TEXT_GRAY
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Parent = btn

	btn.MouseButton1Click:Connect(onClick)
	
	return {
		SetActive = function(isActive)
			text.TextColor3 = isActive and COLORS.CYAN_400 or COLORS.TEXT_GRAY
			text.Font = isActive and Enum.Font.GothamBold or Enum.Font.Code
		end
	}
end

function SciFiMenu.Mount()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- 1. Setup ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SciFiMenu"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false -- Ẩn mặc định
	screenGui.DisplayOrder = 10
	screenGui.Parent = playerGui

	-- 2. Main Container
	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(0.6, 0.7)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.BackgroundColor3 = COLORS.SLATE_900
	container.BorderSizePixel = 2
	container.BorderColor3 = COLORS.CYAN_400
	container.Parent = screenGui

	-- Sidebar
	local sidebar = Instance.new("Frame")
	sidebar.Size = UDim2.fromScale(0.25, 1)
	sidebar.BackgroundColor3 = COLORS.SLATE_900
	sidebar.BorderColor3 = COLORS.SLATE_700
	sidebar.Parent = container

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 5)
	list.Parent = sidebar
	
	-- Padding top cho sidebar
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 20)
	pad.Parent = sidebar

	-- Content Area
	local content = Instance.new("Frame")
	content.Size = UDim2.fromScale(0.75, 1)
	content.Position = UDim2.fromScale(0.25, 0)
	content.BackgroundTransparency = 1
	content.Parent = container
	
	local title = Instance.new("TextLabel")
	title.Text = "SYSTEM READY"
	title.TextColor3 = COLORS.WHITE
	title.Font = Enum.Font.SciFi
	title.TextSize = 30
	title.Size = UDim2.fromScale(1, 0.15)
	title.BackgroundTransparency = 1
	title.Parent = content

	-- Logic Tabs
	local tabs = {}
	local function SetTab(name)
		title.Text = "> " .. name
		for tName, tObj in pairs(tabs) do
			tObj.SetActive(tName == name)
		end
	end

	tabs["DEPLOY"] = CreateTab("DEPLOY", sidebar, function() SetTab("DEPLOY") end)
	tabs["SETTINGS"] = CreateTab("SETTINGS", sidebar, function() SetTab("SETTINGS") end)
	
	SetTab("DEPLOY") -- Default

	-- API Object
	local api = {}
	
	function api.SetVisible(visible)
		screenGui.Enabled = visible
	end
	
	function api.Toggle()
		screenGui.Enabled = not screenGui.Enabled
	end
	
	return api
end

return SciFiMenu