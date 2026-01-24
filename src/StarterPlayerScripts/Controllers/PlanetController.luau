-- PlanetController: Client-side planet streaming and rendering
-- Clean, robust, idiomatic Luau for Roblox

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local MAX_RENDERED_PLANETS = 17
local PLANET_SPAWN_RADIUS = 12000
local ATMOSPHERE_BUFFER = 3000
local UPDATE_INTERVAL = 2

local RenderedPlanets = {}

local function CleanupOrphanedPlanetModels()
    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:match("^Planet_") then
            local found = false
            for _, tracked in pairs(RenderedPlanets) do
                if tracked == model then
                    found = true
                    break
                end
            end
            if not found then
                model:Destroy()
            end
        end
    end
end

local function IsPlanetOverlap(newPos, newSize)
    for _, planet in pairs(RenderedPlanets) do
        local atmosphere = planet:FindFirstChild("Atmosphere")
        if atmosphere then
            local dist = (atmosphere.Position - newPos).Magnitude
            local minDist = (atmosphere.Size.X + newSize) / 2 + ATMOSPHERE_BUFFER
            if dist < minDist then
                return true
            end
        end
    end
    return false
end


local function CreatePlanetMesh(data)
    local key = data.GridPos.X .. "_" .. data.GridPos.Y .. "_" .. data.GridPos.Z
    if RenderedPlanets[key] then return RenderedPlanets[key] end

    local count = 0
    for _, planet in pairs(RenderedPlanets) do
        if planet.PrimaryPart then count = count + 1 end
    end
    if count >= MAX_RENDERED_PLANETS then return nil end

    if data.IsHome then
        for _, planet in pairs(RenderedPlanets) do
            if planet.PrimaryPart and planet.PrimaryPart:GetAttribute("IsHome") then
                return planet
            end
        end
    end

    local worldPos = Vector3.new(data.WorldPos.X, data.WorldPos.Y, data.WorldPos.Z)
    if not data.IsHome and IsPlanetOverlap(worldPos, data.Size) then
        warn("Skipping planet due to overlap:", key)
        return nil
    end

    local biomeColor = Color3.new(data.Biome.Color.R, data.Biome.Color.G, data.Biome.Color.B)
    local planetModel = Instance.new("Model")
    planetModel.Name = "Planet_" .. key

    local atmosphere = Instance.new("Part")
    atmosphere.Name = "Atmosphere"
    atmosphere.Size = Vector3.new(data.Size, data.Size, data.Size)
    atmosphere.Position = worldPos
    atmosphere.Anchored = true
    atmosphere.CanCollide = false
    atmosphere.Material = Enum.Material.ForceField
    atmosphere.Color = biomeColor
    atmosphere.Shape = Enum.PartType.Ball
    atmosphere.Material = Enum.Material.Neon
    atmosphere.Transparency = 0
    atmosphere.Parent = planetModel

    -- Create classic baseplate ground (grid of small Parts) with randomization by planet content
    local tileSize = 8
    local groundHeight = 4
    local numTiles = math.floor((data.Size * 0.5) / tileSize)
    local startPos = worldPos + Vector3.new(-numTiles * tileSize / 2 + tileSize / 2, -10, -numTiles * tileSize / 2 + tileSize / 2)
    local groundFolder = Instance.new("Folder")
    groundFolder.Name = "GroundTiles"
    groundFolder.Parent = planetModel
    local seed = (data.Seed or 0) + (data.Biome and (data.Biome.Name:len() * 1000) or 0)
    math.randomseed(seed)
    local surfaceType = data.SurfaceType or Enum.SurfaceType.Studs
    for x = 0, numTiles - 1 do
        for z = 0, numTiles - 1 do
            local tile = Instance.new("Part")
            tile.Name = "Tile"
            tile.Size = Vector3.new(tileSize, groundHeight, tileSize)
            tile.Anchored = true
            tile.Material = Enum.Material.Plastic
            -- Áp dụng surfaceType từ server cho tất cả mặt
            tile.TopSurface = surfaceType
            tile.BottomSurface = surfaceType
            tile.FrontSurface = surfaceType
            tile.BackSurface = surfaceType
            tile.LeftSurface = surfaceType
            tile.RightSurface = surfaceType
            -- Randomize color and height by planet biome/content
            local baseColor = Color3.fromRGB(106, 127, 63)
            if data.Biome and data.Biome.Name == "Desert" then
                baseColor = Color3.fromRGB(220, 180, 100)
            elseif data.Biome and data.Biome.Name == "Ocean" then
                baseColor = Color3.fromRGB(30, 100, 180)
            elseif data.Biome and data.Biome.Name == "Forest" then
                baseColor = Color3.fromRGB(50, 150, 50)
            elseif data.Biome and data.Biome.Name == "Ice" then
                baseColor = Color3.fromRGB(200, 230, 255)
            elseif data.Biome and data.Biome.Name == "Volcanic" then
                baseColor = Color3.fromRGB(80, 40, 20)
            elseif data.Biome and data.Biome.Name == "Toxic" then
                baseColor = Color3.fromRGB(150, 255, 50)
            elseif data.Biome and data.Biome.Name == "Crystal" then
                baseColor = Color3.fromRGB(200, 100, 255)
            elseif data.Biome and data.Biome.Name == "Glitch" then
                baseColor = Color3.fromRGB(255, 0, 255)
            end
            -- Slight random variation
            local colorOffset = math.random(-10, 10)
            tile.Color = Color3.new(
                math.clamp(baseColor.R + colorOffset/255, 0, 1),
                math.clamp(baseColor.G + colorOffset/255, 0, 1),
                math.clamp(baseColor.B + colorOffset/255, 0, 1)
            )
            tile.Reflectance = 0
            tile.CastShadow = false -- Tắt bóng đổ để baseplate luôn sáng
            tile.Position = startPos + Vector3.new(x * tileSize, math.random(-1,1), z * tileSize)
            tile.Parent = groundFolder
        end
    end
    -- Set PrimaryPart to first tile for teleport/spawn
    if #groundFolder:GetChildren() > 0 then
        planetModel.PrimaryPart = groundFolder:GetChildren()[1]
    elseif planetModel:FindFirstChild("Atmosphere") then
        planetModel.PrimaryPart = planetModel.Atmosphere
    end
    planetModel.Parent = workspace
    RenderedPlanets[key] = planetModel
    -- Store sky index for this planet (from server)
    planetModel:SetAttribute("SkyPresetIndex", data.SkyPresetIndex or 1)
    -- Store sky name for this planet (from client)
    planetModel:SetAttribute("SkyPresetName", data.SkyPresetName or "")
    -- Store Bloom data for this planet
    if data.Bloom then
        planetModel:SetAttribute("Bloom", HttpService:JSONEncode(data.Bloom))
    end
    return planetModel
end

local function CleanupDistantPlanets(playerPos)
    local count = 0
    local keepKeys = {}
    for key, planet in pairs(RenderedPlanets) do
        if planet and planet.PrimaryPart then
            local distance = (planet.PrimaryPart.Position - playerPos).Magnitude
            local isHome = planet.PrimaryPart:GetAttribute("IsHome")
            if isHome or distance < PLANET_SPAWN_RADIUS then
                count = count + 1
                keepKeys[key] = true
            end
        end
    end
    if count > MAX_RENDERED_PLANETS then
        local planetsList = {}
        for key, planet in pairs(RenderedPlanets) do
            if planet and planet.PrimaryPart and not planet.PrimaryPart:GetAttribute("IsHome") then
                local distance = (planet.PrimaryPart.Position - playerPos).Magnitude
                table.insert(planetsList, {key = key, dist = distance})
            end
        end
        table.sort(planetsList, function(a, b) return a.dist > b.dist end)
        local toRemove = count - MAX_RENDERED_PLANETS
        for i = 1, toRemove do
            local entry = planetsList[i]
            if entry and RenderedPlanets[entry.key] then
                RenderedPlanets[entry.key]:Destroy()
                RenderedPlanets[entry.key] = nil
            end
        end
    end
    local allKeys, homeKey = {}, nil
    for key, planet in pairs(RenderedPlanets) do
        if planet and planet.PrimaryPart then
            if planet.PrimaryPart:GetAttribute("IsHome") then
                homeKey = key
            else
                table.insert(allKeys, key)
            end
        end
    end
    while (#allKeys + (homeKey and 1 or 0)) > MAX_RENDERED_PLANETS do
        local key = table.remove(allKeys)
        if key and RenderedPlanets[key] then
            RenderedPlanets[key]:Destroy()
            RenderedPlanets[key] = nil
        end
    end
    CleanupOrphanedPlanetModels()
end

local SkiesFolder = ReplicatedStorage:WaitForChild("Skies")

local function GetAllSkyPresets()
    local skies = {}
    for _, obj in ipairs(SkiesFolder:GetChildren()) do
        if obj:IsA("Sky") then
            table.insert(skies, obj)
        end
    end
    table.sort(skies, function(a, b) return a.Name < b.Name end) -- Ensure order is stable
    return skies
end

local function GetSkyByIndex(idx)
    local skies = GetAllSkyPresets()
    if #skies == 0 then return nil end
    idx = ((idx - 1) % #skies) + 1
    return skies[idx]
end

local function GetSkyByName(name)
    for _, obj in ipairs(SkiesFolder:GetChildren()) do
        if obj:IsA("Sky") and obj.Name == name then
            return obj
        end
    end
    return nil
end

local DEFAULT_SPACE_SKY_NAME = "space"

local function HideOtherPlanets(exceptKey)
    for key, planet in pairs(RenderedPlanets) do
        if key ~= exceptKey then
            planet.Parent = nil -- Hide from workspace
        else
            planet.Parent = workspace
        end
    end
end

local function ShowAllPlanets()
    for key, planet in pairs(RenderedPlanets) do
        planet.Parent = workspace
    end
end

local function ApplyPlanetBloom(bloomData)
    if not bloomData then
        print("[PlanetController] No bloom data, using default.")
        return
    end
    print("[PlanetController] Applying Bloom:", HttpService:JSONEncode(bloomData))
    Lighting.Brightness = bloomData.Brightness or 2
    Lighting.Ambient = Color3.new(1,1,1) -- Đảm bảo sáng đều
    Lighting.OutdoorAmbient = Color3.new(1,1,1)
    Lighting.EnvironmentDiffuseScale = 1
    Lighting.EnvironmentSpecularScale = 1
    -- Remove old bloom
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("BloomEffect") then obj:Destroy() end
    end
    -- Add new bloom
    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = bloomData.BloomIntensity or 0.2
    bloom.Size = bloomData.BloomSize or 24
    bloom.Threshold = bloomData.BloomThreshold or 1
    bloom.Parent = Lighting
end

local function ResetToDefaultBloom()
    print("[PlanetController] Reset to default bloom.")
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(127,127,127)
    Lighting.OutdoorAmbient = Color3.fromRGB(127,127,127)
    Lighting.EnvironmentDiffuseScale = 1
    Lighting.EnvironmentSpecularScale = 1
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("BloomEffect") then obj:Destroy() end
    end
end

local lastPlanetKey = nil
local lastSkyClone = nil
local insideAtmosphere = false
local function UpdatePlanetSky(playerPos)
    local closestKey, closestDist, closestPlanet, closestAtmosphere, closestRadius = nil, math.huge, nil, nil, nil
    for key, planet in pairs(RenderedPlanets) do
        local atmosphere = planet:FindFirstChild("Atmosphere")
        if atmosphere then
            local dist = (atmosphere.Position - playerPos).Magnitude
            local radius = atmosphere.Size.X/2
            if dist < closestDist then
                closestDist = dist
                closestKey = key
                closestPlanet = planet
                closestAtmosphere = atmosphere
                closestRadius = radius
            end
        end
    end
    if closestPlanet and closestAtmosphere and closestDist < (closestRadius + 100) then
        if lastPlanetKey ~= closestKey or not insideAtmosphere then
            if lastSkyClone then lastSkyClone:Destroy() end
            local skyName = closestPlanet:GetAttribute("SkyPresetName") or closestPlanet.SkyPresetName or (closestPlanet._data and closestPlanet._data.SkyPresetName)
            local src = GetSkyByName(skyName)
            if src and src:IsA("Sky") then
                lastSkyClone = src:Clone()
                for _, obj in ipairs(Lighting:GetChildren()) do
                    if obj:IsA("Sky") then obj:Destroy() end
                end
                lastSkyClone.Parent = Lighting
            end
            -- Áp dụng bloom/ánh sáng từ server
            local bloomData = nil
            local bloomAttr = closestPlanet:GetAttribute("Bloom")
            if bloomAttr then
                local ok, decoded = pcall(function() return HttpService:JSONDecode(bloomAttr) end)
                if ok then bloomData = decoded end
            end
            ApplyPlanetBloom(bloomData)
            HideOtherPlanets(closestKey)
            lastPlanetKey = closestKey
            insideAtmosphere = true
        end
    else
        if insideAtmosphere or lastPlanetKey ~= nil then
            if lastSkyClone then lastSkyClone:Destroy() lastSkyClone = nil end
            -- Apply default space sky
            local spaceSky = GetSkyByName(DEFAULT_SPACE_SKY_NAME)
            if spaceSky then
                for _, obj in ipairs(Lighting:GetChildren()) do
                    if obj:IsA("Sky") then obj:Destroy() end
                end
                spaceSky:Clone().Parent = Lighting
            end
            ResetToDefaultBloom()
            ShowAllPlanets()
            insideAtmosphere = false
            lastPlanetKey = nil
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

        local homePlanetPos = nil

        -- 1. Always create/render home planet first and teleport player onto it
        local homePlanetData = nil
        do
            local pos = Vector3.new(0, PLANET_Y, 0)
            local success, planets = pcall(function()
                return GetPlanetsRemote:InvokeServer(pos)
            end)
            if success and planets then
                for _, data in ipairs(planets) do
                    if data.IsHome then
                        data.WorldPos.Y = PLANET_Y
                        homePlanetData = data
                        break
                    end
                end
            end
        end
        assert(homePlanetData, "Home planet data not found!")
        local homePlanetModel = CreatePlanetMesh(homePlanetData)
        assert(homePlanetModel, "Home planet model not created!")
        -- Teleport player onto home planet
        local spawnCFrame = nil
        local homeSpawn = homePlanetModel:FindFirstChild("HomeSpawn")
        if homeSpawn then
            spawnCFrame = homeSpawn.CFrame + Vector3.new(0, homeSpawn.Size.Y/2 + 3, 0)
        else
            local ground = homePlanetModel:FindFirstChild("Ground")
            if ground then
                spawnCFrame = ground.CFrame + Vector3.new(0, ground.Size.Y/2 + 3, 0)
            end
        end
        if spawnCFrame then
            rootPart.CFrame = spawnCFrame
        else
            rootPart.CFrame = CFrame.new(Vector3.new(homePlanetData.WorldPos.X, homePlanetData.WorldPos.Y + 30, homePlanetData.WorldPos.Z))
        end
        rootPart.Anchored = false

        -- 2. Now render neighbors and other planets as before
        local function RenderNeighborsAndOthers()
            local gridOffsets = {
                {1,0,0}, {-1,0,0}, {0,1,0}, {0,-1,0}, {0,0,1}, {0,0,-1},
            }
            local renderedKeys = {}
            -- Mark home planet as rendered
            local homeKey = homePlanetData.GridPos.X .. "_" .. homePlanetData.GridPos.Y .. "_" .. homePlanetData.GridPos.Z
            renderedKeys[homeKey] = true
            -- Render neighbors
            for _, offset in ipairs(gridOffsets) do
                local gx = homePlanetData.GridPos.X + offset[1]
                local gy = homePlanetData.GridPos.Y + offset[2]
                local gz = homePlanetData.GridPos.Z + offset[3]
                local pos = Vector3.new(gx * 1800, PLANET_Y + gy * 1800, gz * 1800)
                local success, planets = pcall(function()
                    return GetPlanetsRemote:InvokeServer(pos)
                end)
                if success and planets then
                    for _, data in ipairs(planets) do
                        data.WorldPos.Y = PLANET_Y + (data.GridPos.Y or gy) * 1800
                        local key = (data.GridPos.X or gx) .. "_" .. (data.GridPos.Y or gy) .. "_" .. (data.GridPos.Z or gz)
                        if not renderedKeys[key] and not data.IsHome then
                            renderedKeys[key] = true
                            CreatePlanetMesh(data)
                        end
                    end
                end
            end
            -- Fill up to MAX_RENDERED_PLANETS with other nearby planets
            local count = 0
            for _, planet in pairs(RenderedPlanets) do
                if planet.PrimaryPart then count = count + 1 end
            end
            if count < MAX_RENDERED_PLANETS then
                local playerPos = Vector3.new(homePlanetData.WorldPos.X, PLANET_Y, homePlanetData.WorldPos.Z)
                local success, planets = pcall(function()
                    return GetPlanetsRemote:InvokeServer(playerPos)
                end)
                if success and planets then
                    for _, data in ipairs(planets) do
                        if count >= MAX_RENDERED_PLANETS then break end
                        data.WorldPos.Y = PLANET_Y
                        local key = data.GridPos.X .. "_" .. data.GridPos.Y .. "_" .. data.GridPos.Z
                        if not renderedKeys[key] and not data.IsHome then
                            if not IsPlanetOverlap(Vector3.new(data.WorldPos.X, data.WorldPos.Y, data.WorldPos.Z), data.Size) then
                                CreatePlanetMesh(data)
                                count = count + 1
                            end
                        end
                    end
                end
            end
            -- Cleanup if over cap
            local allKeys, homeKey2 = {}, nil
            for key, planet in pairs(RenderedPlanets) do
                if planet and planet.PrimaryPart then
                    if planet.PrimaryPart:GetAttribute("IsHome") then
                        homeKey2 = key
                    else
                        table.insert(allKeys, key)
                    end
                end
            end
            while (#allKeys + (homeKey2 and 1 or 0)) > MAX_RENDERED_PLANETS do
                local key = table.remove(allKeys)
                if key and RenderedPlanets[key] then
                    RenderedPlanets[key]:Destroy()
                    RenderedPlanets[key] = nil
                end
            end
            CleanupOrphanedPlanetModels()
        end

        RenderNeighborsAndOthers()

        local function StreamPlanets()
            if not rootPart or not rootPart.Parent then return end
            local playerPos = rootPart.Position
            local count = 0
            for _, planet in pairs(RenderedPlanets) do
                if planet.PrimaryPart then count = count + 1 end
            end
            if count > MAX_RENDERED_PLANETS then
                local allKeys, homeKey = {}, nil
                for key, planet in pairs(RenderedPlanets) do
                    if planet and planet.PrimaryPart then
                        if planet.PrimaryPart:GetAttribute("IsHome") then
                            homeKey = key
                        else
                            table.insert(allKeys, key)
                        end
                    end
                end
                while (#allKeys + (homeKey and 1 or 0)) > MAX_RENDERED_PLANETS do
                    local key = table.remove(allKeys)
                    if key and RenderedPlanets[key] then
                        RenderedPlanets[key]:Destroy()
                        RenderedPlanets[key] = nil
                    end
                end
                CleanupOrphanedPlanetModels()
                return
            end
            if count >= MAX_RENDERED_PLANETS then return end
            local success, planets = pcall(function()
                return GetPlanetsRemote:InvokeServer(playerPos)
            end)
            if success and planets then
                local added = 0
                for _, data in ipairs(planets) do
                    data.WorldPos.Y = PLANET_Y
                    if not data.IsHome then
                        if added + count < MAX_RENDERED_PLANETS and not IsPlanetOverlap(Vector3.new(data.WorldPos.X, data.WorldPos.Y, data.WorldPos.Z), data.Size) then
                            CreatePlanetMesh(data)
                            added = added + 1
                        end
                    end
                end
            end
        end

        task.spawn(function()
            while true do
                StreamPlanets()
                CleanupDistantPlanets(rootPart.Position)
                UpdatePlanetSky(rootPart.Position)
                task.wait(UPDATE_INTERVAL)
            end
        end)
        print("🌍 Planet controller initialized (client-side rendering)")
    end)
end

return PlanetController
