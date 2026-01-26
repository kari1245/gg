local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService") -- Dùng để check mỗi frame

local Promise = require(ReplicatedStorage.Packages.Promise)

local PlanetController = {}
local RenderedPlanets = {}
local AtmosphereState = { InAtmosphere = false, CurrentPlanetKey = nil }
local CachedPlanets = {} -- Lưu cache data để xử lý nhanh

-- Constants
local DEFAULT_SKY_NAME = "Space"
local DEFAULT_LIGHTING = {
	Brightness = 1.5,
	Ambient = Color3.fromRGB(10,10,20),
	OutdoorAmbient = Color3.fromRGB(20,20,30),
	EnvironmentDiffuseScale = 1.1,
	EnvironmentSpecularScale = 0.35,
}

-- Fade effect helper
local function fadeColorCorrection(target, duration, props)
	duration = duration or 0.7
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)

	local start = {}
	for k, v in pairs(props) do
		start[k] = cc[k]
	end

	local t = 0
	while t < duration do
		t = math.min(t + RunService.RenderStepped:Wait(), duration)
		local alpha = t / duration
		for k, v in pairs(props) do
			if typeof(v) == "number" then
				cc[k] = start[k] + (v - start[k]) * alpha
			elseif typeof(v) == "Color3" then
				local s = start[k] or Color3.new(1,1,1)
				cc[k] = Color3.new(
				s.R + (v.R - s.R) * alpha,
				s.G + (v.G - s.G) * alpha,
				s.B + (v.B - s.B) * alpha
			)
			end
		end
	end
end

local function applyLightingConfig(bloom, fade)
	if not bloom then bloom = {} end
	Lighting.Brightness = bloom.Brightness or DEFAULT_LIGHTING.Brightness
	Lighting.Ambient = bloom.Ambient and Color3.new(bloom.Ambient.R, bloom.Ambient.G, bloom.Ambient.B) or DEFAULT_LIGHTING.Ambient
	Lighting.OutdoorAmbient = bloom.OutdoorAmbient and Color3.new(bloom.OutdoorAmbient.R, bloom.OutdoorAmbient.G, bloom.OutdoorAmbient.B) or DEFAULT_LIGHTING.OutdoorAmbient
	Lighting.EnvironmentDiffuseScale = bloom.EnvironmentDiffuseScale or DEFAULT_LIGHTING.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = bloom.EnvironmentSpecularScale or DEFAULT_LIGHTING.EnvironmentSpecularScale

	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
	local ccConf = bloom.ColorCorrection or {}
	local targetProps = {
		Brightness = ccConf.Brightness or 0,
		Contrast = ccConf.Contrast or 0,
		Saturation = ccConf.Saturation or 0,
		TintColor = ccConf.TintColor and Color3.new(ccConf.TintColor.R, ccConf.TintColor.G, ccConf.TintColor.B) or Color3.new(1,1,1)
	}
	if fade then
		fadeColorCorrection(0.7, 0.7, targetProps)
	else
		for k, v in pairs(targetProps) do cc[k] = v end
	end

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
	
	return model -- Chưa parent vào workspace ngay để tránh flicker
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
	
	return model
end

-- LOGIC CHUẨN: Bán kính thật
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
		if minDst < radius then 
			return nearest 
		end
	end
	return nil
end

local lastPlanetKey = nil

-- Hàm Render Tối Ưu: Tạo Mới -> Parent -> Xóa Cũ (Tránh nháy hình)
function RenderPlanetsFromServer(planets)
	-- Update Cache
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
		-- TRANSITION: SPACE -> PLANET (or Planet -> Planet)
		if lastPlanetKey ~= newPlanetKey then
			local data = planetByKey[newPlanetKey]
			if data then
				local newModel = CreatePlanetModel(data)
				newModel.Parent = workspace
				if RenderedPlanets[newPlanetKey] then
					RenderedPlanets[newPlanetKey]:Destroy()
				end
				RenderedPlanets[newPlanetKey] = newModel
				clearRenderedExcept(newPlanetKey)
				applyLightingConfig(data.Bloom, true) -- Fade in khi vào planet
				applySky(data.SkyPresetName)
			end
			lastPlanetKey = newPlanetKey
		end
	else
		-- TRANSITION: PLANET -> SPACE
		if lastPlanetKey ~= "_space_" then
			for key, model in pairs(RenderedPlanets) do
				model:Destroy()
				RenderedPlanets[key] = nil
			end
			for key, data in pairs(planetByKey) do
				local m = CreateAtmosphereOnlyModel(data)
				m.Parent = workspace
				RenderedPlanets[key] = m
			end
			applyLightingConfig(nil, true) -- Fade out khi ra space
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

function PlanetController.Init()
	local GetPlanetsRemote = ReplicatedStorage:WaitForChild("GetPlanetsRemote")
	
	local function HandleCharacterSpawn(char)
		local root = char:WaitForChild("HumanoidRootPart")
		root.Anchored = true

		local function fetchPlanetsPromise(attempts)
			attempts = attempts or 0
			return Promise.new(function(resolve, reject)
				local ok, data = pcall(function() return GetPlanetsRemote:InvokeServer() end)
				if ok and data and #data > 0 then
					resolve(data)
				elseif attempts < 20 then
					task.wait(0.5)
					fetchPlanetsPromise(attempts + 1):andThen(resolve, reject)
				else
					reject("Failed to fetch planets after 20 attempts")
				end
			end)
		end

		fetchPlanetsPromise():andThen(function(planets)
			CachedPlanets = planets or {}
			local validPlanets = {}
			for _, p in ipairs(planets) do
				if p.GroundTiles and #p.GroundTiles > 0 then table.insert(validPlanets, p) end
			end
			if #validPlanets > 0 then
				local randomPlanet = validPlanets[math.random(1, #validPlanets)]
				local key = randomPlanet.GridPos.X .. "_" .. randomPlanet.GridPos.Y .. "_" .. randomPlanet.GridPos.Z
				if randomPlanet.WorldPos and randomPlanet.Size then
					local radius = randomPlanet.Size / 2
					local dropHeight = radius + 200
					root.CFrame = CFrame.new(randomPlanet.WorldPos.X, randomPlanet.WorldPos.Y + dropHeight, randomPlanet.WorldPos.Z)
					if RenderedPlanets[key] then RenderedPlanets[key]:Destroy() end
					local model = CreateAtmosphereOnlyModel(randomPlanet)
					model.Parent = workspace
					RenderedPlanets[key] = model
					AtmosphereState.InAtmosphere = false
					lastPlanetKey = "_space_"
					applyLightingConfig(nil)
					applySky(DEFAULT_SKY_NAME)
				end
				task.wait(1.0)
				root.Anchored = false
			else
				root.Anchored = false
			end
		end):catch(function()
			root.Anchored = false
		end)
	end

	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(HandleCharacterSpawn)
	if player.Character then task.spawn(function() HandleCharacterSpawn(player.Character) end) end

	-- [OPTIMIZATION] NETWORK SYNC LOOP (Chậm - 0.5s)
	task.defer(function()
		local lastPos = Vector3.new(0, -999999, 0)
		local UPDATE_THRESHOLD = 100
		while true do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and not root.Anchored then
				if (root.Position - lastPos).Magnitude > UPDATE_THRESHOLD then
					Promise.new(function(resolve, reject)
						local ok, newPlanets = pcall(function() return GetPlanetsRemote:InvokeServer() end)
						if ok and newPlanets then resolve(newPlanets) else reject() end
					end):andThen(function(newPlanets)
						CachedPlanets = newPlanets
						lastPos = root.Position
					end)
				end
			end
			task.wait(0.5)
		end
	end)

	-- [OPTIMIZATION] RENDER LOOP (Nhanh - Mỗi Frame)
	-- Check vị trí liên tục để chuyển đổi Space <-> Planet mượt mà
	RunService.Heartbeat:Connect(function()
		if #CachedPlanets > 0 then
			RenderPlanetsFromServer(CachedPlanets)
		end
	end)
end

return PlanetController