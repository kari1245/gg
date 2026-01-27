local SciFiMenu = {}

local COLORS = {
	SLATE_900 = Color3.fromRGB(15, 23, 42),
	SLATE_800 = Color3.fromRGB(30, 41, 59),
	SLATE_700 = Color3.fromRGB(51, 65, 85),
	CYAN_400 = Color3.fromRGB(34, 211, 238),
	CYAN_900 = Color3.fromRGB(22, 78, 99),
	WHITE = Color3.fromRGB(255, 255, 255),
	TEXT_GRAY = Color3.fromRGB(148, 163, 184)
}

local function CreateTab(labelName, parent, onClick)
	local btn = Instance.new("TextButton")
	btn.Name = labelName
	btn.Size = UDim2.fromScale(1, 0.1)
	btn.BackgroundColor3 = COLORS.SLATE_900
	btn.BackgroundTransparency = 1
	btn.AutoButtonColor = false
	btn.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0.02, 0)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = btn
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.05, 0)
	padding.Parent = btn

	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.fromScale(0.1, 0.4)
	indicator.SizeConstraint = Enum.SizeConstraint.RelativeYY
	indicator.BackgroundColor3 = COLORS.TEXT_GRAY
	indicator.Parent = btn

	local text = Instance.new("TextLabel")
	text.Text = labelName
	text.Font = Enum.Font.Code
	text.TextScaled = true
	text.TextColor3 = COLORS.TEXT_GRAY
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(0.7, 0.5)
	text.Parent = btn
	
	local activeBar = Instance.new("Frame")
	activeBar.Size = UDim2.fromScale(0.02, 1)
	activeBar.BackgroundColor3 = COLORS.CYAN_400
	activeBar.Visible = false
	activeBar.Parent = btn

	-- Logic
	btn.MouseButton1Click:Connect(onClick)
	
	-- Return object to manipulate later
	return {
		Instance = btn,
		SetActive = function(isActive)
			activeBar.Visible = isActive
			text.TextColor3 = isActive and COLORS.CYAN_400 or COLORS.TEXT_GRAY
			indicator.BackgroundColor3 = isActive and COLORS.CYAN_400 or COLORS.TEXT_GRAY
			btn.BackgroundTransparency = isActive and 0.7 or 1
		end
	}
end

function SciFiMenu.New()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SciFiMenu"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10

	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "MainContainer"
	mainContainer.Size = UDim2.fromScale(0.8, 0.8)
	mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	mainContainer.Position = UDim2.fromScale(0.5, 0.5)
	mainContainer.BackgroundColor3 = COLORS.SLATE_900
	mainContainer.BorderSizePixel = 2
	mainContainer.BorderColor3 = COLORS.SLATE_700
	mainContainer.Parent = screenGui

	-- Sidebar
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.fromScale(0.25, 1)
	sidebar.BackgroundColor3 = COLORS.SLATE_900
	sidebar.BackgroundTransparency = 0.5
	sidebar.BorderColor3 = COLORS.SLATE_700
	sidebar.BorderSizePixel = 1
	sidebar.Parent = mainContainer

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = sidebar

	-- Logo
	local logoArea = Instance.new("Frame")
	logoArea.Size = UDim2.fromScale(1, 0.15)
	logoArea.BackgroundTransparency = 1
	logoArea.Parent = sidebar
	
	local logoText = Instance.new("TextLabel")
	logoText.Text = "NEOBLOX"
	logoText.TextColor3 = COLORS.WHITE
	logoText.Font = Enum.Font.SciFi
	logoText.TextScaled = true
	logoText.Size = UDim2.fromScale(0.8, 0.5)
	logoText.Position = UDim2.fromScale(0.1, 0.25)
	logoText.BackgroundTransparency = 1
	logoText.Parent = logoArea

	-- Content Area
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.fromScale(0.75, 1)
	content.Position = UDim2.fromScale(0.25, 0)
	content.BackgroundTransparency = 1
	content.Parent = mainContainer
	
	local header = Instance.new("TextLabel")
	header.Text = "DEPLOY"
	header.Font = Enum.Font.Code
	header.TextScaled = true
	header.TextColor3 = COLORS.WHITE
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Size = UDim2.fromScale(1, 0.1)
	header.BackgroundTransparency = 1
	header.Position = UDim2.fromScale(0.05, 0.05)
	header.Parent = content

	-- Tabs Logic
	local tabs = {}
	local function SetTab(name)
		header.Text = name
		for tName, tabObj in pairs(tabs) do
			tabObj.SetActive(tName == name)
		end
	end

	tabs["DEPLOY"] = CreateTab("DEPLOY", sidebar, function() SetTab("DEPLOY") end)
	tabs["LOADOUT"] = CreateTab("LOADOUT", sidebar, function() SetTab("LOADOUT") end)
	tabs["CHARACTER"] = CreateTab("CHARACTER", sidebar, function() SetTab("CHARACTER") end)

	SetTab("DEPLOY") -- Default

	return screenGui
end

return SciFiMenu