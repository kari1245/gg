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

-- [[ 4. ACHIEVEMENTS - Based on Wallet balance ]]
GameConfig.Achievements = {
	{ ID = "RICH_1", Type = "Wallet", Val = 100, Title = "FIRST_STEPS", Desc = "Hold $100 in wallet", Color = Color3.fromRGB(150, 150, 150), Icon = "◇" },
	{ ID = "RICH_2", Type = "Wallet", Val = 500, Title = "HUSTLER", Desc = "Hold $500 in wallet", Color = Color3.fromRGB(100, 255, 100), Icon = "◈" },
	{ ID = "RICH_3", Type = "Wallet", Val = 1000, Title = "ENTREPRENEUR", Desc = "Hold $1,000 in wallet", Color = Color3.fromRGB(0, 255, 150), Icon = "◆" },
	{ ID = "RICH_4", Type = "Wallet", Val = 5000, Title = "INVESTOR", Desc = "Hold $5,000 in wallet", Color = Color3.fromRGB(0, 200, 255), Icon = "▣" },
	{ ID = "RICH_5", Type = "Wallet", Val = 10000, Title = "WHALE", Desc = "Hold $10,000 in wallet", Color = Color3.fromRGB(50, 255, 200), Icon = "◉" },
	{ ID = "RICH_6", Type = "Wallet", Val = 50000, Title = "TYCOON", Desc = "Hold $50,000 in wallet", Color = Color3.fromRGB(170, 0, 255), Icon = "⬢" },
	{ ID = "RICH_7", Type = "Wallet", Val = 100000, Title = "MILLIONAIRE", Desc = "Hold $100,000 in wallet", Color = Color3.fromRGB(255, 215, 0), Icon = "⬣" },
	{ ID = "RICH_8", Type = "Wallet", Val = 500000, Title = "LEGEND", Desc = "Hold $500,000 in wallet", Color = Color3.fromRGB(255, 100, 0), Icon = "⯁" },
	{ ID = "RICH_9", Type = "Wallet", Val = 1000000, Title = "DIAMOND_HANDS", Desc = "Hold $1,000,000 in wallet", Color = Color3.fromRGB(185, 242, 255), Icon = "◬" },
}

-- [[ 5. NFT EARNING SYSTEM ]]
GameConfig.NftEarning = {
	-- Passive income by equipping NFT (works offline)
	Earning = {
		Common    = { HourlyRate = 10 },    -- $10/hour
		Uncommon  = { HourlyRate = 25 },    -- $25/hour
		Rare      = { HourlyRate = 60 },    -- $60/hour
		Epic      = { HourlyRate = 150 },   -- $150/hour
		Legendary = { HourlyRate = 400 },   -- $400/hour
		Glitch    = { HourlyRate = 1500 },  -- $1500/hour
	},
	MaxEquippedSlots = 3  -- Max 3 NFT equipped at once
}

-- [[ 6. BLACKJACK ]]
GameConfig.Blackjack = { 
	MinBet = 50, 
	MaxBet = 50000
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
	GoldYellow = Color3.fromRGB(255, 220, 50),
}

return GameConfig