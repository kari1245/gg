local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlanetService = {}

-- Configuration
local PLANET_GRID_SPACING = 1800 -- Distance between planets
local MIN_PLANET_SIZE = 500
local MAX_PLANET_SIZE = 1500

-- Biome types (metadata only)
local BiomeTypes = {
	{Name = "Desert", Color = Color3.fromRGB(220, 180, 100), Emissive = 0},
	{Name = "Ocean", Color = Color3.fromRGB(30, 100, 180), Emissive = 0},
	{Name = "Forest", Color = Color3.fromRGB(50, 150, 50), Emissive = 0},
	{Name = "Ice", Color = Color3.fromRGB(200, 230, 255), Emissive = 0},
	{Name = "Volcanic", Color = Color3.fromRGB(180, 50, 30), Emissive = 0.3},
	{Name = "Toxic", Color = Color3.fromRGB(150, 255, 50), Emissive = 0.5},
	{Name = "Crystal", Color = Color3.fromRGB(200, 100, 255), Emissive = 0.7},
	{Name = "Glitch", Color = Color3.fromRGB(255, 0, 255), Emissive = 1}
}

-- Home planet height

local HOME_PLANET_HEIGHT = 3000
local DESTROY_HEIGHT = workspace and workspace.FallenPartsDestroyHeight or -500
local DESTROY_BUFFER = 800 -- Minimum distance from destroy height for any planet

-- Seeded random number generator
local function SeededRandom(seed, min, max)
	local x = math.sin(seed) * 10000
	local frac = x - math.floor(x)
	if min and max then
		return min + frac * (max - min)
	end
	return frac
end

-- List of available sky preset names (should match names in ReplicatedStorage/Skies)
local SKY_PRESET_NAMES = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" }

local function PickRandomSkyName(seed)
    if #SKY_PRESET_NAMES == 0 then return "" end
    local idx = math.floor(SeededRandom(seed, 1, #SKY_PRESET_NAMES + 0.99))
    return tostring(idx) -- chỉ trả về số, ví dụ "1", "2", ...
end

-- List of available bloom/lighting presets
local BLOOM_PRESETS = {
    {Brightness = 2, BloomIntensity = 0.2, BloomSize = 24, BloomThreshold = 1},
    {Brightness = 3, BloomIntensity = 0.4, BloomSize = 36, BloomThreshold = 0.8},
    {Brightness = 1.5, BloomIntensity = 0.1, BloomSize = 16, BloomThreshold = 1.2},
    {Brightness = 2.5, BloomIntensity = 0.3, BloomSize = 32, BloomThreshold = 0.9},
    {Brightness = 2, BloomIntensity = 0.5, BloomSize = 40, BloomThreshold = 0.7},
}

local function PickRandomBloomPreset(seed)
    local idx = math.floor(SeededRandom(seed, 1, #BLOOM_PRESETS + 0.99))
    return BLOOM_PRESETS[idx] or BLOOM_PRESETS[1]
end

-- List of available surface types for baseplate
local SURFACE_TYPES = {
    Enum.SurfaceType.Studs,
    Enum.SurfaceType.Smooth,
    Enum.SurfaceType.Universal,
    Enum.SurfaceType.Glue,
    Enum.SurfaceType.Weld,
    Enum.SurfaceType.Hinge,
    Enum.SurfaceType.Motor,
    Enum.SurfaceType.SteppingMotor,
    Enum.SurfaceType.Inlet
}

local function PickRandomSurfaceType(seed)
    local idx = math.floor(SeededRandom(seed, 1, #SURFACE_TYPES + 0.99))
    return SURFACE_TYPES[idx] or Enum.SurfaceType.Studs
end

-- Generate planet metadata from grid coordinates (lightweight, no mesh creation)
function PlanetService:GeneratePlanetData(gridX, gridY, gridZ)
		if gridX == 0 and gridY == 0 and gridZ == 0 then
			print("[DEBUG][SERVER] GeneratePlanetData(0,0,0) called")
		end
	local seed = gridX * 73856093 + gridY * 19349663 + gridZ * 83492791
	
	-- Home planet at 0,0,0, always at center
	if gridX == 0 and gridY == 0 and gridZ == 0 then
		print("[DEBUG][SERVER] GeneratePlanetData(0,0,0) RETURN HOME PLANET")
		local biome = BiomeTypes[3]
		local skyPresetName = PickRandomSkyName(seed)
		local bloomPreset = PickRandomBloomPreset(seed)
		local surfaceType = PickRandomSurfaceType(seed)
		return {
			GridPos = {X = 0, Y = 0, Z = 0},
			WorldPos = {X = 0, Y = HOME_PLANET_HEIGHT, Z = 0},
			Size = 500, -- Home planet size set to 500
			Biome = {
				Name = biome.Name,
				Color = {R = biome.Color.R, G = biome.Color.G, B = biome.Color.B},
				Emissive = biome.Emissive
			},
			Seed = seed,
			IsHome = true,
			SkyPresetName = skyPresetName,
			Bloom = bloomPreset,
			SurfaceType = surfaceType
		}
	end
	
	-- 90% chance to have a planet
	if SeededRandom(seed) > 0.9 then
		return nil
	end

	local size = SeededRandom(seed + 1, MIN_PLANET_SIZE, MAX_PLANET_SIZE)
	local biomeIndex = math.floor(SeededRandom(seed + 2, 1, #BiomeTypes + 0.99))
	local biome = BiomeTypes[biomeIndex]
	local skyPresetName = PickRandomSkyName(seed)
	local bloomPreset = PickRandomBloomPreset(seed)
	local surfaceType = PickRandomSurfaceType(seed)

	-- Calculate world position
	local baseX = gridX * PLANET_GRID_SPACING
	local baseY = gridY * PLANET_GRID_SPACING
	local baseZ = gridZ * PLANET_GRID_SPACING

	local offsetX = SeededRandom(seed + 3, -500, 500)
	local offsetY = SeededRandom(seed + 4, -500, 500)
	local offsetZ = SeededRandom(seed + 5, -500, 500)

	local worldPos = {
		X = baseX + offsetX,
		Y = baseY + offsetY,
		Z = baseZ + offsetZ
	}

	-- Prevent planets from spawning too close to destroy height
	if worldPos.Y - size/2 < (DESTROY_HEIGHT + DESTROY_BUFFER) then
		return nil
	end

	-- Check distance to home planet
	local dx = worldPos.X - 0
	local dy = worldPos.Y - HOME_PLANET_HEIGHT
	local dz = worldPos.Z - 0
	local distanceToHome = math.sqrt(dx*dx + dy*dy + dz*dz)
	local minSafeDistance = (2000 + size) / 2 + 500

	if distanceToHome < minSafeDistance then
		return nil -- Too close to home
	end

	return {
		GridPos = {X = gridX, Y = gridY, Z = gridZ},
		WorldPos = worldPos,
		Size = size,
		Biome = {
			Name = biome.Name,
			Color = {R = biome.Color.R, G = biome.Color.G, B = biome.Color.B},
			Emissive = biome.Emissive
		},
		Seed = seed,
		IsHome = false,
		SkyPresetName = skyPresetName,
		Bloom = bloomPreset,
		SurfaceType = surfaceType
	}
end

-- Get planets near a position (returns metadata only)
function PlanetService:GetPlanetsNearPosition(position)
	-- Đảm bảo home planet luôn nằm ở grid (0,0,0) với Y = HOME_PLANET_HEIGHT
	local gridOriginX = math.floor(position.X / PLANET_GRID_SPACING)
	local gridOriginY = math.floor((position.Y - HOME_PLANET_HEIGHT) / PLANET_GRID_SPACING)
	local gridOriginZ = math.floor(position.Z / PLANET_GRID_SPACING)
	
	local planets = {}
	local range = 3 -- Check 7x7x7 grid around player

	local homePlanetAdded = false

	for x = -range, range do
		for y = -range, range do
			for z = -range, range do
				local gx = gridOriginX + x
				local gy = gridOriginY + y
				local gz = gridOriginZ + z
				
				local data = self:GeneratePlanetData(gx, gy, gz)
				if data then
					table.insert(planets, data)
					if data.IsHome then
						homePlanetAdded = true
					end
				end
			end
		end
	end

	-- Đảm bảo luôn có planet home
	if not homePlanetAdded then
		local homeData = self:GeneratePlanetData(0, 0, 0)
		if homeData then
			print("[DEBUG][SERVER] Home planet forcibly added to metadata list")
			table.insert(planets, homeData)
		else
			print("[DEBUG][SERVER] Home planet (0,0,0) returned nil!")
		end
	end

	return planets
end

-- Create planet terrain
function PlanetService:CreatePlanetTerrain(planetData, parent)
    -- Classic baseplate: grid of small Parts (8x8 studs)
    local tileSize = 8
    local groundHeight = 4
    local numTiles = math.floor(planetData.Size / tileSize)
    local startPos = planetData.Position + Vector3.new(-planetData.Size/2 + tileSize/2, -10, -planetData.Size/2 + tileSize/2)
    local groundFolder = Instance.new("Folder")
    groundFolder.Name = "GroundTiles"
    groundFolder.Parent = parent
	local surfaceType = planetData.SurfaceType or Enum.SurfaceType.Studs
	for x = 0, numTiles - 1 do
		for z = 0, numTiles - 1 do
			local tile = Instance.new("Part")
			tile.Name = "Tile"
			tile.Size = Vector3.new(tileSize, groundHeight, tileSize)
			tile.Anchored = true
			tile.Material = Enum.Material.Plastic
			tile.TopSurface = surfaceType
			tile.BottomSurface = surfaceType
			tile.FrontSurface = surfaceType
			tile.BackSurface = surfaceType
			tile.LeftSurface = surfaceType
			tile.RightSurface = surfaceType
			tile.Color = Color3.fromRGB(106, 127, 63)
			tile.Position = startPos + Vector3.new(x * tileSize, 0, z * tileSize)
			tile.Parent = groundFolder
		end
	end
    return groundFolder
end

return PlanetService
