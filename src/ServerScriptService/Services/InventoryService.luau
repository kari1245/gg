local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local InventoryService = Knit.CreateService {
	Name = "InventoryService",
	Client = { InventoryUpdated = Knit.CreateSignal() }
}

function InventoryService:KnitInit()
	self.DataService = Knit.GetService("DataService")
end

function InventoryService:OnDataLoaded(player, data)
	self.Client.InventoryUpdated:Fire(player, data.NftInventory)
end

function InventoryService:AddNft(player, nftData)
	local profile = self.DataService:GetProfile(player)
	if not profile then return end
	
	-- Lưu object NFT vào mảng
	table.insert(profile.Data.NftInventory, nftData)
	
	self.Client.InventoryUpdated:Fire(player, profile.Data.NftInventory)
	print("🎒 Added NFT to inventory:", nftData.Hash)
end

function InventoryService.Client:GetData(player)
	local profile = self.Server.DataService:WaitForProfile(player) -- Dùng WaitForProfile thay vì GetProfile
	if profile then 
		print("📦 GetData for", player.Name, "returned", #profile.Data.NftInventory, "NFTs")
		return profile.Data.NftInventory 
	end
	print("⚠️ GetData for", player.Name, "- No profile found")
	return {}
end

return InventoryService