--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local peek = Fusion.peek
local scoped = Fusion.scoped

local SciFiMenu = require(script.Parent.Parent.UI.SciFiMenu)
local MenuToggleButton = require(script.Parent.Parent.UI.MenuToggleButton)

local UIController = Knit.CreateController { Name = "UIController" }

function UIController:KnitStart()
	print("[UIController] Starting...")
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	self.Scope = scoped(Fusion)
	self.IsMenuOpen = self.Scope:Value(false)
	
	local function toggleMenu()
		local currentStatus = peek(self.IsMenuOpen)
		self.IsMenuOpen:set(not currentStatus)
	end

	-- Mount Main Menu (Không còn callback xây dựng)
	local menuInstance = SciFiMenu({
		Visible = self.IsMenuOpen
	})
	menuInstance.Parent = playerGui

	-- Mount Nút HUD
	local buttonInstance = MenuToggleButton({
		OnClick = toggleMenu
	})
	buttonInstance.Parent = playerGui
	
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.M then
			toggleMenu()
		end
	end)
	
	print("[UIController] UI Mounted & Ready.")
end

function UIController:CloseMenu()
	if self.IsMenuOpen then
		self.IsMenuOpen:set(false)
	end
end

return UIController