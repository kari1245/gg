local GameConfig = {}

-- [[ 1. KINH TẾ ]]
GameConfig.StartingWallet = 1000000
GameConfig.StartingVault = 0

-- [[ 2. SHOP SETTINGS ]]
GameConfig.ShopSettings = {
	DailySlots = 6,
	Weights = { Common = 1000, Rare = 400, Epic = 100, Legendary = 20, Glitch = 1 }
}

-- [[ 3. ĐỘ HIẾM ]] (Đã xóa Hack)
GameConfig.Rarities = {
	Common    = { Color = Color3.fromRGB(150, 150, 150), PriceMult = 1,    Name = "COMMON" },
	Rare      = { Color = Color3.fromRGB(0, 200, 255),   PriceMult = 5,    Name = "RARE" },
	Epic      = { Color = Color3.fromRGB(170, 0, 255),   PriceMult = 20,   Name = "EPIC" },
	Legendary = { Color = Color3.fromRGB(255, 200, 0),   PriceMult = 100,  Name = "LEGENDARY" },
	Glitch    = { Color = Color3.fromRGB(255, 0, 0),     PriceMult = 500,  Name = "GLITCHED" },
}

-- [[ 4. ITEM DATABASE ]] (Chỉ còn Cosmetics)
GameConfig.Cosmetics = {
	{ ID = "Soda", Name = "Neon Drink", Rarity = "Common", BasePrice = 50, Image = "rbxassetid://13112343210" },
	{ ID = "Pizza", Name = "Cyber Pizza", Rarity = "Common", BasePrice = 50, Image = "rbxassetid://13112343211" },
	{ ID = "Katana", Name = "Cyber Blade", Rarity = "Rare", BasePrice = 100, Image = "rbxassetid://13112347895" },
	{ ID = "Bat", Name = "Neon Bat", Rarity = "Rare", BasePrice = 120, Image = "rbxassetid://13112347896" },
	{ ID = "Laptop", Name = "Data Deck", Rarity = "Epic", BasePrice = 200, Image = "rbxassetid://13112341234" },
	{ ID = "Hammer", Name = "Ban Hammer", Rarity = "Legendary", BasePrice = 500, Image = "rbxassetid://13112345678" },
	{ ID = "USB", Name = "Virus Drive", Rarity = "Glitch", BasePrice = 1000, Image = "rbxassetid://13112349999" },
}

-- [[ ĐÃ XÓA MỤC HACKS ]]

-- [[ 5. ACHIEVEMENTS ]]
GameConfig.Achievements = {
	{ ID = "RICH_1", Type = "Wallet", Val = 500, Title = "SCRIPT_KIDDIE", Desc = "Reach $500" },
	{ ID = "RICH_2", Type = "Wallet", Val = 2000, Title = "CRYPTO_MINER", Desc = "Reach $2,000" },
	{ ID = "WIN_1", Type = "Wins", Val = 1, Title = "NEWBIE", Desc = "Win 1 Match" },
	{ ID = "WIN_5", Type = "Wins", Val = 5, Title = "GAMBLER", Desc = "Win 5 Matches" },
}

-- [[ 6. JOB SYSTEM ]]
GameConfig.JobSystem = { 
	Reward = 50, 
	Words = {
		"SUDO_ROOT", "DECRYPT_SHA", "BYPASS_FW", "INJECT_SQL", "DDOS_ATK",
		"BRUTE_FORCE", "SSH_TUNNEL", "OVERRIDE_SYS", "ACCESS_GRANTED", "NET_SCAN"
	}
}

-- [[ 7. BLACKJACK ]]
GameConfig.Blackjack = {
	MinBet = 50,
	MaxBet = 50000
}

GameConfig.Colors = { Green = Color3.fromRGB(0, 255, 100), Gold = Color3.fromRGB(255, 200, 0) }

function GameConfig.GetItemInfo(itemId)
	for _, item in ipairs(GameConfig.Cosmetics) do 
		if item.ID == itemId then return item, "Cosmetic" end 
	end
	return nil
end

function GameConfig.GetPrice(itemId)
	local item, type = GameConfig.GetItemInfo(itemId)
	if not item then return 999999 end
	local rInfo = GameConfig.Rarities[item.Rarity]
	return item.BasePrice * (rInfo and rInfo.PriceMult or 1)
end

return GameConfig