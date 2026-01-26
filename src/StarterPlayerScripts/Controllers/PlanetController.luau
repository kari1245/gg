local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Promise = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Promise"))

local PlanetController = {}
local RenderedPlanets = {}
local AtmosphereState = { InAtmosphere = false, CurrentPlanetKey = nil }
local CachedPlanets = {} 

local currentFetchPromise = nil
local activeLightingTweens = {}
local TWEEN_INFO_LIGHTING = TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local DEFAULT_SKY_NAME = "Space"
local DEFAULT_LIGHTING = {
	Brightness = 1.5,
	Ambient = Color3.fromRGB(10,10,20),
	OutdoorAmbient = Color3.fromRGB(20,20,30),
	EnvironmentDiffuseScale = 1.1,
	EnvironmentSpecularScale = 0.35,
	Bloom = { Intensity = 0.08, Size = 24, Threshold = 1.3 },
	ColorCorrection = { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1,1,1) }
}

local function toColor(t)
	if typeof(t) == "Color3" then return t end
	return Color3.new(t.R, t.G, t.B)
end

local function cancelActiveTweens()
	for _, tween in pairs(activeLightingTweens) do
		if tween and tween.Cancel then tween:Cancel() end
	end
	activeLightingTweens = {}
end

local function tweenProperty(instance, properties)
	local tween = TweenService:Create(instance, TWEEN_INFO_LIGHTING, properties)
	table.insert(activeLightingTweens, tween)
	tween:Play()
end

local function UpdateLightingEffects(targetConfig)
	cancelActiveTweens()
	tweenProperty(Lighting, {
		Brightness = targetConfig.Brightness or DEFAULT_LIGHTING.Brightness,
		Ambient = targetConfig.Ambient and toColor(targetConfig.Ambient) or DEFAULT_LIGHTING.Ambient,
		OutdoorAmbient = targetConfig.OutdoorAmbient and toColor(targetConfig.OutdoorAmbient) or DEFAULT_LIGHTING.OutdoorAmbient,
		EnvironmentDiffuseScale = targetConfig.EnvironmentDiffuseScale or DEFAULT_LIGHTING.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = targetConfig.EnvironmentSpecularScale or DEFAULT_LIGHTING.EnvironmentSpecularScale
	})
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
	local ccConf = targetConfig.ColorCorrection or DEFAULT_LIGHTING.ColorCorrection
	tweenProperty(cc, {
		Brightness = ccConf.Brightness or 0,
		Contrast = ccConf.Contrast or 0,
		Saturation = ccConf.Saturation or 0,
		TintColor = ccConf.TintColor and toColor(ccConf.TintColor) or Color3.new(1,1,1)
	})
	local bloomFx = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
	local bloomConf = targetConfig.Bloom or DEFAULT_LIGHTING.Bloom
	tweenProperty(bloomFx, {
		Intensity = bloomConf.Intensity or 0,
		Size = bloomConf.Size or 0,
		Threshold = bloomConf.Threshold or 0
	})
end

local function applySky(skyName)
	local currentSky = Lighting:FindFirstChildOfClass("Sky")
	if currentSky and currentSky.Name == skyName then return end
	for _, obj in ipairs(Lighting:GetChildren()) do if obj:IsA("Sky") then obj:Destroy() end end
	local skies = ReplicatedStorage:FindFirstChild("Skies")
	local targetName = (skyName and skyName ~= "") and skyName or "space"
	if skies then
		local sky = skies:FindFirstChild(targetName) or skies:FindFirstChild("space")
		if sky then sky:Clone().Parent = Lighting end
	end
end

-- RENDER ATMOSPHERE (SPACE MODE)
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
	return model
end

-- RENDER FULL PLANET (GROUND MODE)
local function CreatePlanetModel(data)
	local model = Instance.new("Model")
	model.Name = "Planet_" .. data.GridPos.X .. "_" .. data.GridPos.Y .. "_" .. data.GridPos.Z
	
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
				if clone:IsA("Model") then
					if clone:IsA("Model") then
						clone:PivotTo(cf)
					else
						clone.CFrame = cf
					end
				else
					clone.CFrame = cf
				end
			else
				clone.CFrame = cf
			end
			clone.Parent = objectsFolder
		end
	end
	return model
end

-- CHECK IF INSIDE ATMOSPHERE
local function getCurrentPlanetInAtmosphere(planets, playerPos)
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
		-- [LOGIC] Vào trong bán kính = Atmosphere. Ra ngoài = Space.
		if minDst < radius then 
			return nearest 
		end
	end
	return nil
end

local lastPlanetKey = nil

-- RENDER STATE MACHINE
function RenderPlanetsFromServer(planets)
	CachedPlanets = planets 
	local player = Players.LocalPlayer
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local playerPos = root.Position
	local inPlanet = getCurrentPlanetInAtmosphere(planets, playerPos)
	
	local planetByKey = {}
	for _, data in ipairs(planets) do
		planetByKey[data.GridPos.X .. "_" .. data.GridPos.Y .. "_" .. data.GridPos.Z] = data
	end

	local newPlanetKey = inPlanet and (inPlanet.GridPos.X .. "_" .. inPlanet.GridPos.Y .. "_" .. inPlanet.GridPos.Z) or nil
	AtmosphereState.InAtmosphere = (inPlanet ~= nil)
	AtmosphereState.CurrentPlanetKey = newPlanetKey

	local function clearRenderedExcept(keepKey)
		for key, model in pairs(RenderedPlanets) do
			if key ~= keepKey then
				if model then model:Destroy() end
				RenderedPlanets[key] = nil
			end
		end
	end

	if AtmosphereState.InAtmosphere then
		-- TRẠNG THÁI: TRONG HÀNH TINH (RENDER FULL)
		if lastPlanetKey ~= newPlanetKey then
			local data = planetByKey[newPlanetKey]
			if data then
				local newModel = CreatePlanetModel(data)
				newModel.Parent = workspace
				if RenderedPlanets[newPlanetKey] then RenderedPlanets[newPlanetKey]:Destroy() end
				RenderedPlanets[newPlanetKey] = newModel
				clearRenderedExcept(newPlanetKey)
				local targetConfig = { Bloom = data.Bloom }
				UpdateLightingEffects(targetConfig)
				applySky(data.SkyPresetName)
			end
			lastPlanetKey = newPlanetKey
		end
	else
		-- TRẠNG THÁI: NGOÀI VŨ TRỤ (RENDER ATMOSPHERE)
		if lastPlanetKey ~= "_space_" then
			for key, model in pairs(RenderedPlanets) do model:Destroy() RenderedPlanets[key] = nil end
			for key, data in pairs(planetByKey) do
				local m = CreateAtmosphereOnlyModel(data)
				m.Parent = workspace
				RenderedPlanets[key] = m
			end
			UpdateLightingEffects(DEFAULT_LIGHTING)
			applySky(DEFAULT_SKY_NAME)
			lastPlanetKey = "_space_"
		else
			for key, data in pairs(planetByKey) do
				if not RenderedPlanets[key] then
					local m = CreateAtmosphereOnlyModel(data)
					m.Parent = workspace
					RenderedPlanets[key] = m
				end
			end
		end
	end
end

local function FetchPlanetsFromServer()
	local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes") 
	local GetPlanetsRemote = RemotesFolder:WaitForChild("GetPlanetsRemote")
	if currentFetchPromise then currentFetchPromise:cancel() end
	currentFetchPromise = Promise.new(function(resolve, reject, onCancel)
		local data = GetPlanetsRemote:InvokeServer()
		if data then resolve(data) else reject("No data") end
	end)
	return currentFetchPromise
end

function PlanetController.Init()
	local function HandleCharacterSpawn(char)
		local root = char:WaitForChild("HumanoidRootPart")
		root.Anchored = true
		
		-- Lấy dữ liệu với Retry
		Promise.retryWithDelay(function()
			return FetchPlanetsFromServer():andThen(function(planets)
				if not planets or #planets == 0 then return Promise.reject("Empty") end
				return planets
			end)
		end, 20, 0.5)
		:andThen(function(planets)
			CachedPlanets = planets
			
			if #planets > 0 then
				local randomPlanet = planets[math.random(1, #planets)]
				local key = randomPlanet.GridPos.X .. "_" .. randomPlanet.GridPos.Y .. "_" .. randomPlanet.GridPos.Z
				
				if randomPlanet.WorldPos and randomPlanet.Size then
					local radius = randomPlanet.Size / 2
					-- DROP TỪ NGOÀI VŨ TRỤ (Cao hơn đỉnh 200 studs)
					local dropHeight = radius + 200
					
					root.CFrame = CFrame.new(randomPlanet.WorldPos.X, randomPlanet.WorldPos.Y + dropHeight, randomPlanet.WorldPos.Z)
					
					-- PRE-RENDER SPACE MODE (Bắt buộc vì đang ở ngoài)
					if RenderedPlanets[key] then RenderedPlanets[key]:Destroy() end
					local model = CreateAtmosphereOnlyModel(randomPlanet)
					model.Parent = workspace
					RenderedPlanets[key] = model
					
					-- FORCE STATE: SPACE
					AtmosphereState.InAtmosphere = false
					lastPlanetKey = "_space_"
					UpdateLightingEffects(DEFAULT_LIGHTING)
					applySky(DEFAULT_SKY_NAME)
					
					print("Orbital Drop initialized at:", key)
				end
				
				task.wait(1.0)
				if root then root.Anchored = false end
			else
				warn("No planets found for spawn")
				if root then root.Anchored = false end
			end
		end)
		:catch(function(err) warn(err) if root then root.Anchored = false end end)
	end

	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(HandleCharacterSpawn)
	if player.Character then task.spawn(function() HandleCharacterSpawn(player.Character) end) end

	-- NETWORK LOOP
	task.defer(function()
		local lastPos = Vector3.new(0, -999999, 0)
		local UPDATE_THRESHOLD = 100 
		while true do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and not root.Anchored then
				if (root.Position - lastPos).Magnitude > UPDATE_THRESHOLD then
					FetchPlanetsFromServer():andThen(function(newPlanets)
						CachedPlanets = newPlanets
						lastPos = root.Position
					end):catch(function() end)
				end
			end
			task.wait(0.5)
		end
	end)

	-- RENDER LOOP (Mượt mà)
	RunService.Heartbeat:Connect(function()
		if CachedPlanets and #CachedPlanets > 0 then
			RenderPlanetsFromServer(CachedPlanets)
		end
	end)
end

return PlanetController