local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local PlanetMath = require(ReplicatedStorage.Common.PlanetMath) -- Import Math

-- [CONFIGURATION]
local PLANET_GRID_SPACING = 12000
local MIN_PLANET_SIZE = 500
local MAX_PLANET_SIZE = 1500
local NUM_PLANETS = 100
local REQUEST_COOLDOWN = 0.3

-- [CONSTANTS] (Giữ nguyên BiomeTypes cũ của bạn)
local BiomeTypes = {
	{Name = "Desert", Color = Color3.fromRGB(232, 213, 160), Emissive = 0},
	{Name = "Ocean", Color = Color3.fromRGB(36, 104, 160), Emissive = 0},
	{Name = "Ice", Color = Color3.fromRGB(210, 235, 250), Emissive = 0},
	{Name = "Volcanic", Color = Color3.fromRGB(60, 30, 20), Emissive = 0.35},
	{Name = "Toxic", Color = Color3.fromRGB(220, 255, 120), Emissive = 0.5},
	{Name = "Crystal", Color = Color3.fromRGB(140, 120, 255), Emissive = 0.7},
	{Name = "Glitch", Color = Color3.fromRGB(255, 0, 255), Emissive = 1},
	{Name = "Magma", Color = Color3.fromRGB(255, 80, 20), Emissive = 0.6},
	{Name = "Cloud", Color = Color3.fromRGB(220, 220, 230), Emissive = 0.1},
	{Name = "Copper", Color = Color3.fromRGB(184, 115, 51), Emissive = 0.2},
	{Name = "Sapphire", Color = Color3.fromRGB(15, 82, 186), Emissive = 0.4},
	{Name = "Ruby", Color = Color3.fromRGB(224, 17, 95), Emissive = 0.5},
	{Name = "Amethyst", Color = Color3.fromRGB(153, 102, 204), Emissive = 0.5},
	{Name = "Sandstone", Color = Color3.fromRGB(237, 201, 175), Emissive = 0.1},
	{Name = "Midnight", Color = Color3.fromRGB(20, 24, 82), Emissive = 0.2}
}

local SKY_PRESET_NAMES = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" }

-- [SERVICE DEFINITION]
local PlanetService = Knit.CreateService {
	Name = "PlanetService",
	Client = {},
}

-- Private State
local _planetGridMap = {} -- Dùng Hash Map cho nhanh
local _lastRequestTimes = {}

local function PickRandomSkyName(seed)
	if #SKY_PRESET_NAMES == 0 then return "" end
	local idx = math.floor(PlanetMath.SeededRandom(seed, 1, #SKY_PRESET_NAMES + 0.99))
	return tostring(idx)
end

local function PickRandomBloomPreset(seed, biomeName)
	return {Brightness = 1.2, BloomIntensity = 0.08, BloomSize = 24, BloomThreshold = 1.3} 
end

local function GetGridKey(x, y, z)
	return x .. "," .. y .. "," .. z
end

function PlanetService:KnitInit()
	print("[PlanetService] Initializing...")
	self:GenerateAllPlanets()
	
	Players.PlayerRemoving:Connect(function(player)
		_lastRequestTimes[player] = nil
	end)
end

function PlanetService:GenerateAllPlanets()
	local planets = {}
	local gridSize = math.ceil(NUM_PLANETS^(1/3))
	local used = {}
	local i = 1

	while #planets < NUM_PLANETS do
		local gx = ((i-1) % gridSize) - math.floor(gridSize/2)
		local gy = (math.floor((i-1)/gridSize) % gridSize) - math.floor(gridSize/2)
		local gz = (math.floor((i-1)/(gridSize*gridSize))) - math.floor(gridSize/2)

		local key = GetGridKey(gx, gy, gz)
		if not used[key] then
			used[key] = true
			local data = self:GeneratePlanetData(gx, gy, gz)
			if data then 
				table.insert(planets, data)
				_planetGridMap[key] = data
			end
		end
		i += 1
		if i > gridSize^3 + 2000 then break end
	end
	
	print("[PlanetService] Generated", #planets, "planets.")
end

function PlanetService:GeneratePlanetData(gridX, gridY, gridZ)
	local seed = gridX * 73856093 + gridY * 19349663 + gridZ * 83492791
	
	-- Calculate Positions
	local jitterSeed = seed + 12345
	local jitterX = PlanetMath.GetGridJitter(jitterSeed, PLANET_GRID_SPACING*0.25)
	local jitterY = PlanetMath.GetGridJitter(jitterSeed+1, PLANET_GRID_SPACING*0.25)
	local jitterZ = PlanetMath.GetGridJitter(jitterSeed+2, PLANET_GRID_SPACING*0.25)

	local size = PlanetMath.SeededRandom(seed + 1, MIN_PLANET_SIZE, MAX_PLANET_SIZE)
	local biomeIndex = math.floor(PlanetMath.SeededRandom(seed + 2, 1, #BiomeTypes + 0.99))
	local biome = BiomeTypes[biomeIndex]
	local skyPresetName = PickRandomSkyName(seed)
	local bloomPreset = PickRandomBloomPreset(seed, biome.Name)
	
	local baseX = gridX * PLANET_GRID_SPACING + jitterX
	local baseY = gridY * PLANET_GRID_SPACING + jitterY
	local baseZ = gridZ * PLANET_GRID_SPACING + jitterZ

	local offsetX = PlanetMath.SeededRandom(seed + 3, -500, 500)
	local offsetY = PlanetMath.SeededRandom(seed + 4, -1500, 1500)
	local offsetZ = PlanetMath.SeededRandom(seed + 5, -500, 500)
	
	local worldPos = {
		X = baseX + offsetX,
		Y = baseY + offsetY,
		Z = baseZ + offsetZ
	}

	-- Height Safety Check
	local DESTROY_HEIGHT = workspace.FallenPartsDestroyHeight
	if DESTROY_HEIGHT == -50000 or DESTROY_HEIGHT == 0 then DESTROY_HEIGHT = -500 end 
	if worldPos.Y - size/2 < (DESTROY_HEIGHT + 800) then return nil end
	
	-- Chance to fail generation
	if PlanetMath.SeededRandom(seed) > 0.9 then return nil end

	-- TRAFFIC OPTIMIZATION: BỎ Objects và GroundTiles
	return {
		GridPos = {X = gridX, Y = gridY, Z = gridZ},
		WorldPos = worldPos,
		Size = size,
		Biome = {Name = biome.Name, Color = {R = biome.Color.R, G = biome.Color.G, B = biome.Color.B}, Emissive = biome.Emissive},
		Seed = seed,
		IsHome = false,
		SkyPresetName = skyPresetName,
		Bloom = bloomPreset,
		-- Objects = objects, <-- BỎ, Client tự tính
		-- GroundTiles = groundTiles <-- BỎ
	}
end

-- [CLIENT METHODS]
function PlanetService.Client:GetPlanetsNearPosition(player)
	local now = os.clock()
	local lastTime = _lastRequestTimes[player] or 0
	if (now - lastTime) < REQUEST_COOLDOWN then return {} end
	_lastRequestTimes[player] = now

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return {} end
	
	local pos = rootPart.Position
	
	-- Spatial Partitioning Lookup (Nhanh hơn duyệt mảng)
	local pGx = math.floor((pos.X / PLANET_GRID_SPACING) + 0.5)
	local pGy = math.floor((pos.Y / PLANET_GRID_SPACING) + 0.5)
	local pGz = math.floor((pos.Z / PLANET_GRID_SPACING) + 0.5)
	
	local nearby = {}
	local range = 1 -- 3x3x3 grid
	
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
	
	-- Sort by distance
	table.sort(nearby, function(a, b)
		local pa = Vector3.new(a.WorldPos.X, a.WorldPos.Y, a.WorldPos.Z)
		local pb = Vector3.new(b.WorldPos.X, b.WorldPos.Y, b.WorldPos.Z)
		return (pa - pos).Magnitude < (pb - pos).Magnitude
	end)

	return nearby
end

return PlanetService