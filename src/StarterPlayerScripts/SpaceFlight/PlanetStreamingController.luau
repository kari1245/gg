local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local PlanetStreamingController = Knit.CreateController { Name = "PlanetStreamingController" }

-- LOD Settings - Extremely high distances to prevent disappearing
local LOD_DISTANCES = {
	Full = 50000,     -- Show full detail planet (50km)
	Simple = 100000,  -- Show simple sphere (100km)
	Far = 500000      -- Increased transparency but still visible (500km)
}

-- Cached planet instances (key = grid coordinates string)
local LoadedPlanets = {}
local LastPlayerPos = Vector3.zero
local UpdateInterval = 2 -- Check every 2 seconds


-- Create icon billboard
local function CreateIconLOD(data)
	local part = Instance.new("Part")
	part.Name = "Planet_LOD_Icon"
	part.Size = Vector3.new(1, 1, 1)
	part.Position = data.WorldPos
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(100, 100)
	billboard.AlwaysOnTop = true
	billboard.Parent = part
	
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromScale(1, 1)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://6031068420" -- Circle icon
	icon.ImageColor3 = data.Biome.Color
	icon.Parent = billboard
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 30)
	label.Position = UDim2.new(0, 0, 1, 5)
	label.BackgroundTransparency = 1
	label.Text = data.Biome.Name
	label.TextColor3 = data.Biome.Color
	label.Font = Enum.Font.Code
	label.TextSize = 18
	label.TextStrokeTransparency = 0.5
	label.Parent = billboard
	
	return part
end

function PlanetStreamingController:KnitStart()
	self.PlanetService = Knit.GetService("PlanetService")
	
	local player = Players.LocalPlayer
	
	-- Defer planet streaming initialization to avoid blocking initial load
	task.defer(function()
		local character = player.Character or player.CharacterAdded:Wait()
		local rootPart = character:WaitForChild("HumanoidRootPart")
		
		-- Wait for initial game load before starting planet streaming
		task.wait(2)
		
		-- Update LOD based on distance
	local function UpdateLOD(planetData, instance, distance)
		if distance <= LOD_DISTANCES.Full then
			-- Show full detail
			if instance.ClassName == "Part" and instance.Name:match("^Planet_") then
				instance.Transparency = 0
				instance.CanCollide = true
			end
		elseif distance <= LOD_DISTANCES.Simple then
			-- Reduced detail but solid
			if instance.ClassName == "Part" and instance.Name:match("^Planet_") then
				instance.Transparency = 0.3
				instance.CanCollide = false
			end
		elseif distance <= LOD_DISTANCES.Far then
			-- Very far but still visible
			if instance.ClassName == "Part" and instance.Name:match("^Planet_") then
				instance.Transparency = 0.6
				instance.CanCollide = false
			end
		else
			-- Extremely far - barely visible but not removed
			if instance.ClassName == "Part" and instance.Name:match("^Planet_") then
				instance.Transparency = 0.8
				instance.CanCollide = false
			end
		end
	end
	
	-- Stream planets periodically
	local function StreamPlanets()
		if not rootPart or not rootPart.Parent then return end
		
		local playerPos = rootPart.Position
		
		-- Request new planets from server if player moved significantly
		local distanceMoved = (playerPos - LastPlayerPos).Magnitude
		if distanceMoved > 1500 then -- Request when moved 1.5km
			LastPlayerPos = playerPos
			-- Request planets near new position (async)
			task.spawn(function()
				local success, planets = pcall(function()
					return self.PlanetService:RequestPlanetsNear(playerPos)
				end)
				if success and planets then
					print("🌍 Loaded", #planets, "planets near", playerPos)
				end
			end)
		end
		
		-- Update ALL planets in workspace, not just streamed ones
		for _, obj in ipairs(workspace:GetChildren()) do
			-- Check for both Model (new) and Part (old) planets
			if (obj:IsA("Model") or obj:IsA("Part")) and obj.Name:match("^Planet_") then
				local planet = obj:IsA("Model") and obj.PrimaryPart or obj
				if planet and planet:IsA("BasePart") and planet.Position then
					local planetPos = planet.Position
					local distance = (planetPos - playerPos).Magnitude
					UpdateLOD({WorldPos = planetPos}, planet, distance)
					
					-- Cache it
					local key = obj.Name:gsub("Planet_", "")
					LoadedPlanets[key] = obj
				end
			end
		end
	end
	
	-- Start streaming loop with lower priority
	task.spawn(function()
		while true do
			StreamPlanets()
			task.wait(UpdateInterval)
		end
	end)
	
	-- Deferred initial load
	task.wait(0.5)
	StreamPlanets()
	end) -- End defer
	
	print("🌍 Planet streaming controller initialized (deferred)")
	print("LOD Distances: Full=" .. LOD_DISTANCES.Full .. ", Simple=" .. LOD_DISTANCES.Simple .. ", Far=" .. LOD_DISTANCES.Far .. " (No unload)")
end

return PlanetStreamingController
