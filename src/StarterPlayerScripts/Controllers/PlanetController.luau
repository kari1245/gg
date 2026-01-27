local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- [FIX 1] Cast Knit to any to prevent 'KnitServer' inference on client
local Knit = require(ReplicatedStorage.Packages.Knit) :: any
local Promise = require(ReplicatedStorage.Packages.Promise)

-- [TYPES]
type PlanetData = {
	GridPos: {X: number, Y: number, Z: number},
	WorldPos: {X: number, Y: number, Z: number},
	Size: number,
	Biome: {Name: string, Color: {R: number, G: number, B: number}, Emissive: number},
	Seed: number,
	SkyPresetName: string,
	Bloom: {Brightness: number?, BloomIntensity: number?, BloomSize: number?, BloomThreshold: number?, Intensity: number?, Size: number?, Threshold: number?},
	Objects: {any},
	GroundTiles: {any},
	IsHome: boolean
}

type ColorCorrectionConfig = {
	Brightness: number?, 
	Contrast: number?, 
	Saturation: number?, 
	TintColor: Color3?
}

type BloomConfig = {
	Intensity: number?, 
	Size: number?, 
	Threshold: number?, 
	BloomIntensity: number?, 
	BloomSize: number?, 
	BloomThreshold: number?
}

type LightingConfig = {
	Brightness: number?,
	Ambient: Color3?,
	OutdoorAmbient: Color3?,
	EnvironmentDiffuseScale: number?,
	EnvironmentSpecularScale: number?,
	Bloom: BloomConfig?,
	ColorCorrection: ColorCorrectionConfig?
}

-- [CONSTANTS]
local UPDATE_THRESHOLD = 100 
local TWEEN_INFO_LIGHTING = TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local DEFAULT_SKY_NAME = "Space"

local DEFAULT_LIGHTING: LightingConfig = {
	Brightness = 1.5,
	Ambient = Color3.fromRGB(10,10,20),
	OutdoorAmbient = Color3.fromRGB(20,20,30),
	EnvironmentDiffuseScale = 1.1,
	EnvironmentSpecularScale = 0.35,
	Bloom = { Intensity = 0.08, Size = 24, Threshold = 1.3 },
	ColorCorrection = { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1,1,1) }
}

-- [CONTROLLER DEFINITION]
local PlanetController = Knit.CreateController { Name = "PlanetController" }

-- [STATE]
local RenderedPlanets = {}
local AtmosphereState = { InAtmosphere = false, CurrentPlanetKey = nil }
local CachedPlanets: {PlanetData} = {} 

local currentFetchPromise = nil
local activeLightingTweens = {}
local lastPlanetKey = nil

-- [HELPER FUNCTIONS]
local function toColor(t: any): Color3
	if typeof(t) == "Color3" then return t end
	return Color3.new(t.R, t.G, t.B)
end

local function cancelActiveTweens()
	for _, tween in pairs(activeLightingTweens) do
		if tween and tween.Cancel then tween:Cancel() end
	end
	activeLightingTweens = {}
end

local function tweenProperty(instance: Instance, properties: {[string]: any})
	local tween = TweenService:Create(instance, TWEEN_INFO_LIGHTING, properties)
	table.insert(activeLightingTweens, tween)
	tween:Play()
end

local function UpdateLightingEffects(targetConfig: LightingConfig)
	cancelActiveTweens()
	tweenProperty(Lighting, {
		Brightness = targetConfig.Brightness or DEFAULT_LIGHTING.Brightness,
		Ambient = targetConfig.Ambient and toColor(targetConfig.Ambient) or DEFAULT_LIGHTING.Ambient,
		OutdoorAmbient = targetConfig.OutdoorAmbient and toColor(targetConfig.OutdoorAmbient) or DEFAULT_LIGHTING.OutdoorAmbient,
		EnvironmentDiffuseScale = targetConfig.EnvironmentDiffuseScale or DEFAULT_LIGHTING.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = targetConfig.EnvironmentSpecularScale or DEFAULT_LIGHTING.EnvironmentSpecularScale
	})
	
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
	
	-- [FIX 2] Explicitly type ccConf so 'or {}' is treated as ColorCorrectionConfig (valid because fields are optional)
	local ccConf: ColorCorrectionConfig = targetConfig.ColorCorrection or DEFAULT_LIGHTING.ColorCorrection or {}
	
	tweenProperty(cc, {
		Brightness = ccConf.Brightness or 0,
		Contrast = ccConf.Contrast or 0,
		Saturation = ccConf.Saturation or 0,
		TintColor = ccConf.TintColor and toColor(ccConf.TintColor) or Color3.new(1,1,1)
	})
	
	local bloomFx = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
	-- [FIX 3] Cast to 'any' to handle the mix of custom keys (BloomIntensity) and Roblox keys (Intensity)
	local bloomConf: any = targetConfig.Bloom or DEFAULT_LIGHTING.Bloom or {}
	
	tweenProperty(bloomFx, {
		Intensity = bloomConf.Intensity or bloomConf.BloomIntensity or 0,
		Size = bloomConf.Size or bloomConf.BloomSize or 0,
		Threshold = bloomConf.Threshold or bloomConf.BloomThreshold or 0
	})
end

local function applySky(skyName: string?)
	local currentSky = Lighting:FindFirstChildOfClass("Sky")
	if currentSky and currentSky.Name == skyName then return end
	
	-- Clear old sky
	for _, obj in ipairs(Lighting:GetChildren()) do 
		if obj:IsA("Sky") then obj:Destroy() end 
	end
	
	local skies = ReplicatedStorage:FindFirstChild("Skies")
	local targetName = (skyName and skyName ~= "") and skyName or "space"
	if skies then
		local sky = skies:FindFirstChild(targetName) or skies:FindFirstChild("space")
		if sky then 
			local clone = sky:Clone()
			clone.Parent = Lighting 
		end
	end
end

-- [MODEL CREATION]
local function CreateAtmosphereOnlyModel(data: PlanetData)
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

local function CreatePlanetModel(data: PlanetData)
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
			
			local cf = CFrame.new(obj.PosX, obj.PosY, obj.PosZ) * CFrame.Angles(0, math.rad(obj.RotY or 0), 0)
			
			if clone:IsA("Model") then
				clone:PivotTo(cf)
			else
				clone.CFrame = cf * CFrame.new(0, clone.Size.Y/2, 0)
			end
			clone.Parent = objectsFolder
		end
	end
	return model
end

-- [CORE LOGIC]
function PlanetController:KnitStart()
	print("[PlanetController] Started")
	self.PlanetService = Knit.GetService("PlanetService")
	
	local player = Players.LocalPlayer
	
	-- Handle initial spawn
	if player.Character then self:HandleCharacterSpawn(player.Character) end
	player.CharacterAdded:Connect(function(char) self:HandleCharacterSpawn(char) end)

	-- Network Fetch Loop
	task.spawn(function()
		local lastPos = Vector3.new(0, -999999, 0)
		while true do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart
			if root and not root.Anchored then
				if (root.Position - lastPos).Magnitude > UPDATE_THRESHOLD then
					self:FetchPlanetsFromServer():andThen(function(newPlanets)
						CachedPlanets = newPlanets
						lastPos = root.Position
					end):catch(warn)
				end
			end
			task.wait(0.5)
		end
	end)

	-- Render Loop
	RunService.Heartbeat:Connect(function()
		if CachedPlanets and #CachedPlanets > 0 then
			self:RenderPlanets(CachedPlanets)
		end
	end)
end

function PlanetController:FetchPlanetsFromServer()
	if currentFetchPromise then currentFetchPromise:cancel() end
	
	currentFetchPromise = Promise.new(function(resolve, reject)
		-- Using Knit Service Method instead of RemoteFunction
		self.PlanetService:GetPlanetsNearPosition():andThen(resolve):catch(reject)
	end)
	
	return currentFetchPromise
end

function PlanetController:HandleCharacterSpawn(char)
	local root = char:WaitForChild("HumanoidRootPart") :: BasePart
	root.Anchored = true
	
	Promise.retryWithDelay(function()
		return self:FetchPlanetsFromServer():andThen(function(planets)
			if not planets or #planets == 0 then return Promise.reject("Empty") end
			return planets
		end)
	end, 20, 0.5)
	:andThen(function(planets)
		CachedPlanets = planets
		if #planets > 0 then
			local randomPlanet = planets[math.random(1, #planets)]
			local key = self:_GetPlanetKey(randomPlanet)
			
			if randomPlanet.WorldPos and randomPlanet.Size then
				local radius = randomPlanet.Size / 2
				local dropHeight = radius + 200
				
				root.CFrame = CFrame.new(randomPlanet.WorldPos.X, randomPlanet.WorldPos.Y + dropHeight, randomPlanet.WorldPos.Z)
				
				-- FORCE PRE-RENDER SPACE MODE
				if RenderedPlanets[key] then RenderedPlanets[key]:Destroy() end
				local model = CreateAtmosphereOnlyModel(randomPlanet)
				model.Parent = workspace
				RenderedPlanets[key] = model
				
				AtmosphereState.InAtmosphere = false
				lastPlanetKey = "_space_"
				UpdateLightingEffects(DEFAULT_LIGHTING)
				applySky(DEFAULT_SKY_NAME)
				
				print("Orbital Drop initialized at:", key)
			end
			task.wait(1.0)
			root.Anchored = false
		else
			warn("No planets found for spawn")
			root.Anchored = false
		end
	end)
	:catch(function(err) warn(err); root.Anchored = false end)
end

function PlanetController:RenderPlanets(planets: {PlanetData})
	local player = Players.LocalPlayer
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart
	if not root then return end
	
	local playerPos = root.Position
	local inPlanet = self:_GetCurrentPlanetInAtmosphere(planets, playerPos)
	
	local planetByKey = {}
	for _, data in ipairs(planets) do
		planetByKey[self:_GetPlanetKey(data)] = data
	end

	local newPlanetKey = inPlanet and self:_GetPlanetKey(inPlanet) or nil
	AtmosphereState.InAtmosphere = (inPlanet ~= nil)
	AtmosphereState.CurrentPlanetKey = newPlanetKey

	if AtmosphereState.InAtmosphere then
		-- STATE: INSIDE ATMOSPHERE (FULL RENDER)
		if lastPlanetKey ~= newPlanetKey and inPlanet then
			local data = planetByKey[newPlanetKey]
			if data then
				local newModel = CreatePlanetModel(data)
				newModel.Parent = workspace
				
				if RenderedPlanets[newPlanetKey] then RenderedPlanets[newPlanetKey]:Destroy() end
				RenderedPlanets[newPlanetKey] = newModel
				
				-- Destroy all other distant planets to save performance/visuals
				for key, model in pairs(RenderedPlanets) do
					if key ~= newPlanetKey then
						model:Destroy()
						RenderedPlanets[key] = nil
					end
				end
				
				local targetConfig: LightingConfig = { Bloom = data.Bloom }
				UpdateLightingEffects(targetConfig)
				applySky(data.SkyPresetName)
			end
			lastPlanetKey = newPlanetKey
		end
	else
		-- STATE: SPACE (ATMOSPHERE ORB RENDER)
		if lastPlanetKey ~= "_space_" then
			-- Switch to space mode: clear everything, render only orbs
			for key, model in pairs(RenderedPlanets) do 
				model:Destroy(); RenderedPlanets[key] = nil 
			end
			for key, data in pairs(planetByKey) do
				local m = CreateAtmosphereOnlyModel(data)
				m.Parent = workspace
				RenderedPlanets[key] = m
			end
			UpdateLightingEffects(DEFAULT_LIGHTING)
			applySky(DEFAULT_SKY_NAME)
			lastPlanetKey = "_space_"
		else
			-- Update new planets coming into view
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

-- [INTERNAL HELPERS]
function PlanetController:_GetPlanetKey(data: PlanetData)
	return data.GridPos.X .. "_" .. data.GridPos.Y .. "_" .. data.GridPos.Z
end

function PlanetController:_GetCurrentPlanetInAtmosphere(planets: {PlanetData}, playerPos: Vector3)
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
		if minDst < radius then 
			return nearest 
		end
	end
	return nil
end

return PlanetController