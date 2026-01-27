--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek 

-- [CONFIG] Thêm công cụ TRASH vào cuối danh sách
local AVAILABLE_BLOCKS = {
	{Name = "WoodBlock", Color = Color3.fromRGB(139, 69, 19)},
	{Name = "MetalBlock", Color = Color3.fromRGB(99, 102, 106)},
	{Name = "Engine", Color = Color3.fromRGB(255, 0, 0)},
	{Name = "PilotSeat", Color = Color3.fromRGB(0, 255, 255)},
	{Name = "TRASH", Color = Color3.fromRGB(255, 50, 50)}, -- Nút xóa
}

local COLORS = {
	SLATE_900 = Color3.fromRGB(15, 23, 42),
	SLATE_800 = Color3.fromRGB(30, 41, 59),
	SLATE_700 = Color3.fromRGB(51, 65, 85),
	CYAN_400 = Color3.fromRGB(34, 211, 238),
	CYAN_900 = Color3.fromRGB(22, 78, 99),
	WHITE = Color3.fromRGB(255, 255, 255),
	RED_500 = Color3.fromRGB(239, 68, 68), -- Màu đỏ cho nút Stop
	TEXT_GRAY = Color3.fromRGB(148, 163, 184)
}

-- (Giữ nguyên BlockItem và MenuTab helper functions...)
local function BlockItem(scope, props)
    -- Copy lại code BlockItem cũ của bạn vào đây
    local isHovered = scope:Value(false)
	return scope:New "TextButton" {
		Name = props.Data.Name, Size = UDim2.fromScale(0.3, 0.3), SizeConstraint = Enum.SizeConstraint.RelativeXX,
		BackgroundColor3 = scope:Computed(function(use) return use(isHovered) and COLORS.SLATE_700 or COLORS.SLATE_800 end),
		Text = "", [OnEvent "MouseEnter"] = function() isHovered:set(true) end, [OnEvent "MouseLeave"] = function() isHovered:set(false) end,
		[OnEvent "Activated"] = props.OnClick,
		[Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0.1, 0) },
			scope:New "UIStroke" { Color = COLORS.CYAN_400, Thickness = 2, Transparency = scope:Computed(function(use) return use(props.IsSelected) and 0 or 1 end) },
			scope:New "Frame" { Size = UDim2.fromScale(0.6, 0.6), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), BackgroundColor3 = props.Data.Color, [Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0.2, 0) } } },
			scope:New "TextLabel" { Text = props.Data.Name, Size = UDim2.fromScale(1, 0.2), Position = UDim2.fromScale(0, 0.8), BackgroundTransparency = 1, TextColor3 = COLORS.WHITE, TextScaled = true, Font = Enum.Font.Code }
		}
	}
end

local function MenuTab(scope, props)
    -- Copy lại code MenuTab cũ vào đây
    local isHovered = scope:Value(false)
    -- ...
    -- Code này không thay đổi, tôi rút gọn để dễ nhìn
	local backgroundColor = scope:Computed(function(use) if use(props.IsActive) then return COLORS.CYAN_900 elseif use(isHovered) then return COLORS.SLATE_800 else return COLORS.SLATE_900 end end)
	local textColor = scope:Computed(function(use) return use(props.IsActive) and COLORS.CYAN_400 or COLORS.TEXT_GRAY end)
	return scope:New "TextButton" {
		Name = props.Label, Size = UDim2.fromScale(1, 0.1), BackgroundColor3 = backgroundColor,
		BackgroundTransparency = scope:Computed(function(use) return use(props.IsActive) and 0.7 or (use(isHovered) and 0.5 or 1) end),
		[OnEvent "MouseEnter"] = function() isHovered:set(true) end, [OnEvent "MouseLeave"] = function() isHovered:set(false) end,
		[OnEvent "MouseButton1Click"] = props.OnClick,
		[Children] = { scope:New "UIListLayout" { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.02, 0), VerticalAlignment = Enum.VerticalAlignment.Center }, scope:New "UIPadding" { PaddingLeft = UDim.new(0.05, 0) }, scope:New "TextLabel" { Text = props.Label, Font = Enum.Font.Code, TextScaled = true, TextColor3 = textColor, BackgroundTransparency = 1, Size = UDim2.fromScale(0.7, 0.5) } }
	}
end

local function StuddedBackground(scope, props)
	return scope:New "ImageLabel" { Name = "BG", Size = UDim2.fromScale(1, 1), Image = "rbxassetid://6073663785", ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, ZIndex = 0 }
end

return function(props)
	local scope = Fusion.scoped(Fusion)
	local activeTab = scope:Value("BUILD")
	local selectedBlock = scope:Value(nil)

	local function selectBlock(blockName)
		selectedBlock:set(blockName)
		if props.OnBlockSelected then props.OnBlockSelected(blockName) end
	end

	local gui = scope:New "ScreenGui" {
		Name = "SciFiMenu", ResetOnSpawn = false, Enabled = props.Visible, DisplayOrder = 10,
		
		[Children] = {
			scope:New "Frame" {
				Name = "MainContainer", Size = UDim2.fromScale(0.8, 0.8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = COLORS.SLATE_900, BorderSizePixel = 2, BorderColor3 = COLORS.SLATE_700,
				
				[Children] = {
					StuddedBackground(scope, {}),
					
					-- Sidebar
					scope:New "Frame" {
						Name = "Sidebar", Size = UDim2.fromScale(0.25, 1), BackgroundColor3 = COLORS.SLATE_900, BackgroundTransparency = 0.5,
						[Children] = {
							scope:New "UIListLayout" { SortOrder = Enum.SortOrder.LayoutOrder },
							scope:New "Frame" { Size = UDim2.fromScale(1, 0.15), BackgroundTransparency = 1, [Children] = { scope:New "TextLabel" { Text = "SHIPYARD", TextColor3 = COLORS.WHITE, TextScaled = true, Size = UDim2.fromScale(0.8, 0.5), Position = UDim2.fromScale(0.1, 0.25), BackgroundTransparency = 1, Font = Enum.Font.SciFi } } },
							MenuTab(scope, { Label = "BUILD", IsActive = scope:Computed(function(use) return use(activeTab) == "BUILD" end), OnClick = function() activeTab:set("BUILD") end }),
							MenuTab(scope, { Label = "STATS", IsActive = scope:Computed(function(use) return use(activeTab) == "STATS" end), OnClick = function() activeTab:set("STATS") end }),
						}
					},
					
					-- Content Area
					scope:New "Frame" {
						Name = "Content", Size = UDim2.fromScale(0.75, 1), Position = UDim2.fromScale(0.25, 0), BackgroundTransparency = 1,
						[Children] = {
							scope:New "UIPadding" { PaddingTop = UDim.new(0.05, 0), PaddingLeft = UDim.new(0.05, 0), PaddingRight = UDim.new(0.05, 0) },
							
							-- Header Row (Gồm Tiêu đề và Nút Stop)
							scope:New "Frame" {
								Size = UDim2.fromScale(1, 0.1), BackgroundTransparency = 1,
								[Children] = {
									scope:New "TextLabel" {
										Text = scope:Computed(function(use) return "MODE: " .. use(activeTab) end),
										Font = Enum.Font.Code, TextScaled = true, TextColor3 = COLORS.WHITE, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromScale(0.6, 1), BackgroundTransparency = 1
									},
									-- [MỚI] Nút STOP BUILDING
									scope:New "TextButton" {
										Text = "STOP BUILD",
										Size = UDim2.fromScale(0.3, 0.8), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
										BackgroundColor3 = COLORS.RED_500, TextColor3 = COLORS.WHITE, Font = Enum.Font.Code, TextScaled = true,
										Visible = scope:Computed(function(use) return use(selectedBlock) ~= nil end), -- Chỉ hiện khi đang xây
										[OnEvent "Activated"] = function() selectBlock(nil) end, -- Hủy chọn
										[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0.2, 0) } }
									}
								}
							},
							
							-- Build Grid
							scope:New "ScrollingFrame" {
								Name = "BuildGrid", Size = UDim2.fromScale(1, 0.85), Position = UDim2.fromScale(0, 0.15), BackgroundTransparency = 1,
								Visible = scope:Computed(function(use) return use(activeTab) == "BUILD" end),
								CanvasSize = UDim2.fromScale(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
								[Children] = {
									scope:New "UIGridLayout" { CellSize = UDim2.fromOffset(100, 100), CellPadding = UDim2.fromOffset(15, 15) },
									scope:ForValues(AVAILABLE_BLOCKS, function(use, scope, blockData)
										return BlockItem(scope, {
											Data = blockData,
											IsSelected = scope:Computed(function(use) return use(selectedBlock) == blockData.Name end),
											OnClick = function() selectBlock(blockData.Name) end
										})
									end)
								}
							}
						}
					}
				}
			}
		}
	}
	gui.Destroying:Connect(function() scope:doCleanup() end)
	return gui
end