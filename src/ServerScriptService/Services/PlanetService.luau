local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local PlanetService = Knit.CreateService {
	Name = "PlanetService",
	Client = {}
}

-- Configuration
local PLANET_GRID_SPACING = 1800 -- Distance between potential planet spawns (closer planets)
local PLANET_RENDER_DISTANCE = 15000 -- Max distance to render planets
local MIN_PLANET_SIZE = 500 -- Reduced for closer spacing
local MAX_PLANET_SIZE = 1500 -- Reduced to prevent overlap

-- Active planets in the world (key = grid coordinate string like "0_0_0")
local ActivePlanets = {}

-- Biome types with colors
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

-- Seeded random number generator
local function SeededRandom(seed, min, max)
	local x = math.sin(seed) * 10000
	local frac = x - math.floor(x)
	if min and max then
		return min + frac * (max - min)
	end
	return frac
end

-- Home planet height (safe from death barrier)
local HOME_PLANET_HEIGHT = 3000

-- Generate planet data from grid coordinates
function PlanetService:GeneratePlanetData(gridX, gridY, gridZ)
	local seed = gridX * 73856093 + gridY * 19349663 + gridZ * 83492791
	
	-- Home planet at 0,0,0 always exists at safe height
	if gridX == 0 and gridY == 0 and gridZ == 0 then
		return {
			GridPos = {X = 0, Y = 0, Z = 0},
			WorldPos = Vector3.new(0, HOME_PLANET_HEIGHT, 0),
			Size = 2000, -- Larger home planet
			Biome = BiomeTypes[3], -- Forest (green)
			Seed = seed,
			IsHome = true
		}
	end
	
	-- 90% chance to have a planet at this grid position
	if SeededRandom(seed) > 0.9 then
		return nil -- No planet here
	end
	
	local size = SeededRandom(seed + 1, MIN_PLANET_SIZE, MAX_PLANET_SIZE)
	local biomeIndex = math.floor(SeededRandom(seed + 2, 1, #BiomeTypes + 0.99))
	local biome = BiomeTypes[biomeIndex]
	
	-- Calculate world position (with small random offset)
	local basePos = Vector3.new(gridX, gridY, gridZ) * PLANET_GRID_SPACING
	local offset = Vector3.new(
		SeededRandom(seed + 3, -500, 500),
		SeededRandom(seed + 4, -500, 500),
		SeededRandom(seed + 5, -500, 500)
	)
	
	local worldPos = basePos + offset
	
	-- Prevent planets from spawning too close to home planet
	local homePlanetPos = Vector3.new(0, HOME_PLANET_HEIGHT, 0)
	local distanceToHome = (worldPos - homePlanetPos).Magnitude
	local minSafeDistance = (2000 + size) / 2 + 500 -- Home planet radius + new planet radius + 500 buffer
	
	if distanceToHome < minSafeDistance then
		return nil -- Skip planets too close to home
	end
	
	return {
		GridPos = {X = gridX, Y = gridY, Z = gridZ},
		WorldPos = worldPos,
		Size = size,
		Biome = biome,
		Seed = seed
	}
end

-- Create physical planet in workspace
function PlanetService:CreatePlanetMesh(data)
	print("🌐 Creating planet mesh at", data.WorldPos, "- Size:", data.Size, "- Biome:", data.Biome.Name)
	
	-- Create Model wrapper
	local planetModel = Instance.new("Model")
	planetModel.Name = "Planet_" .. data.GridPos.X .. "_" .. data.GridPos.Y .. "_" .. data.GridPos.Z
	
	-- Create atmosphere shell (transparent, can pass through)
	local atmosphere = Instance.new("Part")
	atmosphere.Name = "Atmosphere"
	atmosphere.Size = Vector3.new(data.Size, data.Size, data.Size)
	atmosphere.Position = data.WorldPos
	atmosphere.Anchored = true
	atmosphere.CanCollide = false -- Can fly through
	atmosphere.Material = Enum.Material.ForceField
	atmosphere.Color = data.Biome.Color
	atmosphere.Shape = Enum.PartType.Ball
	atmosphere.Transparency = 0.5
	atmosphere.Parent = planetModel
	
	-- Add atmosphere glow
	local atmosphereLight = Instance.new("PointLight")
	atmosphereLight.Brightness = 5
	atmosphereLight.Range = data.Size * 1.5
	atmosphereLight.Color = data.Biome.Color
	atmosphereLight.Parent = atmosphere
	
	-- Create inner terrain platform (flat ground inside planet)
	local platformSize = data.Size * 0.5
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Size = Vector3.new(platformSize, 20, platformSize)
	ground.Position = data.WorldPos
	ground.Anchored = true
	ground.CanCollide = true
	ground.Material = Enum.Material.Ground
	ground.Color = data.Biome.Color
	ground.Parent = planetModel
	
	-- Add natural surface texture
	local surfaceTexture = Instance.new("Texture")
	surfaceTexture.Texture = "rbxasset://textures/terrain/grass.png"
	surfaceTexture.Face = Enum.NormalId.Top
	surfaceTexture.StudsPerTileU = 8
	surfaceTexture.StudsPerTileV = 8
	surfaceTexture.Parent = ground
	
	-- Add decorations (trees, rocks)
	local decorationCount = math.random(10, 30)
	for i = 1, decorationCount do
		local isTree = math.random() > 0.4
		local decoration = Instance.new("Part")
		
		if isTree then
			-- Create tree
			decoration.Name = "Tree"
			decoration.Size = Vector3.new(3, math.random(20, 40), 3)
			decoration.Material = Enum.Material.Wood
			decoration.Color = Color3.fromRGB(101, 67, 33)
			
			-- Add foliage
			local foliage = Instance.new("Part")
			foliage.Name = "Foliage"
			foliage.Size = Vector3.new(10, 15, 10)
			foliage.Shape = Enum.PartType.Ball
			foliage.Material = Enum.Material.Grass
			foliage.Color = data.Biome.Color
			foliage.Position = decoration.Position + Vector3.new(0, decoration.Size.Y/2 + 7, 0)
			foliage.Anchored = true
			foliage.CanCollide = true
			foliage.Parent = planetModel
		else
			-- Create rock
			decoration.Name = "Rock"
			decoration.Size = Vector3.new(math.random(4, 8), math.random(3, 6), math.random(4, 8))
			decoration.Material = Enum.Material.Rock
			decoration.Color = Color3.fromRGB(120, 120, 120)
		end
		
		-- Random position on platform
		local randomX = math.random(-platformSize/2 + 10, platformSize/2 - 10)
		local randomZ = math.random(-platformSize/2 + 10, platformSize/2 - 10)
		decoration.Position = ground.Position + Vector3.new(randomX, ground.Size.Y/2 + decoration.Size.Y/2, randomZ)
		decoration.Anchored = true
		decoration.CanCollide = true
		decoration.Parent = planetModel
	end
	
	-- Add clouds/fog effect for atmosphere
	if data.Biome.Emissive < 0.5 then
		local clouds = Instance.new("ParticleEmitter")
		clouds.Texture = "rbxasset://textures/particles/smoke_main.dds"
		clouds.Color = ColorSequence.new(data.Biome.Color)
		clouds.Size = NumberSequence.new(50)
		clouds.Transparency = NumberSequence.new(0.8)
		clouds.Lifetime = NumberRange.new(10, 20)
		clouds.Rate = 3
		clouds.Speed = NumberRange.new(5, 10)
		clouds.SpreadAngle = Vector2.new(180, 180)
		clouds.Parent = atmosphere
	end
	
	-- Store biome data in attributes for atmosphere controller
	atmosphere:SetAttribute("BiomeName", data.Biome.Name)
	atmosphere:SetAttribute("BiomeEmissive", data.Biome.Emissive)
	atmosphere:SetAttribute("IsHome", data.IsHome or false)
	
	-- Set PrimaryPart
	planetModel.PrimaryPart = atmosphere
	
	-- Add spawn platform if this is the home planet
	if data.IsHome then
		local spawnPlatform = Instance.new("SpawnLocation")
		spawnPlatform.Name = "HomeSpawn"
		spawnPlatform.Size = Vector3.new(20, 2, 20)
		spawnPlatform.Position = ground.Position + Vector3.new(0, ground.Size.Y/2 + 1, 0) -- On top of ground
		spawnPlatform.Anchored = true
		spawnPlatform.CanCollide = true
		spawnPlatform.Material = Enum.Material.Neon
		spawnPlatform.Color = Color3.fromRGB(0, 255, 150)
		spawnPlatform.Transparency = 0.3
		spawnPlatform.Duration = 0
		spawnPlatform.Parent = planetModel
		
		local welcomeSign = Instance.new("Part")
		welcomeSign.Size = Vector3.new(1, 10, 0.5)
		welcomeSign.Position = spawnPlatform.Position + Vector3.new(0, 8, 0)
		welcomeSign.Anchored = true
		welcomeSign.CanCollide = false
		welcomeSign.Material = Enum.Material.Neon
		welcomeSign.Color = Color3.fromRGB(0, 255, 255)
		welcomeSign.Parent = planetModel
		
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(300, 100)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = math.huge -- Always visible no matter how far
		billboard.Parent = welcomeSign
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "◆ HOME PLANET ◆\nPress F to fly"
		label.TextColor3 = Color3.fromRGB(0, 255, 255)
		label.Font = Enum.Font.Code
		label.TextSize = 24
		label.TextStrokeTransparency = 0.5
		label.Parent = billboard
		
		print("🏠 Home planet spawn platform created inside planet at", spawnPlatform.Position)
	end
	
	return planetModel
end

-- Get or create planet at grid coordinates
function PlanetService:GetOrCreatePlanet(gridX, gridY, gridZ)
	local key = gridX .. "_" .. gridY .. "_" .. gridZ
	
	-- Return cached planet if exists
	if ActivePlanets[key] then
		return ActivePlanets[key]
	end
	
	-- Generate new planet data
	local data = self:GeneratePlanetData(gridX, gridY, gridZ)
	if not data then 
		print("❌ No planet at grid", key)
		return nil 
	end
	
	print("✨ Generating planet data at grid", key)
	
	-- Create physical mesh
	local planet = self:CreatePlanetMesh(data)
	planet.Parent = workspace
	
	-- Cache it
	ActivePlanets[key] = {Data = data, Part = planet}
	
	print("🪐 Generated planet at grid", key, "-", data.Biome.Name)
	return ActivePlanets[key]
end

-- Stream planets around a position
function PlanetService:StreamPlanetsNear(position)
	local gridOrigin = Vector3.new(
		math.floor(position.X / PLANET_GRID_SPACING),
		math.floor(position.Y / PLANET_GRID_SPACING),
		math.floor(position.Z / PLANET_GRID_SPACING)
	)
	
	local planets = {}
	local range = 0 -- Only check current grid cell (1 planet at a time)
	
	for x = -range, range do
		for y = -range, range do
			for z = -range, range do
				local gx, gy, gz = gridOrigin.X + x, gridOrigin.Y + y, gridOrigin.Z + z
				local planet = self:GetOrCreatePlanet(gx, gy, gz)
				if planet then
					table.insert(planets, planet.Data)
				end
			end
		end
	end
	
	return planets
end

-- Client RPC to request planets near position
function PlanetService.Client:RequestPlanetsNear(player, position)
	return self.Server:StreamPlanetsNear(position)
end

-- Cleanup planets that are far from ALL players
function PlanetService:CleanupDistantPlanets()
	local Players = game:GetService("Players")
	local activePlayers = Players:GetPlayers()
	
	-- If no players, don't cleanup anything
	if #activePlayers == 0 then return end
	
	local toRemove = {}
	
	for key, planet in pairs(ActivePlanets) do
		-- Never remove home planet
		if planet.Data.IsHome then continue end
		
		local planetPos = planet.Data.WorldPos
		local isNearAnyPlayer = false
		
		-- Check if planet is near ANY player
		for _, player in ipairs(activePlayers) do
			local character = player.Character
			if character then
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					local distance = (planetPos - rootPart.Position).Magnitude
					-- Keep if within cleanup distance (3x render distance)
					if distance <= PLANET_RENDER_DISTANCE * 3 then
						isNearAnyPlayer = true
						break
					end
				end
			end
		end
		
		-- Mark for removal if far from all players
		if not isNearAnyPlayer then
			table.insert(toRemove, key)
		end
	end
	
	-- Remove distant planets
	for _, key in ipairs(toRemove) do
		local planet = ActivePlanets[key]
		if planet and planet.Part then
			planet.Part:Destroy()
			ActivePlanets[key] = nil
			print("🗑️ Cleaned up distant planet at grid", key)
		end
	end
	
	if #toRemove > 0 then
		print("♻️ Cleaned up", #toRemove, "distant planets. Active:", #ActivePlanets)
	end
end

function PlanetService:KnitStart()
	print("🌌 Planet Service Online - Infinite procedural universe ready!")
	print("📊 Config: Grid Spacing=" .. PLANET_GRID_SPACING .. ", Min Size=" .. MIN_PLANET_SIZE .. ", Max Size=" .. MAX_PLANET_SIZE)
	
	-- Create home planet first (always at 0,0,0)
	print("🏠 Creating home planet...")
	local homePlanet = self:GetOrCreatePlanet(0, 0, 0)
	if homePlanet then
		print("✅ Home planet created successfully!")
	end
	
	-- Pre-generate 17 starter planets (home + 16 nearby)
	local count = 1 -- Already have home planet
	local positions = {
		-- 6 faces of cube
		{1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}, {0, 0, 1}, {0, 0, -1},
		-- 8 corners of cube (positive combinations)
		{1, 1, 0}, {1, 0, 1}, {0, 1, 1},
		-- Negative combinations
		{-1, -1, 0}, {-1, 0, -1}, {0, -1, -1},
		-- Mixed combinations
		{1, -1, 0}, {-1, 1, 0}, {1, 0, -1}, {-1, 0, 1}
	}
	
	for _, pos in ipairs(positions) do
		local planet = self:GetOrCreatePlanet(pos[1], pos[2], pos[3])
		if planet then count = count + 1 end
	end
	
	print("✅ Pre-generated " .. count .. " starter planets (home + nearby)")
	
	-- Start periodic cleanup (every 30 seconds)
	task.spawn(function()
		while true do
			task.wait(30)
			self:CleanupDistantPlanets()
		end
	end)
	
	print("♻️ Planet cleanup system active (30s interval, 3x render distance)")
end

return PlanetService
