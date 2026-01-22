local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local InventoryService = Knit.CreateService {
	Name = "InventoryService",
	Client = { InventoryUpdated = Knit.CreateSignal() }
}

function InventoryService:KnitInit()
	self.DataService = Knit.GetService("DataService")
	self.CosmeticSystem = Knit.GetService("CosmeticSystem")
end

function InventoryService:OnDataLoaded(player, data)
	-- [FIX] Chỉ gửi Cosmetics và EquippedItem
	self.Client.InventoryUpdated:Fire(player, data.Cosmetics, data.EquippedItem)

	if data.EquippedItem and self.CosmeticSystem then 
		self.CosmeticSystem:UpdateVisual(player, data.EquippedItem) 
	end
end

function InventoryService:AddItem(player, type, itemId)
	local profile = self.DataService:GetProfile(player)
	if not profile then return end
	local data = profile.Data

	if type == "Cosmetic" then 
		data.Cosmetics[itemId] = true
		-- [FIX] Chỉ update Cosmetics
		self.Client.InventoryUpdated:Fire(player, data.Cosmetics, data.EquippedItem)
	end
end

function InventoryService:Equip(player, itemId)
	local profile = self.DataService:GetProfile(player)
	if not profile or not profile.Data then return end
	local data = profile.Data

	if itemId == nil then
		data.EquippedItem = nil
		self.Client.InventoryUpdated:Fire(player, data.Cosmetics, nil)
		if self.CosmeticSystem then self.CosmeticSystem:UpdateVisual(player, nil) end
		return
	end

	if data.Cosmetics and data.Cosmetics[itemId] then
		data.EquippedItem = itemId
		self.Client.InventoryUpdated:Fire(player, data.Cosmetics, itemId)

		if self.CosmeticSystem then 
			self.CosmeticSystem:UpdateVisual(player, itemId) 
		end
	end
end

function InventoryService.Client:GetData(player)
	local profile = self.Server.DataService:GetProfile(player)
	if profile then return profile.Data.Cosmetics, profile.Data.EquippedItem end
end

function InventoryService.Client:Equip(player, itemId)
	return self.Server:Equip(player, itemId)
end

return InventoryService