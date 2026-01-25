-- PlanetController: Minimal, stateless client. Only renders planets using server metadata.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local RenderedPlanets = {}

-- Default space lighting/sky config
local DEFAULT_LIGHTING = {
	Brightness = 1.5,
	Ambient = Color3.fromRGB(10,10,20), -- giảm ambient để bóng rõ hơn
	OutdoorAmbient = Color3.fromRGB(20,20,30),
	EnvironmentDiffuseScale = 1.1, -- tăng mạnh bóng khuếch tán
	EnvironmentSpecularScale = 0.35, -- tăng bóng gương
}
local DEFAULT_SKY_NAME = "Space"
local function applyLightingConfig(bloom)
	local Lighting = game:GetService("Lighting")
	if not bloom then bloom = {} end
	if bloom.Brightness ~= nil then Lighting.Brightness = bloom.Brightness else Lighting.Brightness = DEFAULT_LIGHTING.Brightness end
	if bloom.Ambient ~= nil then Lighting.Ambient = Color3.new(bloom.Ambient.R, bloom.Ambient.G, bloom.Ambient.B) else Lighting.Ambient = DEFAULT_LIGHTING.Ambient end
	if bloom.OutdoorAmbient ~= nil then Lighting.OutdoorAmbient = Color3.new(bloom.OutdoorAmbient.R, bloom.OutdoorAmbient.G, bloom.OutdoorAmbient.B) else Lighting.OutdoorAmbient = DEFAULT_LIGHTING.OutdoorAmbient end
	if bloom.EnvironmentDiffuseScale ~= nil then Lighting.EnvironmentDiffuseScale = bloom.EnvironmentDiffuseScale else Lighting.EnvironmentDiffuseScale = DEFAULT_LIGHTING.EnvironmentDiffuseScale end
	if bloom.EnvironmentSpecularScale ~= nil then Lighting.EnvironmentSpecularScale = bloom.EnvironmentSpecularScale else Lighting.EnvironmentSpecularScale = DEFAULT_LIGHTING.EnvironmentSpecularScale end
	-- ColorCorrection
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if not cc then cc = Instance.new("ColorCorrectionEffect"); cc.Parent = Lighting end
	if bloom.ColorCorrection then
		cc.Brightness = bloom.ColorCorrection.Brightness or 0
		cc.Contrast = bloom.ColorCorrection.Contrast or 0
		cc.Saturation = bloom.ColorCorrection.Saturation or 0
		if bloom.ColorCorrection.TintColor then
			cc.TintColor = Color3.new(bloom.ColorCorrection.TintColor.R, bloom.ColorCorrection.TintColor.G, bloom.ColorCorrection.TintColor.B)
		end
	else
		cc.Brightness = 0; cc.Contrast = 0; cc.Saturation = 0; cc.TintColor = Color3.new(1,1,1)
	end
	-- BloomEffect
	local bloomFx = Lighting:FindFirstChildOfClass("BloomEffect")
	if not bloomFx then bloomFx = Instance.new("BloomEffect"); bloomFx.Parent = Lighting end
	bloomFx.Intensity = bloom.BloomIntensity or 0.08
	bloomFx.Size = bloom.BloomSize or 24
	bloomFx.Threshold = bloom.BloomThreshold or 1.3
end

local function applySky(skyName)
	local Lighting = game:GetService("Lighting")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	-- Remove old sky
	for _, obj in ipairs(Lighting:GetChildren()) do
		if obj:IsA("Sky") then obj:Destroy() end
	end
	local skies = ReplicatedStorage:FindFirstChild("Skies")
	if not skyName or skyName == "" or skyName == DEFAULT_SKY_NAME then
		-- Luôn clone sky 'space' (chữ thường) nếu có
		if skies then
			local sky = skies:FindFirstChild("space")
			if sky and sky:IsA("Sky") then
				local clone = sky:Clone()
				clone.Parent = Lighting
			end
		end
		return
	end
	if skies then
		local sky = skies:FindFirstChild(skyName)
		if sky and sky:IsA("Sky") then
			local clone = sky:Clone()
			clone.Parent = Lighting
		end
	end
end

local function CreatePlanetModel(data)
	local key = data.GridPos.X .. "_" .. data.GridPos.Y .. "_" .. data.GridPos.Z
	local planetModel = Instance.new("Model")
	planetModel.Name = "Planet_" .. key
	-- Atmosphere
	local centerPos = Vector3.new(data.WorldPos.X, data.WorldPos.Y, data.WorldPos.Z)
	if data.GroundTiles and #data.GroundTiles > 0 then
		local sum = Vector3.new(0,0,0)
		for _, tile in ipairs(data.GroundTiles) do
			sum = sum + Vector3.new(tile.Position.X, tile.Position.Y, tile.Position.Z)
		end
		centerPos = sum / #data.GroundTiles
	end
	local atmosphere = Instance.new("Part")
	atmosphere.Name = "Atmosphere"
	atmosphere.Size = Vector3.new(data.Size, data.Size, data.Size)
	atmosphere.Position = centerPos
	atmosphere.Anchored = true
	atmosphere.CanCollide = false
	atmosphere.Material = Enum.Material.Neon
	atmosphere.Color = Color3.new(data.Biome.Color.R, data.Biome.Color.G, data.Biome.Color.B)
	atmosphere.Shape = Enum.PartType.Ball
	atmosphere.Transparency = 0 -- hoàn toàn đục
	atmosphere.CastShadow = false -- không đổ bóng lên ground
	pcall(function() atmosphere.LocalTransparencyModifier = 0 end)
	atmosphere.Parent = planetModel

	-- Không tự động áp dụng ánh sáng ở đây nữa, sẽ xử lý theo vị trí player
	-- Ground
	if data.GroundTiles then
		local groundFolder = Instance.new("Folder")
		groundFolder.Name = "GroundTiles"
		groundFolder.Parent = planetModel
		for _, tileData in ipairs(data.GroundTiles) do
			local tile = Instance.new("Part")
			tile.Name = "Tile"
			tile.Size = Vector3.new(tileData.Size.X, tileData.Size.Y, tileData.Size.Z)
			tile.Position = Vector3.new(tileData.Position.X, tileData.Position.Y, tileData.Position.Z)
			tile.Anchored = true
			tile.Material = Enum.Material.Plastic
			tile.Color = Color3.new(tileData.Color.R, tileData.Color.G, tileData.Color.B)
			tile.TopSurface = tileData.TopSurface == "Studs" and Enum.SurfaceType.Studs or Enum.SurfaceType.Smooth
			tile.BottomSurface = tileData.BottomSurface == "Studs" and Enum.SurfaceType.Studs or Enum.SurfaceType.Smooth
			tile.Parent = groundFolder
		end
	end
	-- Objects
	if data.Objects then
		local objectsFolder = Instance.new("Folder")
		objectsFolder.Name = "Objects"
		objectsFolder.Parent = planetModel
		local treesFolder = ReplicatedStorage:FindFirstChild("Trees")
		local rocksFolder = ReplicatedStorage:FindFirstChild("Rocks")
		for _, obj in ipairs(data.Objects) do
			local model = nil
			if obj.Type == "Tree" and treesFolder then
				model = treesFolder:FindFirstChild(obj.Model)
			elseif obj.Type == "Rock" and rocksFolder then
				model = rocksFolder:FindFirstChild(obj.Model)
			end
			if model then
				local clone = model:Clone()
				clone.Name = obj.Type
				if clone.PrimaryPart then
					clone:SetPrimaryPartCFrame(CFrame.new(obj.PosX or 0, obj.PosY or 0, obj.PosZ or 0))
				else
					clone.Parent = objectsFolder
					clone:SetPrimaryPartCFrame(CFrame.new(obj.PosX or 0, obj.PosY or 0, obj.PosZ or 0))
				end
				clone.Parent = objectsFolder
			else
				-- fallback: create a colored part if model missing
				local part = Instance.new("Part")
				part.Name = obj.Type .. (obj.Model or "")
				part.Size = Vector3.new(obj.SizeX or 8, obj.SizeY or 16, obj.SizeZ or 8)
				part.Anchored = true
				part.Position = Vector3.new(obj.PosX or 0, obj.PosY or 0, obj.PosZ or 0)
				if obj.Color then
					part.Color = Color3.new(obj.Color.R, obj.Color.G, obj.Color.B)
				elseif obj.Type == "Tree" then
					part.Color = Color3.fromRGB(34, 139, 34)
				else
					part.Color = Color3.fromRGB(120, 120, 120)
				end
				part.Parent = objectsFolder
			end
		end
	end
	planetModel.Parent = workspace
	return planetModel
end

local HttpService = game:GetService("HttpService")


-- Helper: kiểm tra player có đang trong atmosphere planet nào không
local function getCurrentPlanetInAtmosphere(planets, playerPos)
	for _, data in ipairs(planets) do
		local center = Vector3.new(data.WorldPos.X, data.WorldPos.Y, data.WorldPos.Z)
		local radius = data.Size/2
		if (playerPos - center).Magnitude < radius then
			return data
		end
	end
	return nil
end


local lastPlanetKey = nil
local lastSkyName = nil

function RenderPlanetsFromServer(planets)
    -- Build new set of keys
    local newKeys = {}
    local newData = {}
    for _, data in ipairs(planets) do
        local key = data.GridPos.X .. "_" .. data.GridPos.Y .. "_" .. data.GridPos.Z
        newKeys[key] = true
        newData[key] = data
    end
    -- Destroy models for planets no longer present
    for key, model in pairs(RenderedPlanets) do
        if not newKeys[key] then
            if typeof(model) == "Instance" and model:IsA("Model") then
                model:Destroy()
            end
            RenderedPlanets[key] = nil
        end
    end
    -- Create or update models for new/changed planets
    for key, data in pairs(newData) do
        local oldModel = RenderedPlanets[key]
        local oldMeta = oldModel and oldModel:GetAttribute("_MetaJson")
        local newMeta = HttpService:JSONEncode(data)
        if not oldModel or oldMeta ~= newMeta then
            if oldModel and typeof(oldModel) == "Instance" and oldModel:IsA("Model") then
                oldModel:Destroy()
            end
            local model = CreatePlanetModel(data)
            model:SetAttribute("_MetaJson", newMeta)
            RenderedPlanets[key] = model
        end
    end

    -- Xác định player đang ở trong planet nào (nếu có)
    local player = Players.LocalPlayer
    local char = player and player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local playerPos = root and root.Position
    local inPlanet = nil
    if playerPos then
        inPlanet = getCurrentPlanetInAtmosphere(planets, playerPos)
    end
    if inPlanet then
        -- Đang trong atmosphere: set lighting/sky theo planet
        local planetKey = inPlanet.GridPos.X .. "_" .. inPlanet.GridPos.Y .. "_" .. inPlanet.GridPos.Z
        if lastPlanetKey ~= planetKey then
            applyLightingConfig(inPlanet.Bloom)
            applySky(inPlanet.SkyPresetName)
            lastPlanetKey = planetKey
            lastSkyName = inPlanet.SkyPresetName
        end
    else
        -- Ngoài atmosphere: set lighting/sky về mặc định (space)
        if lastPlanetKey ~= "_space_" then
            applyLightingConfig(nil)
            applySky(DEFAULT_SKY_NAME)
            lastPlanetKey = "_space_"
            lastSkyName = DEFAULT_SKY_NAME
        end
    end
end

local PlanetController = {}

function PlanetController.Init()
	local player = Players.LocalPlayer
	local GetPlanetsRemote = ReplicatedStorage:WaitForChild("GetPlanetsRemote")
	local DESTROY_HEIGHT = workspace.FallenPartsDestroyHeight or -500
	local PLANET_Y = DESTROY_HEIGHT + 3000
	task.defer(function()
		local character = player.Character or player.CharacterAdded:Wait()
		local rootPart = character:WaitForChild("HumanoidRootPart")
		rootPart.Anchored = true
		rootPart.CFrame = CFrame.new(0, PLANET_Y + 200, 0)
		-- Always render home planet first and teleport player onto it
		local pos = Vector3.new(0, PLANET_Y, 0)
		local success, planets = pcall(function()
			return GetPlanetsRemote:InvokeServer(pos)
		end)
		assert(success and planets and #planets > 0, "No planet data from server!")
		-- Find home planet and spawn player on it
		local homePlanetData = nil
		for _, data in ipairs(planets) do
			if data.IsHome then
				data.WorldPos.Y = PLANET_Y
				homePlanetData = data
				break
			end
		end
		assert(homePlanetData, "Home planet data not found!")
		local homePlanetModel = CreatePlanetModel(homePlanetData)
		assert(homePlanetModel, "Home planet model not created!")
		-- Teleport player to home planet center
		local spawnCFrame = nil
		local groundFolder = homePlanetModel:FindFirstChild("GroundTiles")
		local centerTile = nil
		if groundFolder then
			local minDist = math.huge
			for _, tile in ipairs(groundFolder:GetChildren()) do
				if tile:IsA("BasePart") then
					local dist = (tile.Position - Vector3.new(0, tile.Position.Y, 0)).Magnitude
					if dist < minDist then
						centerTile = tile
						minDist = dist
					end
				end
			end
		end
		if centerTile then
			spawnCFrame = CFrame.new(centerTile.Position + Vector3.new(0, centerTile.Size.Y/2 + 3, 0))
		else
			spawnCFrame = CFrame.new(Vector3.new(homePlanetData.WorldPos.X, homePlanetData.WorldPos.Y + 6, homePlanetData.WorldPos.Z))
		end
		rootPart.CFrame = spawnCFrame
		rootPart.Anchored = false

		-- Main render loop: always fetch and render planets from server
		while true do
			local pos = rootPart.Position
			local ok, planets = pcall(function()
				return GetPlanetsRemote:InvokeServer(pos)
			end)
			if ok and planets then
				RenderPlanetsFromServer(planets)
			end
			task.wait(0.5)
		end
	end)
end

return PlanetController
