local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Modules
local SciFiMenu = require(script.Parent.Parent.UI.SciFiMenu)
local MenuToggleButton = require(script.Parent.Parent.UI.MenuToggleButton)
local FlyTools = require(script.Parent.Parent.UI.FlyTools)

local UIController = {}
UIController.Name = "UIController"

-- State
local _isMenuOpen = false
local _menuInstance = nil

function UIController:Start()
	print("[UIController] Starting...")
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- 1. Create Menu (Hidden by default)
	_menuInstance = SciFiMenu.New()
	_menuInstance.Enabled = false
	_menuInstance.Parent = playerGui

	-- 2. Create Toggle Button
	local toggleBtn = MenuToggleButton.New(function()
		self:ToggleMenu()
	end)
	toggleBtn.Parent = playerGui

	-- 3. Create Fly Tools
	local flyTools = FlyTools.New(function()
		-- We need to access FlyController lazily or via event
		-- For simplicity, we assume FlyController is globally require-able or we fire a bindable
		local controllers = script.Parent
		local FlyController = require(controllers.FlyController)
		FlyController:Toggle()
	end)
	flyTools.Parent = playerGui

	-- Input Listener
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.M then
			self:ToggleMenu()
		end
	end)
	
	print("[UIController] UI Mounted & Ready.")
end

function UIController:ToggleMenu()
	_isMenuOpen = not _isMenuOpen
	if _menuInstance then
		_menuInstance.Enabled = _isMenuOpen
	end
end

return UIController