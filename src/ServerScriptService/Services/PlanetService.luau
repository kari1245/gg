--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

-- [TYPES]
export type PlanetData = {
	GridPos: {X: number, Y: number, Z: number},
	WorldPos: {X: number, Y: number, Z: number},
	Size: number,
	Biome: {Name: string, Color: {R: number, G: number, B: number}, Emissive: number},
	Seed: number,
	SkyPresetName: string,
	Bloom: {Brightness: number, BloomIntensity: number, BloomSize: number, BloomThreshold: number},
	Objects: {any},
	GroundTiles: {any},
	IsHome: boolean
}

-- [CONFIGURATION]
local PLANET_GRID_SPACING = 12000
local MIN_PLANET_SIZE = 500
local MAX_PLANET_SIZE = 1500
local NUM_PLANETS = 100
local REQUEST_COOLDOWN = 0.3

-- [CONSTANTS]
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

-- [HELPER FUNCTIONS]
local function GetGridJitter(seed: number, amount: number): number
	local x = math.sin(seed) * 10000
	return (x - math.floor(x)) * 2 * amount - amount
end

local function SeededRandom(seed: number, min: number?, max: number?): number
	local x = math.sin(seed) * 10000
	local frac = x - math.floor(x)
	if min and max then return min + frac * (max - min) end
	return frac
end

local function PickRandomSkyName(seed: number): string
	if #SKY_PRESET_NAMES == 0 then return "" end
	local idx = math.floor(SeededRandom(seed, 1, #SKY_PRESET_NAMES + 0.99))
	return tostring(idx)
end

local function PickRandomBloomPreset(seed: number, biomeName: string)
	return {Brightness = 1.2, BloomIntensity = 0.08, BloomSize = 24, BloomThreshold = 1.3} 
end

-- [SERVICE DEFINITION]
local PlanetService = Knit.CreateService {
	Name = "PlanetService",
	Client = {},
}

-- Private State
local _planetDataCache: {PlanetData} = {}
local _lastRequestTimes: {[Player]: number} = {}

function PlanetService:KnitInit()
	print("[PlanetService] Initializing...")
	
	-- Pre-generate planet data
	self:GenerateAllPlanets()

	-- Cleanup cache on player leave
	Players.PlayerRemoving:Connect(function(player)
		_lastRequestTimes[player] = nil
	end)
end

function PlanetService:GenerateAllPlanets()
	if #_planetDataCache > 0 then return end

	local planets = {}
	local gridSize = math.ceil(NUM_PLANETS^(1/3))
	local used = {}
	local function gridKey(x, y, z) return tostring(x)..","..tostring(y)..","..tostring(z) end
	local i = 1

	-- Deterministic generation loop
	while #planets < NUM_PLANETS do
		local gx = ((i-1) % gridSize) - math.floor(gridSize/2)
		local gy = (math.floor((i-1)/gridSize) % gridSize) - math.floor(gridSize/2)
		local gz = (math.floor((i-1)/(gridSize*gridSize))) - math.floor(gridSize/2)

		local key = gridKey(gx, gy, gz)
		if not used[key] then
			used[key] = true
			local data = self:GeneratePlanetData(gx, gy, gz)
			if data then table.insert(planets, data) end
		end
		i += 1
		if i > gridSize^3 + 1000 then break end
	end
	
	-- Fallback random generation if needed
	while #planets < NUM_PLANETS do
		local gx = math.random(-gridSize, gridSize)
		local gy = math.random(-gridSize, gridSize)
		local gz = math.random(-gridSize, gridSize)
		local key = gridKey(gx, gy, gz)
		if not used[key] then
			used[key] = true
			local data = self:GeneratePlanetData(gx, gy, gz)
			if data then table.insert(planets, data) end
		end
	end

	_planetDataCache = planets
	print("[PlanetService] Planet Data Init Complete. Count:", #planets)
end

function PlanetService:GeneratePlanetData(gridX: number, gridY: number, gridZ: number): PlanetData?
	local seed = gridX * 73856093 + gridY * 19349663 + gridZ * 83492791
	
	-- Calculate Positions
	local jitterSeed = gridX*73856093 + gridY*19349663 + gridZ*83492791 + 12345
	local jitterX = GetGridJitter(jitterSeed, PLANET_GRID_SPACING*0.25)
	local jitterY = GetGridJitter(jitterSeed+1, PLANET_GRID_SPACING*0.25)
	local jitterZ = GetGridJitter(jitterSeed+2, PLANET_GRID_SPACING*0.25)

	local size = SeededRandom(seed + 1, MIN_PLANET_SIZE, MAX_PLANET_SIZE)
	local biomeIndex = math.floor(SeededRandom(seed + 2, 1, #BiomeTypes + 0.99))
	local biome = BiomeTypes[biomeIndex]
	local skyPresetName = PickRandomSkyName(seed)
	local bloomPreset = PickRandomBloomPreset(seed, biome.Name)
	
	local baseX = gridX * PLANET_GRID_SPACING + jitterX
	local baseY = gridY * PLANET_GRID_SPACING + jitterY
	local baseZ = gridZ * PLANET_GRID_SPACING + jitterZ

	local offsetX = SeededRandom(seed + 3, -500, 500)
	local offsetY = SeededRandom(seed + 4, -1500, 1500)
	local offsetZ = SeededRandom(seed + 5, -500, 500)
	
	local worldPos = {
		X = baseX + offsetX,
		Y = baseY + offsetY,
		Z = baseZ + offsetZ
	}

	-- Height Safety Check
	local DESTROY_HEIGHT = workspace.FallenPartsDestroyHeight
	if DESTROY_HEIGHT == -50000 or DESTROY_HEIGHT == 0 then DESTROY_HEIGHT = -500 end 
	local DESTROY_BUFFER = 800
	if worldPos.Y - size/2 < (DESTROY_HEIGHT + DESTROY_BUFFER) then return nil end
	
	-- Generate Ground Tiles
	local groundDiameter = math.min(size * 0.4, size * 0.98)
	local tileY = 3
	local groundY = worldPos.Y 
	
	local groundTiles = {
		{
			Size = {X = groundDiameter, Y = tileY, Z = groundDiameter},
			Position = {X = worldPos.X, Y = groundY, Z = worldPos.Z},
			Color = {R = biome.Color.R, G = biome.Color.G, B = biome.Color.B},
			TopSurface = "Studs",
			BottomSurface = "Studs"
		}
	}

	-- Generate Objects (Trees/Rocks)
	local objects = {}
	local groundArea = groundDiameter * groundDiameter
	local treeDensity = math.clamp(math.floor(groundArea * 0.0012), 12, 120)
	local rockDensity = math.clamp(math.floor(groundArea * 0.0007), 6, 60)
	local numTrees = math.floor(SeededRandom(seed + 8888, 0, treeDensity + 0.99))
	local numRocks = math.floor(SeededRandom(seed + 9999, 0, rockDensity + 0.99))
	local objectMap = {}

	for i = 1, numTrees do
		local objSeed = seed + i * 1009 + 20000
		local relX = SeededRandom(objSeed + 1, -0.5, 0.5) * (groundDiameter * 0.98)
		local relZ = SeededRandom(objSeed + 2, -0.5, 0.5) * (groundDiameter * 0.98)
		local posX = worldPos.X + relX 
		local posY = groundY + tileY/2 
		local posZ = worldPos.Z + relZ
		local key = tostring(math.floor(posX*10))..","..tostring(math.floor(posZ*10))
		
		if not objectMap[key] then
			local treeType = tostring(math.clamp(math.floor(SeededRandom(objSeed + 20000, 1, 5.99)), 1, 5))
			local rotY = SeededRandom(objSeed + 30000, 0, 360)
			local scale = 0.85 + SeededRandom(objSeed + 40000, 0, 0.3)
			table.insert(objects, {Type = "Tree", Model = treeType, PosX = posX, PosY = posY, PosZ = posZ, RotY = rotY, Scale = scale})
			objectMap[key] = true
		end
	end

	for i = 1, numRocks do
		local objSeed = seed + i * 2009 + 30000
		local relX = SeededRandom(objSeed + 1, -0.5, 0.5) * (groundDiameter * 0.98)
		local relZ = SeededRandom(objSeed + 2, -0.5, 0.5) * (groundDiameter * 0.98)
		local posX = worldPos.X + relX
		local posY = groundY + tileY/2
		local posZ = worldPos.Z + relZ
		local key = tostring(math.floor(posX*10))..","..tostring(math.floor(posZ*10))
		
		if not objectMap[key] then
			local rockType = tostring(math.clamp(math.floor(SeededRandom(objSeed + 30000, 1, 5.99)), 1, 5))
			local rotY = SeededRandom(objSeed + 35000, 0, 360)
			local scale = 0.85 + SeededRandom(objSeed + 45000, 0, 0.3)
			table.insert(objects, {Type = "Rock", Model = rockType, PosX = posX, PosY = posY, PosZ = posZ, RotY = rotY, Scale = scale})
			objectMap[key] = true
		end
	end

	-- Chance to fail generation (Empty space)
	if SeededRandom(seed) > 0.9 then return nil end

	return {
		GridPos = {X = gridX, Y = gridY, Z = gridZ},
		WorldPos = worldPos,
		Size = size,
		Biome = {Name = biome.Name, Color = {R = biome.Color.R, G = biome.Color.G, B = biome.Color.B}, Emissive = biome.Emissive},
		Seed = seed,
		IsHome = false,
		SkyPresetName = skyPresetName,
		Bloom = bloomPreset,
		Objects = objects,
		GroundTiles = groundTiles
	}
end

-- [CLIENT METHODS]
function PlanetService.Client:GetPlanetsNearPosition(player: Player): {PlanetData}
	-- Rate Limiting
	local now = os.clock()
	local lastTime = _lastRequestTimes[player] or 0
	if (now - lastTime) < REQUEST_COOLDOWN then
		return {} -- Return empty if spamming
	end
	_lastRequestTimes[player] = now

	-- Server Authority Position
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return {} end
	
	local position = (rootPart :: BasePart).Position
	
	-- Sort planets by distance
	local nearby = {}
	for i, data in ipairs(_planetDataCache) do
		table.insert(nearby, data) 
	end
	
	table.sort(nearby, function(a, b)
		local pa = Vector3.new(a.WorldPos.X, a.WorldPos.Y, a.WorldPos.Z)
		local pb = Vector3.new(b.WorldPos.X, b.WorldPos.Y, b.WorldPos.Z)
		return (pa - position).Magnitude < (pb - position).Magnitude
	end)

	-- Return closest 20
	local result = {}
	for i = 1, math.min(20, #nearby) do
		table.insert(result, nearby[i])
	end

	return result
end

return PlanetService