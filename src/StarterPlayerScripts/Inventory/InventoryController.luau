local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local View = require(script.Parent.InventoryView)

local InventoryController = Knit.CreateController { Name = "InventoryController" }

function InventoryController:KnitStart()
	self.InvService = Knit.GetService("InventoryService")
	self.SoundController = Knit.GetController("SoundController")
	self.UIManager = Knit.GetController("UIManagerController")
	
	local scope = Fusion.scoped(Fusion)
	local NftList = scope:Value({}) -- Danh sách NFT
	local IsOpen = scope:Value(false)
	
	-- Register với UIManager
	if self.UIManager then
		self.UIManager:RegisterUI("Inventory", IsOpen)
	end
	
	-- Load initial data first
	self.InvService:GetData():andThen(function(data)
		if data then 
			NftList:set(data)
			print("📦 Loaded", #data, "NFTs from inventory")
		end
	end)
	
	-- Then subscribe to updates
	self.InvService.InventoryUpdated:Connect(function(data)
		NftList:set(data or {})
		print("📦 Inventory updated:", #(data or {}), "NFTs")
	end)
	
	-- Render
	local ui = View.New(scope, {
		NftList = NftList,
		IsOpen = IsOpen,
		
		OnToggle = function() 
			if self.SoundController then self.SoundController:Play("UI_Click") end
			IsOpen:set(not Fusion.peek(IsOpen)) 
		end,
		OnClose = function() IsOpen:set(false) end
	})
	ui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return InventoryController