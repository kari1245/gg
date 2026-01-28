-- src/ServerScriptService/Services/PlanetService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlanetMath = require(ReplicatedStorage.Common.PlanetMath)

local SERVER_SESSION_SEED = math.random(1, 1000000000)
print(`[PlanetService] Universe Generated with Session Seed: {SERVER_SESSION_SEED}`)
-- [CONFIGURATION]
local PLANET_GRID_SPACING = 20000
local MIN_PLANET_SIZE = 400
local MAX_PLANET_SIZE = 1000
local NUM_PLANETS = 500 -- Giữ nguyên số lượng lớn để mật độ dày
local SPAWN_CHANCE = 1 
local MAX_VISIBLE_PLANETS = 30 -- [NEW] Giới hạn cứng số lượng hành tinh gửi về

local BiomeTypes = {
    {Name = "Desert", Color = Color3.fromRGB(232, 213, 160), Emissive = 0},
    {Name = "Ocean", Color = Color3.fromRGB(36, 104, 160), Emissive = 0},
    {Name = "Ice", Color = Color3.fromRGB(210, 235, 250), Emissive = 0},
    {Name = "Volcanic", Color = Color3.fromRGB(60, 30, 20), Emissive = 0.35},
    {Name = "Toxic", Color = Color3.fromRGB(220, 255, 120), Emissive = 0.5},
    {Name = "Crystal", Color = Color3.fromRGB(140, 120, 255), Emissive = 0.7},
    {Name = "Magma", Color = Color3.fromRGB(255, 80, 20), Emissive = 0.6},
    {Name = "Midnight", Color = Color3.fromRGB(20, 24, 82), Emissive = 0.2}
}

local SKY_PRESET_NAMES = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" }

-- [SERVICE DEFINITION]
local PlanetService = {}
PlanetService.Name = "PlanetService"

local _planetGridMap = {}

local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
Remotes.Name = "Remotes"
local GetPlanetsFunc = Remotes:FindFirstChild("GetPlanetsNearPosition") or Instance.new("RemoteFunction", Remotes)
GetPlanetsFunc.Name = "GetPlanetsNearPosition"

-- // HELPER FUNCTIONS //

local function GetGridKey(x, y, z)
    return x .. "," .. y .. "," .. z
end

local function PickRandomSkyName(seed)
    if #SKY_PRESET_NAMES == 0 then return "1" end
    local idx = math.floor(PlanetMath.SeededRandom(seed, 1, #SKY_PRESET_NAMES + 0.99))
    return tostring(idx)
end

local function PickRandomBloomPreset(seed, biomeName)
    return {Brightness = 1.2, BloomIntensity = 0.08, BloomSize = 24, BloomThreshold = 1.3} 
end

-- // CORE LOGIC //

function PlanetService:GeneratePlanetData(gridX, gridY, gridZ, forceSpawn)
	local baseSeed = gridX * 73856093 + gridY * 19349663 + gridZ * 83492791
    local seed = baseSeed + SERVER_SESSION_SEED
    
    if not forceSpawn and PlanetMath.SeededRandom(seed) > SPAWN_CHANCE then 
        return nil 
    end

    local jitterSeed = seed + 12345
    local jitterX = PlanetMath.GetGridJitter(jitterSeed, PLANET_GRID_SPACING*0.25)
    local jitterY = PlanetMath.GetGridJitter(jitterSeed+1, PLANET_GRID_SPACING*0.25)
    local jitterZ = PlanetMath.GetGridJitter(jitterSeed+2, PLANET_GRID_SPACING*0.25)

    local size = PlanetMath.SeededRandom(seed + 1, MIN_PLANET_SIZE, MAX_PLANET_SIZE)
    local biomeIndex = math.floor(PlanetMath.SeededRandom(seed + 2, 1, #BiomeTypes + 0.99))
    local biome = BiomeTypes[biomeIndex]
    
    local baseX = gridX * PLANET_GRID_SPACING + jitterX
    local baseY = gridY * PLANET_GRID_SPACING + jitterY
    local baseZ = gridZ * PLANET_GRID_SPACING + jitterZ

    local offsetX = PlanetMath.SeededRandom(seed + 3, -500, 500)
    local offsetY = PlanetMath.SeededRandom(seed + 4, -500, 500)
    local offsetZ = PlanetMath.SeededRandom(seed + 5, -500, 500)
    
    local worldPos = Vector3.new(baseX + offsetX, baseY + offsetY, baseZ + offsetZ)

    if worldPos.Y - (size/2) < (workspace.FallenPartsDestroyHeight + 200) then 
        return nil 
    end
    
    return {
        GridPos = {X = gridX, Y = gridY, Z = gridZ},
        WorldPos = {X = worldPos.X, Y = worldPos.Y, Z = worldPos.Z},
        Size = size,
        Biome = {
            Name = biome.Name, 
            Color = {R = biome.Color.R, G = biome.Color.G, B = biome.Color.B}, 
            Emissive = biome.Emissive
        },
        Seed = seed,
        SkyPresetName = PickRandomSkyName(seed),
        Bloom = PickRandomBloomPreset(seed, biome.Name),
    }
end

function PlanetService:GenerateAllPlanets()
    local planets = {}
    local used = {}
    local generatedCount = 0
    local startTime = os.clock()

    -- FORCE SPAWN AT (0,0,0)
    local startKey = GetGridKey(0, 0, 0)
    local startPlanet = self:GeneratePlanetData(0, 0, 0, true)
    if startPlanet then
        used[startKey] = true
        _planetGridMap[startKey] = startPlanet
        table.insert(planets, startPlanet)
        generatedCount += 1
        print(`[PlanetService] FORCE SPAWN Start Planet at (0,0,0)`)
    end

    -- Generate Random Planets (Dữ liệu cũ: Mật độ cao trong phạm vi hẹp)
    local attempts = 0
    local maxAttempts = NUM_PLANETS * 20

    while generatedCount < NUM_PLANETS and attempts < maxAttempts do
        attempts += 1
        
        -- Giữ nguyên range = 5 để duy trì mật độ dày đặc như bạn muốn
        local range = 5 
        local gx = math.random(-range, range)
        local gy = math.random(-range, range)
        local gz = math.random(-range, range)

        local key = GetGridKey(gx, gy, gz)
        
        if not used[key] then
            used[key] = true
            local data = self:GeneratePlanetData(gx, gy, gz, false)
            if data then 
                table.insert(planets, data)
                _planetGridMap[key] = data
                generatedCount += 1
            end
        end

        if attempts % 100 == 0 then task.wait() end
    end
    
    print(`[PlanetService] Total Generated: {generatedCount} planets.`)
end

function PlanetService:GetPlanetsNearPosition(player)
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return {} end
    
    local pos = rootPart.Position
    local pGx = math.floor((pos.X / PLANET_GRID_SPACING) + 0.5)
    local pGy = math.floor((pos.Y / PLANET_GRID_SPACING) + 0.5)
    local pGz = math.floor((pos.Z / PLANET_GRID_SPACING) + 0.5)
    
    local nearby = {}
    -- Quét rộng (range = 3 hoặc 4) để đảm bảo gom đủ ứng viên trước khi lọc
    local range = 4 
    
    -- 1. GOM TẤT CẢ HÀNH TINH TRONG TẦM QUÉT
    for x = -range, range do
        for y = -range, range do
            for z = -range, range do
                local key = GetGridKey(pGx + x, pGy + y, pGz + z)
                local planet = _planetGridMap[key]
                if planet then
                    table.insert(nearby, planet)
                end
            end
        end
    end

    -- 2. SẮP XẾP TỪ GẦN ĐẾN XA (QUAN TRỌNG)
    table.sort(nearby, function(a, b)
        local posA = Vector3.new(a.WorldPos.X, a.WorldPos.Y, a.WorldPos.Z)
        local posB = Vector3.new(b.WorldPos.X, b.WorldPos.Y, b.WorldPos.Z)
        return (posA - pos).Magnitude < (posB - pos).Magnitude
    end)

    -- 3. CẮT BỎ, CHỈ LẤY 20 CÁI ĐẦU TIÊN
    if #nearby > MAX_VISIBLE_PLANETS then
        local limited = {}
        for i = 1, MAX_VISIBLE_PLANETS do
            table.insert(limited, nearby[i])
        end
        -- Debug: Kiểm chứng xem có đúng 20 cái không
        -- print(`[PlanetService] Found {#nearby} planets, sending closest {MAX_VISIBLE_PLANETS} to {player.Name}`)
        return limited
    end

    return nearby
end

-- // INIT //

function PlanetService:Init()
    print("[PlanetService] Initializing (Fixed 20 Limit Mode)...")
    
    task.spawn(function()
        self:GenerateAllPlanets()
    end)
    
    GetPlanetsFunc.OnServerInvoke = function(player)
        return self:GetPlanetsNearPosition(player)
    end
end

function PlanetService:Start()
end

return PlanetService