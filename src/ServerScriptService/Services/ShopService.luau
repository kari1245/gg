local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local ShopService = Knit.CreateService {
	Name = "ShopService",
	Client = {
		ShopUpdated = Knit.CreateSignal(),
		BuyItem = Knit.CreateSignal()
	}
}

local PlayerShops = {}

function ShopService:KnitInit()
	self.DataService = Knit.GetService("DataService")
	self.EcoService = Knit.GetService("EconomyService")
	self.InvService = Knit.GetService("InventoryService")
	self.NftService = Knit.GetService("NftService")
end

function ShopService:GenerateDailyShop(player)
	local items = {}
	for i = 1, GameConfig.ShopSettings.DailySlots do
		table.insert(items, self.NftService:GenerateNft())
	end
	PlayerShops[player] = items
	self.Client.ShopUpdated:Fire(player, items)
	print("🛒 Shop generated for", player.Name)
end

function ShopService.Client:BuyNft(player, hash)
	local server = self.Server
	print("🛒 Buy Request:", player.Name, hash) -- Debug log
	
	local shopItems = PlayerShops[player]
	if not shopItems then 
		server:GenerateDailyShop(player)
		shopItems = PlayerShops[player]
	end
	
	local selectedNft = nil
	for _, item in ipairs(shopItems) do
		if item.Hash == hash then selectedNft = item; break end
	end
	
	if not selectedNft then 
		warn("❌ Item not found in shop")
		return false, "Item invalid" 
	end
	
	if selectedNft.Sold then 
		warn("❌ Item already sold")
		return false, "Sold out" 
	end
	
	-- [FIX] Dùng WaitForProfile để chắc chắn Data đã load
	local profile = server.DataService:WaitForProfile(player)
	if not profile then return false, "Data loading..." end
	
	if profile.Data.Wallet >= selectedNft.Price then
		server.EcoService:ModifyWallet(player, -selectedNft.Price)
		server.InvService:AddNft(player, selectedNft)
		
		selectedNft.Sold = true
		server.Client.ShopUpdated:Fire(player, shopItems)
		
		print("✅ Buy Success!")
		return true, "Success"
	else
		warn("❌ Not enough money")
		return false, "Not enough money"
	end
end

function ShopService.Client:GetShopData(player)
	if not PlayerShops[player] then
		self.Server:GenerateDailyShop(player)
	end
	return PlayerShops[player]
end

return ShopService