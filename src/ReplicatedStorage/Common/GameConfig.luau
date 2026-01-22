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
}

-- [[ 5. MINING SYSTEM ]]
GameConfig.MiningSystem = {
	MaxStamina = 100, -- Stamina tối đa
	StaminaCost = 10, -- Stamina mỗi lần đào
	StaminaRegenRate = 5, -- Stamina hồi mỗi giây
	MineCooldown = 1.5, -- Cooldown giữa các lần đào (giây)
	Rewards = { -- Random reward mỗi lần đào
		{ Amount = 20, Weight = 500 },  -- 20$ - Common
		{ Amount = 50, Weight = 300 },  -- 50$ - Uncommon  
		{ Amount = 100, Weight = 150 }, -- 100$ - Rare
		{ Amount = 250, Weight = 40 },  -- 250$ - Epic
		{ Amount = 500, Weight = 10 },  -- 500$ - Legendary
	}
}

-- [[ 6. BLACKJACK ]]
GameConfig.Blackjack = { 
	MinBet = 50, 
	MaxBet = 50000,
	MaxPlayers = 3, -- Tối đa 3 người chơi + 1 AI dealer
	LobbyWaitTime = 5, -- Đợi 5s trong lobby trước khi bắt đầu
	GameEndWaitTime = 5 -- Đợi 5s sau khi kết thúc game
}

GameConfig.Colors = { Green = Color3.fromRGB(0, 255, 100), Gold = Color3.fromRGB(255, 200, 0) }

-- [[ 7. CYBER THEME ]]
GameConfig.CyberTheme = {
	-- Primary Colors
	NeonCyan = Color3.fromRGB(0, 255, 255),
	NeonMagenta = Color3.fromRGB(255, 0, 255),
	NeonGreen = Color3.fromRGB(0, 255, 100),
	NeonPurple = Color3.fromRGB(170, 0, 255),
	NeonPink = Color3.fromRGB(255, 20, 147),
	NeonOrange = Color3.fromRGB(255, 100, 0),
	
	-- Backgrounds
	DarkBg = Color3.fromRGB(5, 10, 15),
	MidBg = Color3.fromRGB(15, 20, 30),
	LightBg = Color3.fromRGB(25, 35, 50),
	
	-- Effects
	GlitchRed = Color3.fromRGB(255, 0, 100),
	GlitchBlue = Color3.fromRGB(0, 150, 255),
	GridColor = Color3.fromRGB(0, 255, 255),
	ScanlineColor = Color3.fromRGB(255, 255, 255),
}

return GameConfig