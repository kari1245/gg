local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local NftService = Knit.CreateService { Name = "NftService" }

-- Hàm random độ hiếm dựa trên trọng số (Weight)
function NftService:RollRarity()
	local totalWeight = 0
	for _, data in pairs(GameConfig.NftRarities) do
		totalWeight += data.Weight
	end
	
	local rng = math.random(1, totalWeight)
	local current = 0
	
	for rarity, data in pairs(GameConfig.NftRarities) do
		current += data.Weight
		if rng <= current then
			return rarity, data
		end
	end
	return "Common", GameConfig.NftRarities.Common
end

-- Hàm tạo NFT độc nhất
function NftService:GenerateNft()
	local rarity, data = self:RollRarity()
	
	-- Tạo mã Hash độc nhất (UUID)
	local hash = HttpService:GenerateGUID(false) -- Ví dụ: 3A2B1C...
	-- Rút gọn hash cho đẹp (lấy 8 ký tự đầu + 4 ký tự cuối) hoặc để nguyên
	-- Ở đây ta dùng nguyên UUID để đảm bảo độc nhất tuyệt đối
	
	local price = GameConfig.ShopSettings.BasePrice * data.Mult
	
	return {
		Hash = hash,
		Rarity = rarity,
		Price = price,
		Timestamp = os.time()
	}
end

return NftService