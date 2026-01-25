local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local PlanetController = {}
local RenderedPlanets = {}
local AtmosphereState = { InAtmosphere = false, CurrentPlanetKey = nil }

-- Constants
local DEFAULT_SKY_NAME = "Space"
local DEFAULT_LIGHTING = {
	Brightness = 1.5,
	Ambient = Color3.fromRGB(10,10,20),
	OutdoorAmbient = Color3.fromRGB(20,20,30),
	EnvironmentDiffuseScale = 1.1,
	EnvironmentSpecularScale = 0.35,
}

local function applyLightingConfig(bloom)
	if not bloom then bloom = {} end
	Lighting.Brightness = bloom.Brightness or DEFAULT_LIGHTING.Brightness
	Lighting.Ambient = bloom.Ambient and Color3.new(bloom.Ambient.R, bloom.Ambient.G, bloom.Ambient.B) or DEFAULT_LIGHTING.Ambient
	Lighting.OutdoorAmbient = bloom.OutdoorAmbient and Color3.new(bloom.OutdoorAmbient.R, bloom.OutdoorAmbient.G, bloom.OutdoorAmbient.B) or DEFAULT_LIGHTING.OutdoorAmbient
	Lighting.EnvironmentDiffuseScale = bloom.EnvironmentDiffuseScale or DEFAULT_LIGHTING.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = bloom.EnvironmentSpecularScale or DEFAULT_LIGHTING.EnvironmentSpecularScale
	
	-- ColorCorrection
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
	local ccConf = bloom.ColorCorrection or {}
	cc.Brightness = ccConf.Brightness or 0
	cc.Contrast = ccConf.Contrast or 0
	cc.Saturation = ccConf.Saturation or 0
	cc.TintColor = ccConf.TintColor and Color3.new(ccConf.TintColor.R, ccConf.TintColor.G, ccConf.TintColor.B) or Color3.new(1,1,1)

	-- Bloom
	local bloomFx = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
	bloomFx.Intensity = bloom.BloomIntensity or 0.08
	bloomFx.Size = bloom.BloomSize or 24
	bloomFx.Threshold = bloom.BloomThreshold or 1.3
end

local function applySky(skyName)
	for _, obj in ipairs(Lighting:GetChildren()) do if obj:IsA("Sky") then obj:Destroy() end end
	local skies = ReplicatedStorage:FindFirstChild("Skies")
	local targetName = (skyName and skyName ~= "") and skyName or "space"
	
	if skies then
		local sky = skies:FindFirstChild(targetName) or skies:FindFirstChild("space")
		if sky then sky:Clone().Parent = Lighting end
	end
end

local function CreateAtmosphereOnlyModel(data)
	local model = Instance.new("Model")
	model.Name = "PlanetAtmosphere_" .. data.GridPos.X .. "_" .. data.GridPos.Y .. "_" .. data.GridPos.Z
	
	local atmosphere = Instance.new("Part")
	atmosphere.Name = "Atmosphere"
	atmosphere.Size = Vector3.new(data.Size, data.Size, data.Size)
	atmosphere.Position = Vector3.new(data.WorldPos.X, data.WorldPos.Y, data.WorldPos.Z)
	atmosphere.Anchored = true
	atmosphere.CanCollide = false
	atmosphere.Material = Enum.Material.Neon
	atmosphere.Color = Color3.new(data.Biome.Color.R, data.Biome.Color.G, data.Biome.Color.B)
	atmosphere.Shape = Enum.PartType.Ball
	atmosphere.CastShadow = false
	pcall(function() atmosphere.LocalTransparencyModifier = 0 end)
	atmosphere.Parent = model
	
	model.Parent = workspace
	return model
end

local function CreatePlanetModel(data)
	local model = Instance.new("Model")
	model.Name = "Planet_" .. data.GridPos.X .. "_" .. data.GridPos.Y .. "_" .. data.GridPos.Z
	
	-- Atmosphere
	local atmosphere = Instance.new("Part")
	atmosphere.Name = "Atmosphere"
	atmosphere.Size = Vector3.new(data.Size, data.Size, data.Size)
	atmosphere.Position = Vector3.new(data.WorldPos.X, data.WorldPos.Y, data.WorldPos.Z)
	atmosphere.Anchored = true
	atmosphere.CanCollide = false
	atmosphere.Material = Enum.Material.Neon
	atmosphere.Color = Color3.new(data.Biome.Color.R, data.Biome.Color.G, data.Biome.Color.B)
	atmosphere.Shape = Enum.PartType.Ball
	atmosphere.CastShadow = false
	pcall(function() atmosphere.LocalTransparencyModifier = 0 end)
	atmosphere.Parent = model

	-- Ground
	local groundFolder = Instance.new("Folder", model)
	groundFolder.Name = "GroundTiles"
	if data.GroundTiles then
		for _, tileData in ipairs(data.GroundTiles) do
			local tile = Instance.new("Part")
			tile.Name = "Tile"
			tile.Anchored = true
			tile.Material = Enum.Material.Plastic
			tile.Size = Vector3.new(tileData.Size.X, tileData.Size.Y, tileData.Size.Z)
			tile.Position = Vector3.new(tileData.Position.X, tileData.Position.Y, tileData.Position.Z)
			tile.Color = Color3.new(tileData.Color.R, tileData.Color.G, tileData.Color.B)
			tile.TopSurface = tileData.TopSurface == "Studs" and Enum.SurfaceType.Studs or Enum.SurfaceType.Smooth
			tile.BottomSurface = tileData.BottomSurface == "Studs" and Enum.SurfaceType.Studs or Enum.SurfaceType.Smooth
			tile.Parent = groundFolder
		end
	end

	-- Objects
	local objectsFolder = Instance.new("Folder", model)
	objectsFolder.Name = "Objects"
	local treesFolder = ReplicatedStorage:FindFirstChild("Trees")
	local rocksFolder = ReplicatedStorage:FindFirstChild("Rocks")
	
	if data.Objects then
		for _, obj in ipairs(data.Objects) do
			local template = nil
			if obj.Type == "Tree" and treesFolder then template = treesFolder:FindFirstChild(obj.Model) end
			if obj.Type == "Rock" and rocksFolder then template = rocksFolder:FindFirstChild(obj.Model) end
			
			local clone
			if template then
				clone = template:Clone()
			else
				clone = Instance.new("Part")
				clone.Size = Vector3.new(8, 16, 8)
				clone.Color = obj.Type == "Tree" and Color3.fromRGB(34, 139, 34) or Color3.fromRGB(120, 120, 120)
			end
			
			clone.Name = obj.Type
			local cf = CFrame.new(obj.PosX, obj.PosY, obj.PosZ) * CFrame.Angles(0, math.rad(obj.RotY or 0), 0) * CFrame.new(0, (clone:IsA("Model") and 0 or clone.Size.Y/2), 0)
			
			if clone:IsA("Model") then
				if clone.PrimaryPart then clone:SetPrimaryPartCFrame(cf) else clone:SetPrimaryPartCFrame(cf) end
			else
				clone.CFrame = cf
			end
			clone.Parent = objectsFolder
		end
	end
	
	model.Parent = workspace
	return model
end

local function getCurrentPlanetInAtmosphere(planets, playerPos)
	-- Check nearest planet first
	local nearest = nil
	local minDst = math.huge
	
	for _, data in ipairs(planets) do
		local center = Vector3.new(data.WorldPos.X, data.WorldPos.Y, data.WorldPos.Z)
		local dist = (playerPos - center).Magnitude
		if dist < minDst then
			minDst = dist
			nearest = data
		end
	end
	
	if nearest then
		local radius = nearest.Size / 2
		if minDst < radius then return nearest end
	end
	return nil
end

local lastPlanetKey = nil

function RenderPlanetsFromServer(planets)
	local player = Players.LocalPlayer
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local playerPos = root.Position
	local inPlanet = getCurrentPlanetInAtmosphere(planets, playerPos)
	
	-- Map keys
	local planetByKey = {}
	for _, data in ipairs(planets) do
		planetByKey[data.GridPos.X .. "_" .. data.GridPos.Y .. "_" .. data.GridPos.Z] = data
	end

	local newPlanetKey = inPlanet and (inPlanet.GridPos.X .. "_" .. inPlanet.GridPos.Y .. "_" .. inPlanet.GridPos.Z) or nil
	AtmosphereState.InAtmosphere = (inPlanet ~= nil)
	AtmosphereState.CurrentPlanetKey = newPlanetKey

	local function clearRendered()
		for key, model in pairs(RenderedPlanets) do
			if model then model:Destroy() end
			RenderedPlanets[key] = nil
		end
	end

	-- State Switching
	if AtmosphereState.InAtmosphere then
		-- Inside a planet
		if lastPlanetKey ~= newPlanetKey then
			clearRendered()
			local data = planetByKey[newPlanetKey]
			if data then
				RenderedPlanets[newPlanetKey] = CreatePlanetModel(data)
				applyLightingConfig(data.Bloom)
				applySky(data.SkyPresetName)
			end
			lastPlanetKey = newPlanetKey
		end
	else
		-- In Space
		if lastPlanetKey ~= "_space_" then
			clearRendered()
			for key, data in pairs(planetByKey) do
				RenderedPlanets[key] = CreateAtmosphereOnlyModel(data)
			end
			applyLightingConfig(nil)
			applySky(DEFAULT_SKY_NAME)
			lastPlanetKey = "_space_"
		else
			-- Update space view
			for key, data in pairs(planetByKey) do
				if not RenderedPlanets[key] then
					RenderedPlanets[key] = CreateAtmosphereOnlyModel(data)
				end
			end
		end
	end
end

function PlanetController.Init()
	local GetPlanetsRemote = ReplicatedStorage:WaitForChild("GetPlanetsRemote")
	
	-- Teleport Helper
	local function teleportToHome(char, homeData)
		if not char or not homeData then return end
		local root = char:WaitForChild("HumanoidRootPart")
		local tile = homeData.GroundTiles and homeData.GroundTiles[1]
		if tile then
			root.CFrame = CFrame.new(tile.Position.X, tile.Position.Y + 5, tile.Position.Z)
		else
			root.CFrame = CFrame.new(homeData.WorldPos.X, homeData.WorldPos.Y + 10, homeData.WorldPos.Z)
		end
	end

	task.defer(function()
		local player = Players.LocalPlayer
		local char = player.Character or player.CharacterAdded:Wait()
		
		-- Initial Load
		-- Client passes (0,0,0) as a guess, but uses whatever server returns
		local success, planets = pcall(function() return GetPlanetsRemote:InvokeServer(Vector3.new(0, 0, 0)) end)
		if success and planets then
			local homeData
			for _, p in ipairs(planets) do
				if p.IsHome then
					homeData = p
					break 
				end
			end
			if homeData then teleportToHome(char, homeData) end
		end

		player.CharacterAdded:Connect(function(newChar)
			-- Logic respawn/teleport if needed
		end)

		-- Main Render Loop
		while true do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local ok, newPlanets = pcall(function() return GetPlanetsRemote:InvokeServer(root.Position) end)
				if ok and newPlanets then
					RenderPlanetsFromServer(newPlanets)
				end
			end
			task.wait(1) 
		end
	end)
end

return PlanetController