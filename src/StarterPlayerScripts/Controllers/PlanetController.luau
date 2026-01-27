local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local Knit = require(ReplicatedStorage.Packages.Knit) :: any
local Promise = require(ReplicatedStorage.Packages.Promise)
local PlanetMath = require(ReplicatedStorage.Common.PlanetMath)
local ObjectPool = require(ReplicatedStorage.Common.ObjectPool)

-- [CONSTANTS]
local UPDATE_THRESHOLD = 100 
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

-- [CONTROLLER DEFINITION]
local PlanetController = Knit.CreateController { Name = "PlanetController" }

-- [STATE]
local RenderedPlanets = {}
local AtmosphereState = { InAtmosphere = false, CurrentPlanetKey = nil }
local CachedPlanets = {} 
local currentFetchPromise = nil
local activeLightingTweens = {}
local lastPlanetKey = nil

-- [POOLS]
local Pools = {} 

-- [HELPER FUNCTIONS]
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
	local ccConf = targetConfig.ColorCorrection or DEFAULT_LIGHTING.ColorCorrection or {}
	tweenProperty(cc, {
		Brightness = ccConf.Brightness or 0,
		Contrast = ccConf.Contrast or 0,
		Saturation = ccConf.Saturation or 0,
		TintColor = ccConf.TintColor and toColor(ccConf.TintColor) or Color3.new(1,1,1)
	})
	
	local bloomFx = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
	local bloomConf = targetConfig.Bloom or DEFAULT_LIGHTING.Bloom or {}
	tweenProperty(bloomFx, {
		Intensity = bloomConf.Intensity or bloomConf.BloomIntensity or 0,
		Size = bloomConf.Size or bloomConf.BloomSize or 0,
		Threshold = bloomConf.Threshold or bloomConf.BloomThreshold or 0
	})
end

local function applySky(skyName)
	local currentSky = Lighting:FindFirstChildOfClass("Sky")
	if currentSky and currentSky.Name == skyName then return end
	
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

-- [ASSET SYSTEM - CORRECTED PATH]
function PlanetController:SetupPools()
	-- Cấu hình: Folder nằm trực tiếp trong ReplicatedStorage
	local categories = {
		{FolderName = "Trees", Type = "Tree"},
		{FolderName = "Rocks", Type = "Rock"}
	}
	
	local assetsToPreload = {}

	for _, cat in ipairs(categories) do
		-- [FIX] Tìm trực tiếp trong ReplicatedStorage
		local folder = ReplicatedStorage:FindFirstChild(cat.FolderName)
		
		if folder then
			for _, model in ipairs(folder:GetChildren()) do
				-- Key duy nhất: "Tree_1", "Tree_2", "Rock_1", ...
				local poolKey = cat.Type .. "_" .. model.Name 
				
				-- Tạo Pool (30 objects mỗi loại)
				Pools[poolKey] = ObjectPool.new(model, 30)
				table.insert(assetsToPreload, model)
				print("[PlanetController] Pool Ready:", poolKey)
			end
		else
			warn("[PlanetController] Missing folder in ReplicatedStorage:", cat.FolderName)
		end
	end

	-- Preload assets thật
	if #assetsToPreload > 0 then
		task.spawn(function()
			pcall(function() ContentProvider:PreloadAsync(assetsToPreload) end)
		end)
	end
end

-- [RENDER LOGIC]
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

function PlanetController:CreatePlanetModel(data)
	local model = Instance.new("Model")
	model.Name = "Planet_" .. data.GridPos.X .. "_" .. data.GridPos.Y .. "_" .. data.GridPos.Z
	
	-- Core & Atmosphere
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
	local tileY = 3
	local groundDiameter = math.min(data.Size * 0.4, data.Size * 0.98)
	local tile = Instance.new("Part")
	tile.Name = "CoreTile"
	tile.Anchored = true
	tile.Material = Enum.Material.Plastic
	tile.Size = Vector3.new(groundDiameter, tileY, groundDiameter)
	tile.Position = Vector3.new(data.WorldPos.X, data.WorldPos.Y, data.WorldPos.Z)
	tile.Color = Color3.new(data.Biome.Color.R, data.Biome.Color.G, data.Biome.Color.B)
	tile.TopSurface = Enum.SurfaceType.Studs
	tile.Parent = groundFolder

	-- OBJECTS GENERATION (CORRECT KEY LOOKUP)
	local objectsFolder = Instance.new("Folder", model)
	objectsFolder.Name = "Objects"
	
	local objectsData = PlanetMath.GenerateVegetationData(data.Seed, data.Size, Vector3.new(data.WorldPos.X, data.WorldPos.Y, data.WorldPos.Z))
	
	for _, obj in ipairs(objectsData) do
		-- Logic: obj.Type="Tree", obj.Model="1" -> Key="Tree_1"
		local poolKey = obj.Type .. "_" .. obj.Model 
		local pool = Pools[poolKey]
		
		-- Fallback: Nếu không tìm thấy Tree_5, thử tìm Tree_1
		if not pool then
			pool = Pools[obj.Type .. "_1"] 
		end
		
		if pool then
			local item = pool:Get()
			if item then
				local cf = CFrame.new(obj.PosX, obj.PosY, obj.PosZ) * CFrame.Angles(0, math.rad(obj.RotY or 0), 0)
				
				if item:IsA("Model") then
					item:PivotTo(cf)
					if obj.Scale and item.PrimaryPart then
						item:ScaleTo(obj.Scale)
					end
				else
					item.CFrame = cf * CFrame.new(0, item.Size.Y/2, 0)
				end
				
				-- Lưu key để trả về đúng kho khi unload
				item:SetAttribute("PoolType", poolKey)
				item.Parent = objectsFolder
			end
		end
	end
	
	return model
end

function PlanetController:UnloadPlanet(key)
	local model = RenderedPlanets[key]
	if not model then return end
	
	local objectsFolder = model:FindFirstChild("Objects")
	if objectsFolder then
		for _, item in ipairs(objectsFolder:GetChildren()) do
			local poolKey = item:GetAttribute("PoolType")
			if poolKey and Pools[poolKey] then
				Pools[poolKey]:Return(item)
			else
				item:Destroy()
			end
		end
	end
	model:Destroy()
	RenderedPlanets[key] = nil
end

function PlanetController:KnitStart()
	print("[PlanetController] Started - Direct RepStorage Access")
	self:SetupPools()
	
	self.PlanetService = Knit.GetService("PlanetService")
	local player = Players.LocalPlayer
	
	if player.Character then self:HandleCharacterSpawn(player.Character) end
	player.CharacterAdded:Connect(function(char) self:HandleCharacterSpawn(char) end)

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

	RunService.Heartbeat:Connect(function()
		if CachedPlanets and #CachedPlanets > 0 then
			self:RenderPlanets(CachedPlanets)
		end
	end)
end

function PlanetController:FetchPlanetsFromServer()
	if currentFetchPromise then currentFetchPromise:cancel() end
	currentFetchPromise = Promise.new(function(resolve, reject)
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
				
				if RenderedPlanets[key] then self:UnloadPlanet(key) end
				
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

function PlanetController:RenderPlanets(planets)
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
		if lastPlanetKey ~= newPlanetKey and inPlanet then
			local data = planetByKey[newPlanetKey]
			if data then
				local newModel = self:CreatePlanetModel(data)
				newModel.Parent = workspace
				
				if RenderedPlanets[newPlanetKey] then self:UnloadPlanet(newPlanetKey) end
				RenderedPlanets[newPlanetKey] = newModel
				
				for key, _ in pairs(RenderedPlanets) do
					if key ~= newPlanetKey then
						self:UnloadPlanet(key)
					end
				end
				
				local targetConfig = { Bloom = data.Bloom }
				UpdateLightingEffects(targetConfig)
				applySky(data.SkyPresetName)
			end
			lastPlanetKey = newPlanetKey
		end
	else
		if lastPlanetKey ~= "_space_" then
			for key, _ in pairs(RenderedPlanets) do 
				self:UnloadPlanet(key)
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

function PlanetController:_GetPlanetKey(data)
	return data.GridPos.X .. "_" .. data.GridPos.Y .. "_" .. data.GridPos.Z
end

function PlanetController:_GetCurrentPlanetInAtmosphere(planets, playerPos)
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

return PlanetController