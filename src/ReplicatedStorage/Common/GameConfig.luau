local GameConfig = {}

-- [[ 1. KINH TẾ ]]
GameConfig.StartingWallet = 5000 -- Tăng tiền khởi điểm để test mua NFT
GameConfig.StartingVault = 0

-- [[ 2. SHOP SETTINGS ]]
GameConfig.ShopSettings = {
	DailySlots = 6, -- Số lượng NFT bán mỗi ngày
	BasePrice = 100 -- Giá gốc để nhân với hệ số độ hiếm
}

-- [[ 3. NFT RARITIES (Tỷ lệ xuất hiện & Giá trị) ]]
GameConfig.NftRarities = {
	-- Weight: Trọng số (Càng cao càng dễ ra)
	-- Mult: Hệ số nhân giá tiền
	Common    = { Weight = 600,  Mult = 1,    Color = Color3.fromRGB(150, 150, 150), Name = "COMMON" },
	Uncommon  = { Weight = 300,  Mult = 2,    Color = Color3.fromRGB(0, 255, 100),   Name = "UNCOMMON" },
	Rare      = { Weight = 150,  Mult = 5,    Color = Color3.fromRGB(0, 150, 255),   Name = "RARE" },
	Epic      = { Weight = 50,   Mult = 20,   Color = Color3.fromRGB(170, 0, 255),   Name = "EPIC" },
	Legendary = { Weight = 10,   Mult = 100,  Color = Color3.fromRGB(255, 200, 0),   Name = "LEGENDARY" },
	Glitch    = { Weight = 1,    Mult = 1000, Color = Color3.fromRGB(255, 0, 0),     Name = "GLITCH // ERROR" },
}

-- [[ 4. ACHIEVEMENTS ]]
GameConfig.Achievements = {
	{ ID = "RICH_1", Type = "Wallet", Val = 1000, Title = "CRYPTO_TRADER", Desc = "Hold $1,000" },
	{ ID = "WIN_1", Type = "Wins", Val = 1, Title = "LUCKY_HASH", Desc = "Win 1 Match" },
}

-- [[ 5. JOB SYSTEM ]]
GameConfig.JobSystem = { 
	Reward = 50, 
	Words = { "HASHING", "BLOCKCHAIN", "DECRYPT", "MINING", "LEDGER", "TOKEN", "SMART_CONTRACT" }
}

-- [[ 6. BLACKJACK ]]
GameConfig.Blackjack = { MinBet = 50, MaxBet = 50000 }

GameConfig.Colors = { Green = Color3.fromRGB(0, 255, 100), Gold = Color3.fromRGB(255, 200, 0) }

return GameConfig