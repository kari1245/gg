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

-- Hàm lấy số ngày hiện tại (UTC) từ epoch
local function GetCurrentDay()
	return math.floor(os.time() / 86400) -- 86400 giây = 1 ngày
end

function ShopService:GenerateDailyShop(player)
	local profile = self.DataService:WaitForProfile(player)
	if not profile then return end
	
	local currentDay = GetCurrentDay()
	local shopData = profile.Data.NftShopData
	
	-- Kiểm tra xem đã qua ngày mới chưa
	if shopData.LastRefreshDay == currentDay and #shopData.Items > 0 then
		-- Chưa qua ngày mới, dùng lại shop cũ
		PlayerShops[player] = shopData.Items
		self.Client.ShopUpdated:Fire(player, shopData.Items)
		print("🛒 Shop loaded from save for", player.Name)
		return
	end
	
	-- Qua ngày mới rồi, tạo shop mới
	local items = {}
	for i = 1, GameConfig.ShopSettings.DailySlots do
		table.insert(items, self.NftService:GenerateNft())
	end
	
	-- Lưu vào data
	shopData.Items = items
	shopData.LastRefreshDay = currentDay
	
	PlayerShops[player] = items
	self.Client.ShopUpdated:Fire(player, items)
	print("🛒 New shop generated for", player.Name, "(Day:", currentDay, ")")
end

function ShopService.Client:BuyNft(player, hash)
	local server = self.Server
	print("🛒 Buy Request:", player.Name, hash) -- Debug log
	
	-- [FIX] Dùng WaitForProfile để chắc chắn Data đã load
	local profile = server.DataService:WaitForProfile(player)
	if not profile then return false, "Data loading..." end
	
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
	
	if profile.Data.Wallet >= selectedNft.Price then
		server.EcoService:ModifyWallet(player, -selectedNft.Price)
		server.InvService:AddNft(player, selectedNft)
		
		selectedNft.Sold = true
		
		-- Cập nhật cả trong saved data
		profile.Data.NftShopData.Items = shopItems
		
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