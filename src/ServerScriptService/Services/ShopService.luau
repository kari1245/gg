local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local ShopService = Knit.CreateService { Name = "ShopService", Client = {} }

-- Generate Shop mỗi ngày
local DailyShop = {}
local function GenerateShop()
	DailyShop = {}
	local weightedList = {}
	-- Tạo danh sách theo trọng số (giữ nguyên logic cũ của bạn)
	-- ... (Giả sử logic generate shop của bạn ở đây) ...

	-- [VÍ DỤ ĐƠN GIẢN] Nếu bạn chưa có logic random, dùng tạm cái này:
	local allItems = {}
	for _, v in ipairs(GameConfig.Cosmetics) do table.insert(allItems, v.ID) end
	for i = 1, GameConfig.ShopSettings.DailySlots do
		table.insert(DailyShop, allItems[math.random(1, #allItems)])
	end
	print("🛒 Daily Shop Generated:", table.concat(DailyShop, ", "))
end

function ShopService:KnitInit()
	self.DataService = Knit.GetService("DataService")
	self.EconomyService = Knit.GetService("EconomyService") -- Gọi qua Economy để trừ tiền
	self.InventoryService = Knit.GetService("InventoryService") -- Gọi Inventory để thêm đồ
	GenerateShop()
end

function ShopService:BuyItem(player, itemId)
	-- 1. Validate Item trong Daily Shop
	local valid = false
	for _, id in ipairs(DailyShop) do if id == itemId then valid = true; break end end

	local itemInfo = GameConfig.GetItemInfo(itemId)
	if not valid or not itemInfo then return false end

	-- 2. Check tiền & Trừ tiền
	local profile = self.DataService:GetProfile(player)
	if not profile then return false end

	local price = GameConfig.GetPrice(itemId)
	if profile.Data.Wallet >= price then
		self.EconomyService:ModifyWallet(player, -price)
		self.InventoryService:AddItem(player, "Cosmetic", itemId) -- Luôn là Cosmetic
		return true
	end

	return false
end

function ShopService.Client:GetDailyShop(player) return DailyShop end
function ShopService.Client:BuyItem(player, itemId) return self.Server:BuyItem(player, itemId) end

return ShopService