--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local OnEvent = Fusion.OnEvent

local COLORS = {
	CYAN_400 = Color3.fromRGB(34, 211, 238),
	SLATE_900 = Color3.fromRGB(15, 23, 42),
}

return function(props)
	local scope = Fusion.scoped(Fusion)
	local isHovered = scope:Value(false)

	local scale = scope:Spring(scope:Computed(function(use)
		return use(isHovered) and 1.1 or 1
	end), 20, 0.5)

	local gui = scope:New "ScreenGui" {
		Name = "HUD_MenuButton",
		ResetOnSpawn = false,
		DisplayOrder = 5,

		[Fusion.Children] = {
			scope:New "TextButton" {
				Name = "ToggleMenuBtn",
				Text = "MENU",
				Font = Enum.Font.SciFi,
				TextScaled = true, -- Tự động chỉnh cỡ chữ để vừa nút responsive
				TextColor3 = COLORS.CYAN_400,

				AnchorPoint = Vector2.new(0, 0.5),
				-- [CHANGE] Vị trí và kích thước dùng Scale hoàn toàn
				Position = UDim2.fromScale(0.01, 0.5), 
				Size = UDim2.fromScale(0.1, 0.08),

				BackgroundColor3 = COLORS.SLATE_900,
				BorderSizePixel = 2,
				BorderColor3 = COLORS.CYAN_400,

				[OnEvent "MouseEnter"] = function() isHovered:set(true) end,
				[OnEvent "MouseLeave"] = function() isHovered:set(false) end,
				[OnEvent "Activated"] = props.OnClick,

				[Fusion.Children] = {
					-- [CHANGE] Corner Radius dùng Scale (bo tròn 20% chiều cao nút)
					scope:New "UICorner" { CornerRadius = UDim.new(0.2, 0) },
					scope:New "UIScale" { Scale = scale }
				}
			}
		}
	}

	gui.Destroying:Connect(function()
		scope:doCleanup()
	end)

	return gui
end