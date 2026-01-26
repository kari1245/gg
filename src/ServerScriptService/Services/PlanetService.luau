local PlanetService = {}
local _planetDataCache = nil

-- Configuration
local PLANET_GRID_SPACING = 3000
local MIN_PLANET_SIZE = 500
local MAX_PLANET_SIZE = 1500

-- [SERVER] Dynamic Safe Height
local DESTROY_HEIGHT = workspace.FallenPartsDestroyHeight
if DESTROY_HEIGHT == -50000 or DESTROY_HEIGHT == 0 then DESTROY_HEIGHT = -500 end 
local DESTROY_BUFFER = 800

local function GetGridJitter(seed, amount)
	local x = math.sin(seed) * 10000
	return (x - math.floor(x)) * 2 * amount - amount
end

local function SeededRandom(seed, min, max)
	local x = math.sin(seed) * 10000
	local frac = x - math.floor(x)
	if min and max then return min + frac * (max - min) end
	return frac
end

-- Biome Types
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
local BLOOM_PRESETS = {
	{Brightness = 1.2, BloomIntensity = 0.08, BloomSize = 24, BloomThreshold = 1.3, Ambient = {R=30/255, G=30/255, B=40/255}, OutdoorAmbient = {R=40/255, G=40/255, B=50/255}, EnvironmentDiffuseScale = 1.1, EnvironmentSpecularScale = 0.35, ColorCorrection = {Brightness = 0.1, Contrast = 0.03, Saturation = -0.05, TintColor = {R=240/255, G=240/255, B=255/255}}},
	{Brightness = 1.4, BloomIntensity = 0.12, BloomSize = 36, BloomThreshold = 1.1, Ambient = {R=25/255, G=25/255, B=35/255}, OutdoorAmbient = {R=35/255, G=35/255, B=45/255}, EnvironmentDiffuseScale = 1.1, EnvironmentSpecularScale = 0.35, ColorCorrection = {Brightness = 0.12, Contrast = 0.04, Saturation = -0.07, TintColor = {R=235/255, G=235/255, B=250/255}}},
	{Brightness = 1.0, BloomIntensity = 0.05, BloomSize = 16, BloomThreshold = 1.5, Ambient = {R=20/255, G=20/255, B=30/255}, OutdoorAmbient = {R=30/255, G=30/255, B=40/255}, EnvironmentDiffuseScale = 1.1, EnvironmentSpecularScale = 0.35, ColorCorrection = {Brightness = 0.08, Contrast = 0.02, Saturation = -0.09, TintColor = {R=230/255, G=230/255, B=245/255}}},
	{Brightness = 1.3, BloomIntensity = 0.09, BloomSize = 32, BloomThreshold = 1.2, Ambient = {R=28/255, G=28/255, B=38/255}, OutdoorAmbient = {R=38/255, G=38/255, B=48/255}, EnvironmentDiffuseScale = 1.1, EnvironmentSpecularScale = 0.35, ColorCorrection = {Brightness = 0.11, Contrast = 0.03, Saturation = -0.06, TintColor = {R=238/255, G=238/255, B=252/255}}},
	{Brightness = 1.1, BloomIntensity = 0.13, BloomSize = 40, BloomThreshold = 1.0, Ambient = {R=22/255, G=22/255, B=32/255}, OutdoorAmbient = {R=32/255, G=32/255, B=42/255}, EnvironmentDiffuseScale = 1.1, EnvironmentSpecularScale = 0.35, ColorCorrection = {Brightness = 0.09, Contrast = 0.025, Saturation = -0.08, TintColor = {R=232/255, G=232/255, B=248/255}}},
}
local SURFACE_TYPES = {Enum.SurfaceType.Studs, Enum.SurfaceType.Smooth, Enum.SurfaceType.Universal, Enum.SurfaceType.Glue, Enum.SurfaceType.Weld, Enum.SurfaceType.Hinge, Enum.SurfaceType.Motor, Enum.SurfaceType.SteppingMotor, Enum.SurfaceType.Inlet}

local function PickRandomSkyName(seed)
	if #SKY_PRESET_NAMES == 0 then return "" end
	local idx = math.floor(SeededRandom(seed, 1, #SKY_PRESET_NAMES + 0.99))
	return tostring(idx)
end

local function PickRandomBloomPreset(seed, biomeName)
	local biomePresetMap = { Desert = 1, Ocean = 2, Ice = 3, Volcanic = 4, Toxic = 5, Crystal = 2, Glitch = 5, Magma = 4, Cloud = 1, Copper = 1, Sapphire = 2, Ruby = 4, Amethyst = 5, Sandstone = 1, Midnight = 3 }
	local presetIdx = biomePresetMap[biomeName or ""]
	local offset = math.floor(SeededRandom(seed+999, -1, 1.99))
	local idx = math.clamp((presetIdx or 1) + offset, 1, #BLOOM_PRESETS)
	return BLOOM_PRESETS[idx] or BLOOM_PRESETS[1]
end

local function PickRandomSurfaceType(seed)
	local idx = math.floor(SeededRandom(seed, 1, #SURFACE_TYPES + 0.99))
	return SURFACE_TYPES[idx] or Enum.SurfaceType.Studs
end

-- ==============================================================================
-- GENERATE PLANET DATA
-- ==============================================================================
function PlanetService:GeneratePlanetData(gridX, gridY, gridZ)
	local seed = gridX * 73856093 + gridY * 19349663 + gridZ * 83492791
	
	-- Jitter Logic
	local jitterSeed = gridX*73856093 + gridY*19349663 + gridZ*83492791 + 12345
	local jitterX = GetGridJitter(jitterSeed, PLANET_GRID_SPACING*0.25)
	local jitterY = GetGridJitter(jitterSeed+1, PLANET_GRID_SPACING*0.25)
	local jitterZ = GetGridJitter(jitterSeed+2, PLANET_GRID_SPACING*0.25)

	local size = SeededRandom(seed + 1, MIN_PLANET_SIZE, MAX_PLANET_SIZE)
	local biomeIndex = math.floor(SeededRandom(seed + 2, 1, #BiomeTypes + 0.99))
	local biome = BiomeTypes[biomeIndex]
	local skyPresetName = PickRandomSkyName(seed)
	local bloomPreset = PickRandomBloomPreset(seed, biome.Name)
	local surfaceType = tostring(PickRandomSurfaceType(seed))
	
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

	if not worldPos or not worldPos.X or not worldPos.Z or not size then return nil end

	-- Safety Checks
	if worldPos.Y - size/2 < (DESTROY_HEIGHT + DESTROY_BUFFER) then return nil end
	
	-- Ground (Centered)
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

	-- Objects
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
		SurfaceType = surfaceType,
		Objects = objects,
		GroundTiles = groundTiles
	}
end

-- ==============================================================================
-- INIT DATA
-- ==============================================================================
local function InitPlanetData(PlanetServiceRef)
	if _planetDataCache then return end
	local planets = {}
	local MIN_DIST = 2500
	local NUM_PLANETS = 100

	local gridSize = math.ceil(NUM_PLANETS^(1/3))
	local used = {}
	local function gridKey(x, y, z) return tostring(x)..","..tostring(y)..","..tostring(z) end
	local i = 1

	while #planets < NUM_PLANETS do
		local gx = ((i-1) % gridSize) - math.floor(gridSize/2)
		local gy = (math.floor((i-1)/gridSize) % gridSize) - math.floor(gridSize/2)
		local gz = (math.floor((i-1)/(gridSize*gridSize))) - math.floor(gridSize/2)
		
		local key = gridKey(gx, gy, gz)
		if not used[key] then
			used[key] = true
			local data = PlanetServiceRef:GeneratePlanetData(gx, gy, gz)
			if data then
				local tooClose = false
				for _, p in ipairs(planets) do
					local dist = math.sqrt((data.WorldPos.X - p.WorldPos.X)^2 + (data.WorldPos.Y - p.WorldPos.Y)^2 + (data.WorldPos.Z - p.WorldPos.Z)^2)
					if dist < MIN_DIST then tooClose = true break end
				end
				if not tooClose then
					table.insert(planets, data)
				end
			end
		end
		
		i = i + 1
		if i > gridSize^3 + 1000 then break end
	end
	
	while #planets < NUM_PLANETS do
		local gx = math.random(-gridSize, gridSize)
		local gy = math.random(-gridSize, gridSize)
		local gz = math.random(-gridSize, gridSize)
		local key = gridKey(gx, gy, gz)
		if not used[key] then
			used[key] = true
			local data = PlanetServiceRef:GeneratePlanetData(gx, gy, gz)
			if data then
				table.insert(planets, data)
			end
		end
	end
	_planetDataCache = planets
	print("[SERVER] Planet Data Init Complete. Count:", #planets)
end

function PlanetService:GetPlanetsNearPosition(position)
	InitPlanetData(self)
	local planets = _planetDataCache or {}
	if #planets == 0 then return {} end

	local nearby = {}
	for i, data in ipairs(planets) do
		table.insert(nearby, data) 
	end
	
	table.sort(nearby, function(a, b)
		local pa = Vector3.new(a.WorldPos.X, a.WorldPos.Y, a.WorldPos.Z)
		local pb = Vector3.new(b.WorldPos.X, b.WorldPos.Y, b.WorldPos.Z)
		return (pa - position).Magnitude < (pb - position).Magnitude
	end)

	local result = {}
	local DETAIL_DISTANCE = 4000 

	for i = 1, math.min(20, #nearby) do
		local planetRaw = nearby[i]
		local planetData = table.clone(planetRaw) 
		
		local dist = (Vector3.new(planetData.WorldPos.X, planetData.WorldPos.Y, planetData.WorldPos.Z) - position).Magnitude
		
		if dist > DETAIL_DISTANCE then
			planetData.Objects = nil 
			planetData.GroundTiles = nil 
		end
		
		table.insert(result, planetData)
	end

	return result
end

return PlanetService