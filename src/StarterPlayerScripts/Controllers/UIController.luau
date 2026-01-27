--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

-- [FUSION UTILS]
local peek = Fusion.peek
local scoped = Fusion.scoped

-- [IMPORT UI COMPONENTS]
-- Lưu ý: Folder "UI" phải nằm ngang hàng với folder "Controllers" trong StarterPlayerScripts
local SciFiMenu = require(script.Parent.Parent.UI.SciFiMenu)
local MenuToggleButton = require(script.Parent.Parent.UI.MenuToggleButton)

local UIController = Knit.CreateController { Name = "UIController" }

function UIController:KnitStart()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- 1. Tạo Scope để quản lý trạng thái của Controller này
	local scope = scoped(Fusion)

	-- 2. Tạo State: Menu đang mở hay đóng?
	local isMenuOpen = scope:Value(false)

	-- 3. Hàm xử lý logic Toggle (Bật/Tắt)
	local function toggleMenu()
		-- Dùng peek() để lấy giá trị hiện tại mà không tạo dependency graph (vì đây là event handler)
		local currentStatus = peek(isMenuOpen)
		isMenuOpen:set(not currentStatus)
	end

	-- 4. Mount (Gắn) Main Menu vào PlayerGui
	-- Truyền State 'isMenuOpen' vào thuộc tính Visible
	local menuInstance = SciFiMenu({
		Visible = isMenuOpen
	})
	menuInstance.Parent = playerGui

	-- 5. Mount (Gắn) Nút Bấm HUD vào PlayerGui
	-- Truyền hàm 'toggleMenu' xuống dưới dạng Callback (OnClick)
	local buttonInstance = MenuToggleButton({
		OnClick = toggleMenu
	})
	buttonInstance.Parent = playerGui

	-- 6. Xử lý phím tắt (Phím M)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.M then
			toggleMenu()
		end
	end)

	print("[UIController] UI Mounted & Ready.")
end

return UIController