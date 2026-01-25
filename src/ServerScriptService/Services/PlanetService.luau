local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlanetService = {}

-- Configuration
local PLANET_GRID_SPACING = 3000 -- Distance between planets (increased spacing)
local MIN_PLANET_SIZE = 500
local MAX_PLANET_SIZE = 1500

-- Biome types (metadata only)
local BiomeTypes = {
	-- Desert: vàng cát nhạt (Venus, Mercury)
	{Name = "Desert", Color = Color3.fromRGB(232, 213, 160), Emissive = 0},
	-- Ocean: xanh biển sâu (Earth, Neptune)
	{Name = "Ocean", Color = Color3.fromRGB(36, 104, 160), Emissive = 0},
	-- Ice: xanh băng (Uranus, Pluto)
	{Name = "Ice", Color = Color3.fromRGB(210, 235, 250), Emissive = 0},
	-- Volcanic: đen tro, đỏ cam (Io, núi lửa)
	{Name = "Volcanic", Color = Color3.fromRGB(60, 30, 20), Emissive = 0.35},
	-- Toxic: vàng neon (exoplanet khí độc)
	{Name = "Toxic", Color = Color3.fromRGB(220, 255, 120), Emissive = 0.5},
	-- Crystal: tím lam sáng (giả tưởng)
	{Name = "Crystal", Color = Color3.fromRGB(140, 120, 255), Emissive = 0.7},
	-- Glitch: tím neon (hiệu ứng glitch)
	{Name = "Glitch", Color = Color3.fromRGB(255, 0, 255), Emissive = 1},
	-- Magma: cam đỏ rực (lava planet)
	{Name = "Magma", Color = Color3.fromRGB(255, 80, 20), Emissive = 0.6},
	-- Cloud: trắng xám bạc (Venus, gas giant)
	{Name = "Cloud", Color = Color3.fromRGB(220, 220, 230), Emissive = 0.1},
	-- Copper: đồng đỏ ánh kim (fantasy)
	{Name = "Copper", Color = Color3.fromRGB(184, 115, 51), Emissive = 0.2},
	-- Sapphire: xanh lam ngọc (fantasy)
	{Name = "Sapphire", Color = Color3.fromRGB(15, 82, 186), Emissive = 0.4},
	-- Ruby: đỏ ruby (fantasy)
	{Name = "Ruby", Color = Color3.fromRGB(224, 17, 95), Emissive = 0.5},
	-- Amethyst: tím thạch anh (fantasy)
	{Name = "Amethyst", Color = Color3.fromRGB(153, 102, 204), Emissive = 0.5},
	-- Sandstone: vàng cam nhạt (sao Hỏa, sa mạc)
	{Name = "Sandstone", Color = Color3.fromRGB(237, 201, 175), Emissive = 0.1},
	-- Midnight: xanh đen vũ trụ (deep space)
	{Name = "Midnight", Color = Color3.fromRGB(20, 24, 82), Emissive = 0.2}
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
	{
		Brightness = 1.2, BloomIntensity = 0.08, BloomSize = 24, BloomThreshold = 1.3,
		Ambient = {R=30/255, G=30/255, B=40/255},
		OutdoorAmbient = {R=40/255, G=40/255, B=50/255},
		EnvironmentDiffuseScale = 1.1,
		EnvironmentSpecularScale = 0.35,
		ColorCorrection = {
			Brightness = 0.1, Contrast = 0.03, Saturation = -0.05, TintColor = {R=240/255, G=240/255, B=255/255}
		}
	},
	{
		Brightness = 1.4, BloomIntensity = 0.12, BloomSize = 36, BloomThreshold = 1.1,
		Ambient = {R=25/255, G=25/255, B=35/255},
		OutdoorAmbient = {R=35/255, G=35/255, B=45/255},
		EnvironmentDiffuseScale = 1.1,
		EnvironmentSpecularScale = 0.35,
		ColorCorrection = {
			Brightness = 0.12, Contrast = 0.04, Saturation = -0.07, TintColor = {R=235/255, G=235/255, B=250/255}
		}
	},
	{
		Brightness = 1.0, BloomIntensity = 0.05, BloomSize = 16, BloomThreshold = 1.5,
		Ambient = {R=20/255, G=20/255, B=30/255},
		OutdoorAmbient = {R=30/255, G=30/255, B=40/255},
		EnvironmentDiffuseScale = 1.1,
		EnvironmentSpecularScale = 0.35,
		ColorCorrection = {
			Brightness = 0.08, Contrast = 0.02, Saturation = -0.09, TintColor = {R=230/255, G=230/255, B=245/255}
		}
	},
	{
		Brightness = 1.3, BloomIntensity = 0.09, BloomSize = 32, BloomThreshold = 1.2,
		Ambient = {R=28/255, G=28/255, B=38/255},
		OutdoorAmbient = {R=38/255, G=38/255, B=48/255},
		EnvironmentDiffuseScale = 1.1,
		EnvironmentSpecularScale = 0.35,
		ColorCorrection = {
			Brightness = 0.11, Contrast = 0.03, Saturation = -0.06, TintColor = {R=238/255, G=238/255, B=252/255}
		}
	},
	{
		Brightness = 1.1, BloomIntensity = 0.13, BloomSize = 40, BloomThreshold = 1.0,
		Ambient = {R=22/255, G=22/255, B=32/255},
		OutdoorAmbient = {R=32/255, G=32/255, B=42/255},
		EnvironmentDiffuseScale = 1.1,
		EnvironmentSpecularScale = 0.35,
		ColorCorrection = {
			Brightness = 0.09, Contrast = 0.025, Saturation = -0.08, TintColor = {R=232/255, G=232/255, B=248/255}
		}
	},
}

local function PickRandomBloomPreset(seed, biomeName)
	-- Map biome name to preset index (ưu tiên màu sắc/ánh sáng phù hợp)
	local biomePresetMap = {
		Desert = 1,
		Ocean = 2,
		Ice = 3,
		Volcanic = 4,
		Toxic = 5,
		Crystal = 2,
		Glitch = 5,
		Magma = 4,
		Cloud = 1,
		Copper = 1,
		Sapphire = 2,
		Ruby = 4,
		Amethyst = 5,
		Sandstone = 1,
		Midnight = 3
	}
	local presetIdx = biomePresetMap[biomeName or ""]
	if presetIdx then
		-- Vẫn random nhẹ quanh preset chính
		local offset = math.floor(SeededRandom(seed+999, -1, 1.99))
		local idx = math.clamp((presetIdx or 1) + offset, 1, #BLOOM_PRESETS)
		return BLOOM_PRESETS[idx] or BLOOM_PRESETS[1]
	else
		local idx = math.floor(SeededRandom(seed, 1, #BLOOM_PRESETS + 0.99))
		return BLOOM_PRESETS[idx] or BLOOM_PRESETS[1]
	end
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
		if not self._homePlanetDebugPrinted then
			print("[DEBUG][SERVER] GeneratePlanetData(0,0,0) called")
			self._homePlanetDebugPrinted = true
		end
	end
	local seed = gridX * 73856093 + gridY * 19349663 + gridZ * 83492791

	-- Home planet at 0,0,0, always at center
	-- Always generate ground tiles for every planet
	local isHome = (gridX == 0 and gridY == 0 and gridZ == 0)
	local biome, skyPresetName, bloomPreset, surfaceType, size, worldPos
			if isHome then
				biome = BiomeTypes[3]
				skyPresetName = PickRandomSkyName(seed)
				bloomPreset = PickRandomBloomPreset(seed, biome.Name)
				surfaceType = PickRandomSurfaceType(seed)
				size = 500
				-- Center home planet at (0, HOME_PLANET_HEIGHT, 0)
				-- Both ground and atmosphere will use this Y
				worldPos = {X = 0, Y = HOME_PLANET_HEIGHT, Z = 0}
			else
				size = SeededRandom(seed + 1, MIN_PLANET_SIZE, MAX_PLANET_SIZE)
				local biomeIndex = math.floor(SeededRandom(seed + 2, 1, #BiomeTypes + 0.99))
				biome = BiomeTypes[biomeIndex]
				skyPresetName = PickRandomSkyName(seed)
				bloomPreset = PickRandomBloomPreset(seed, biome.Name)
				surfaceType = PickRandomSurfaceType(seed)
				-- Calculate world position
				local baseX = gridX * PLANET_GRID_SPACING
				local baseY = gridY * PLANET_GRID_SPACING
				local baseZ = gridZ * PLANET_GRID_SPACING
				local offsetX = SeededRandom(seed + 3, -500, 500)
				local offsetY = SeededRandom(seed + 4, -500, 500)
				local offsetZ = SeededRandom(seed + 5, -500, 500)
				worldPos = {
					X = baseX + offsetX,
					Y = baseY + offsetY,
					Z = baseZ + offsetZ
				}
			end

		       -- Generate ground tiles centered at WorldPos (groundY = worldPos.Y)
			       local tileSize = 32
				local groundDiameter = size * 0.4 -- ground is 40% of atmosphere diameter
			       local numTiles = math.floor(groundDiameter / tileSize)
			       local groundTiles = {}
			       local groundY = worldPos.Y
			       local startX = worldPos.X - groundDiameter/2 + tileSize/2
			       local startZ = worldPos.Z - groundDiameter/2 + tileSize/2
				   for x = 0, numTiles - 1 do
					   for z = 0, numTiles - 1 do
						   local tileSeed = seed + x * 1009 + z * 9176 + 99999
						   -- Mỏng hơn, Y=3
						   local tileY = 3
						   -- Random offset Y nhỏ hơn độ dày (Y=3), tránh lồi lõm quá mức
						   local yOffset = SeededRandom(tileSeed, -1.2, 1.2)
						   table.insert(groundTiles, {
							   Size = {X = tileSize, Y = tileY, Z = tileSize},
							   Position = {
								   X = startX + x * tileSize,
								   Y = groundY + yOffset,
								   Z = startZ + z * tileSize
							   },
							   Color = {R = biome.Color.R, G = biome.Color.G, B = biome.Color.B},
							   TopSurface = "Studs",
							   BottomSurface = "Studs"
						   })
					   end
				   end

	-- Generate tree/rock objects for all planets except home (deterministic by seed, sent to client)
	local objects = {}
	if not isHome then
		local totalTiles = numTiles * numTiles
		-- Mật độ biến thiên nhẹ theo seed để không đều
		local densitySeed = seed % 10000
		local treeDensity = math.clamp(math.floor(totalTiles * (0.7 + SeededRandom(densitySeed, 0, 0.2))), 24, 300)
		local rockDensity = math.clamp(math.floor(totalTiles * (0.5 + SeededRandom(densitySeed+123, 0, 0.2))), 12, 220)
		local treeChance = treeDensity / totalTiles
		local rockChance = rockDensity / totalTiles
		-- Đảm bảo không trùng vị trí cây/đá bằng cách dùng map
		local objectMap = {}
		for x = 0, numTiles - 1 do
			for z = 0, numTiles - 1 do
				local tileSeed = seed + x * 1009 + z * 9176
				-- Random offset trong tile để không đều lưới
				local offsetX = SeededRandom(tileSeed + 500, -tileSize*0.35, tileSize*0.35)
				local offsetZ = SeededRandom(tileSeed + 1000, -tileSize*0.35, tileSize*0.35)
				local posX = startX + x * tileSize + offsetX
				local posY = groundY
				local posZ = startZ + z * tileSize + offsetZ
				local key = tostring(math.floor(posX*10))..","..tostring(math.floor(posZ*10))
				local randTree = SeededRandom(tileSeed, 0, 1)
				local randRock = SeededRandom(tileSeed + 12345, 0, 1)
				if randTree < treeChance then
					local treeType = tostring(math.clamp(math.floor(SeededRandom(tileSeed + 20000, 1, 5.99)), 1, 5))
					local rotY = SeededRandom(tileSeed + 30000, 0, 360)
					local scale = 0.85 + SeededRandom(tileSeed + 40000, 0, 0.3)
					table.insert(objects, {
						Type = "Tree",
						Model = treeType,
						PosX = posX,
						PosY = posY,
						PosZ = posZ,
						RotY = rotY,
						Scale = scale
					})
					objectMap[key] = true
				elseif randRock < rockChance and not objectMap[key] then
					local rockType = tostring(math.clamp(math.floor(SeededRandom(tileSeed + 30000, 1, 5.99)), 1, 5))
					local rotY = SeededRandom(tileSeed + 35000, 0, 360)
					local scale = 0.85 + SeededRandom(tileSeed + 45000, 0, 0.3)
					-- Đá nổi lên mặt đất một chút (cao hơn cây)
					local rockYOffset = 4 + SeededRandom(tileSeed + 46000, 0, 2) -- 4~6 studs
					table.insert(objects, {
						Type = "Rock",
						Model = rockType,
						PosX = posX,
						PosY = posY + rockYOffset,
						PosZ = posZ,
						RotY = rotY,
						Scale = scale
					})
					objectMap[key] = true
				end
			end
		end
	end

	-- 90% chance to have a planet (skip for home)
	if not isHome and SeededRandom(seed) > 0.9 then
		return nil
	end

	-- Prevent planets from spawning too close to destroy height (skip for home)
	if not isHome then
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
			return nil
		end
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
		       IsHome = isHome,
		       SkyPresetName = skyPresetName,
		       Bloom = bloomPreset,
		       SurfaceType = surfaceType,
		       Objects = objects,
		       GroundTiles = groundTiles
	       }
end

-- Get planets near a position (returns metadata only)
function PlanetService:GetPlanetsNearPosition(position)
	-- Luôn trả về 20 planet gần nhất quanh gốc toạ độ (0, HOME_PLANET_HEIGHT, 0)
	local centerX, centerY, centerZ = 0, HOME_PLANET_HEIGHT, 0
	local gridOriginX = 0
	local gridOriginY = 0
	local gridOriginZ = 0
	local planets = {}
	local range = 2 -- 5x5x5 grid quanh gốc
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
	-- Sort planets by distance to gốc toạ độ
	table.sort(planets, function(a, b)
		local da = (a.WorldPos.X - centerX)^2 + (a.WorldPos.Y - centerY)^2 + (a.WorldPos.Z - centerZ)^2
		local db = (b.WorldPos.X - centerX)^2 + (b.WorldPos.Y - centerY)^2 + (b.WorldPos.Z - centerZ)^2
		return da < db
	end)
	-- Giữ lại 20 planet gần nhất
	while #planets > 20 do
		table.remove(planets)
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
	-- Classic baseplate: grid of larger Parts (16x16 studs)
	local tileSize = 32
	local groundHeight = 4
	local numTiles = math.floor(planetData.Size / tileSize)
	local startPos = planetData.Position + Vector3.new(-planetData.Size/2 + tileSize/2, -10, -planetData.Size/2 + tileSize/2)
	local groundFolder = Instance.new("Folder")
	groundFolder.Name = "GroundTiles"
	groundFolder.Parent = parent
	local surfaceType = planetData.SurfaceType or Enum.SurfaceType.Studs

	-- Lấy danh sách model cây và đá từ ReplicatedStorage
	local treesFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Trees")
	local rocksFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Rocks")
	local treeModels = {}
	local rockModels = {}
	if treesFolder then
		for _, obj in ipairs(treesFolder:GetChildren()) do
			if obj:IsA("Model") then table.insert(treeModels, obj) end
		end
	end
	if rocksFolder then
		for _, obj in ipairs(rocksFolder:GetChildren()) do
			if obj:IsA("Model") then table.insert(rockModels, obj) end
		end
	end

	-- Mật độ: trung bình 1 cây/đá mỗi 12-20 tile (tùy size planet)
	local totalTiles = numTiles * numTiles
	local treeDensity = math.clamp(math.floor(totalTiles / 2), 18, 160) -- even more trees
	local rockDensity = math.clamp(math.floor(totalTiles / 3), 12, 120) -- even more rocks
	local treeChance = treeDensity / totalTiles
	local rockChance = rockDensity / totalTiles

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

			-- Random cây
			if #treeModels > 0 and math.random() < treeChance then
				local treeTemplate = treeModels[math.random(1, #treeModels)]
				local tree = treeTemplate:Clone()
				tree.Name = "Tree"
				-- Đặt gốc cây lên tile
				if tree.PrimaryPart then
					tree:SetPrimaryPartCFrame(tile.CFrame * CFrame.new(0, tile.Size.Y/2 + tree.PrimaryPart.Size.Y/2, 0) * CFrame.Angles(0, math.rad(math.random(0,359)), 0))
				else
					tree.Parent = tile
					tree:SetPrimaryPartCFrame(tile.CFrame)
				end
				tree.Parent = tile
			end
			-- Random đá
			if #rockModels > 0 and math.random() < rockChance then
				local rockTemplate = rockModels[math.random(1, #rockModels)]
				local rock = rockTemplate:Clone()
				rock.Name = "Rock"
				if rock.PrimaryPart then
					rock:SetPrimaryPartCFrame(tile.CFrame * CFrame.new(0, tile.Size.Y/2 + rock.PrimaryPart.Size.Y/2, 0) * CFrame.Angles(0, math.rad(math.random(0,359)), 0))
				else
					rock.Parent = tile
					rock:SetPrimaryPartCFrame(tile.CFrame)
				end
				rock.Parent = tile
			end
		end
	end
	return groundFolder
end

return PlanetService
