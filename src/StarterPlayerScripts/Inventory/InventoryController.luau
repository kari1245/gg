local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local View = require(script.Parent.InventoryView)

local InventoryController = Knit.CreateController { Name = "InventoryController" }

function InventoryController:KnitStart()
	self.InvService = Knit.GetService("InventoryService")
	self.SoundController = Knit.GetController("SoundController")

	local scope = Fusion.scoped(Fusion)
	local Cosmetics = scope:Value({})
	local Equipped = scope:Value(nil)
	local IsOpen = scope:Value(false)

	-- Sync Data
	self.InvService.InventoryUpdated:Connect(function(c, e)
		Cosmetics:set(c or {}); Equipped:set(e)
	end)

	self.InvService:GetData():andThen(function(c, e)
		if c then Cosmetics:set(c); Equipped:set(e) end
	end)

	-- Render
	local ui = View.New(scope, {
		Cosmetics = Cosmetics, 
		EquippedItem = Equipped, 
		IsOpen = IsOpen,

		OnToggle = function() 
			if self.SoundController then self.SoundController:Play("UI_Click") end
			IsOpen:set(not Fusion.peek(IsOpen)) 
		end,
		OnClose = function() IsOpen:set(false) end,
		OnEquip = function(itemId)
			if self.SoundController then self.SoundController:Play("UI_Click") end
			local current = Fusion.peek(Equipped)
			local target = if current == itemId then nil else itemId
			self.InvService:Equip(target)
		end
	})
	ui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return InventoryController