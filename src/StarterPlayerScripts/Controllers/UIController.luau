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
-- Đảm bảo folder UI nằm đúng vị trí trong StarterPlayerScripts
local SciFiMenu = require(script.Parent.Parent.UI.SciFiMenu)
local MenuToggleButton = require(script.Parent.Parent.UI.MenuToggleButton)

local UIController = Knit.CreateController { Name = "UIController" }

function UIController:KnitStart()
	print("[UIController] Starting...")
	
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Lấy Controller xây dựng để giao tiếp
	local ShipBuildController = Knit.GetController("ShipBuildController")

	-- 1. Tạo Scope quản lý bộ nhớ cho Controller này
	local scope = scoped(Fusion)
	
	-- 2. State: Trạng thái Menu (Mở/Đóng)
	local isMenuOpen = scope:Value(false)
	
	-- 3. Hàm Toggle Menu (Dùng peek để đọc giá trị mà không tạo dependency)
	local function toggleMenu()
		local currentStatus = peek(isMenuOpen)
		isMenuOpen:set(not currentStatus)
	end

	-- 4. Mount Main Menu
	local menuInstance = SciFiMenu({
		Visible = isMenuOpen, -- Truyền State vào để tự động ẩn/hiện
		
		-- Callback: Khi người chơi chọn một block trong tab BUILD
		OnBlockSelected = function(blockName)
			print("[UI] Selected Block:", blockName)
			if ShipBuildController then
        		if blockName then
            		ShipBuildController:SelectBlock(blockName)
        		else
            		ShipBuildController:CancelBuild() -- Gọi hàm hủy khi blockName là nil
        		end
    		end
			-- Tùy chọn: Tự động đóng menu khi chọn xong để xây cho dễ
			-- isMenuOpen:set(false) 
		end
	})
	menuInstance.Parent = playerGui

	-- 5. Mount Nút HUD (Nút Mở Menu)
	local buttonInstance = MenuToggleButton({
		OnClick = toggleMenu
	})
	buttonInstance.Parent = playerGui
	
	-- 6. Phím tắt (Nhấn M để bật/tắt)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.M then
			toggleMenu()
		end
	end)
	
	print("[UIController] UI Mounted & Ready.")
end

return UIController