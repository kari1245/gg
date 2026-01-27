local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion) :: any

-- Unpack commonly used Fusion symbols
local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

local COLORS = {
	SLATE_900 = Color3.fromRGB(15, 23, 42),
	SLATE_800 = Color3.fromRGB(30, 41, 59),
	SLATE_700 = Color3.fromRGB(51, 65, 85),
	CYAN_400 = Color3.fromRGB(34, 211, 238),
	CYAN_900 = Color3.fromRGB(22, 78, 99),
	WHITE = Color3.fromRGB(255, 255, 255),
	TEXT_GRAY = Color3.fromRGB(148, 163, 184)
}

-- [TYPES]
type MenuTabProps = {
	Label: string,
	IsActive: any, -- Fusion State
	OnClick: () -> ()
}

-- Component: Tab Menu
local function MenuTab(scope: any, props: MenuTabProps)
	local isHovered = scope:Value(false)
	
	local backgroundColor = scope:Computed(function(use)
		if use(props.IsActive) then return COLORS.CYAN_900
		elseif use(isHovered) then return COLORS.SLATE_800
		else return COLORS.SLATE_900 end
	end)
	
	local textColor = scope:Computed(function(use)
		return use(props.IsActive) and COLORS.CYAN_400 or COLORS.TEXT_GRAY
	end)

	-- [FIX] Use Fusion.New(scope, ...) syntax and cast props to any
	return New(scope, "TextButton") ({
		Name = props.Label,
		Size = UDim2.fromScale(1, 0.1),
		BackgroundColor3 = backgroundColor,
		BackgroundTransparency = scope:Computed(function(use) 
			return use(props.IsActive) and 0.7 or (use(isHovered) and 0.5 or 1) 
		end),
		AutoButtonColor = false,
		
		[OnEvent "MouseEnter"] = function() isHovered:set(true) end,
		[OnEvent "MouseLeave"] = function() isHovered:set(false) end,
		[OnEvent "MouseButton1Click"] = props.OnClick,
		
		[Children] = {
			New(scope, "UIListLayout") ({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0.02, 0),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
			} :: any),
			
			New(scope, "UIPadding") ({ PaddingLeft = UDim.new(0.05, 0) } :: any),
			
			New(scope, "Frame") ({
				Size = UDim2.fromScale(0.1, 0.4),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				BackgroundColor3 = textColor,
			} :: any),
			
			New(scope, "TextLabel") ({
				Text = props.Label,
				Font = Enum.Font.Code,
				TextScaled = true,
				TextColor3 = textColor,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.7, 0.5),
				AutomaticSize = Enum.AutomaticSize.None
			} :: any),
			
			New(scope, "Frame") ({
				Size = UDim2.fromScale(0.02, 1),
				BackgroundColor3 = COLORS.CYAN_400,
				Visible = props.IsActive,
				Position = UDim2.fromScale(0, 0)
			} :: any)
		}
	} :: any)
end

local function StuddedBackground(scope: any, props: {ZIndex: number?, LayoutOrder: number?})
	return New(scope, "ImageLabel") ({
		Name = "StuddedBackground",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6073663785", 
		ImageTransparency = 0.9,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(20, 20),
		ZIndex = props.ZIndex or 1,
		LayoutOrder = props.LayoutOrder
	} :: any)
end

-- [MAIN COMPONENT]
return function(props: {Visible: any})
	local scope = Fusion.scoped(Fusion)
	local activeTab = scope:Value("DEPLOY") 
	
	local gui = New(scope, "ScreenGui") ({
		Name = "SciFiMenu",
		ResetOnSpawn = false,
		Enabled = props.Visible,
		DisplayOrder = 10,
		
		[Children] = {
			New(scope, "Frame") ({
				Name = "MainContainer",
				Size = UDim2.fromScale(0.8, 0.8),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = COLORS.SLATE_900,
				BorderSizePixel = 2,
				BorderColor3 = COLORS.SLATE_700,
				
				[Children] = {
					StuddedBackground(scope, {}),
					
					-- Sidebar
					New(scope, "Frame") ({
						Name = "Sidebar",
						Size = UDim2.fromScale(0.25, 1),
						BackgroundColor3 = COLORS.SLATE_900,
						BackgroundTransparency = 0.5,
						BorderColor3 = COLORS.SLATE_700,
						BorderSizePixel = 1,
						
						[Children] = {
							New(scope, "UIListLayout") ({ SortOrder = Enum.SortOrder.LayoutOrder } :: any),
							
							New(scope, "Frame") ({ -- Logo Area
								Size = UDim2.fromScale(1, 0.15),
								BackgroundTransparency = 1,
								[Children] = {
									New(scope, "TextLabel") ({
										Text = "NEOBLOX",
										TextColor3 = COLORS.WHITE,
										Font = Enum.Font.SciFi,
										TextScaled = true,
										Size = UDim2.fromScale(0.8, 0.5),
										Position = UDim2.fromScale(0.1, 0.25),
										BackgroundTransparency = 1
									} :: any)
								}
							} :: any),
							
							-- Tabs
							MenuTab(scope, { 
								Label = "DEPLOY", 
								IsActive = scope:Computed(function(use) return use(activeTab) == "DEPLOY" end),
								OnClick = function() activeTab:set("DEPLOY") end
							}),
							MenuTab(scope, { 
								Label = "LOADOUT", 
								IsActive = scope:Computed(function(use) return use(activeTab) == "LOADOUT" end),
								OnClick = function() activeTab:set("LOADOUT") end
							}),
							MenuTab(scope, { 
								Label = "CHARACTER", 
								IsActive = scope:Computed(function(use) return use(activeTab) == "CHARACTER" end),
								OnClick = function() activeTab:set("CHARACTER") end
							}),
						}
					} :: any),
					
					-- Content Area
					New(scope, "Frame") ({
						Name = "Content",
						Size = UDim2.fromScale(0.75, 1),
						Position = UDim2.fromScale(0.25, 0),
						BackgroundTransparency = 1,
						[Children] = {
							New(scope, "UIPadding") ({
								PaddingTop = UDim.new(0.05, 0), PaddingLeft = UDim.new(0.05, 0),
								PaddingRight = UDim.new(0.05, 0), PaddingBottom = UDim.new(0.05, 0)
							} :: any),
							
							New(scope, "TextLabel") ({
								Text = scope:Computed(function(use) return use(activeTab) end),
								Font = Enum.Font.Code,
								TextScaled = true,
								TextColor3 = COLORS.WHITE,
								TextXAlignment = Enum.TextXAlignment.Left,
								Size = UDim2.fromScale(1, 0.1),
								BackgroundTransparency = 1
							} :: any),
							
							New(scope, "TextLabel") ({
								Text = "Select an option from the sidebar.",
								TextColor3 = COLORS.TEXT_GRAY,
								BackgroundTransparency = 1,
								Size = UDim2.fromScale(1, 0.5),
								Position = UDim2.fromScale(0, 0.2),
								TextScaled = true
							} :: any)
						}
					} :: any)
				}
			} :: any)
		}
	} :: any)
	
	gui.Destroying:Connect(function() scope:doCleanup() end)
	return gui
end