local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Knit = require(ReplicatedStorage.Packages.Knit)

local PlanetAtmosphereController = Knit.CreateController { Name = "PlanetAtmosphereController" }

local CurrentPlanet = nil
local OriginalLighting = {}

-- Biome lighting configurations
local BiomeLighting = {
	Desert = {
		Ambient = Color3.fromRGB(255, 200, 150),
		OutdoorAmbient = Color3.fromRGB(255, 220, 180),
		Brightness = 3,
		FogColor = Color3.fromRGB(255, 200, 150),
		FogEnd = 1000,
		FogStart = 100
	},
	Ocean = {
		Ambient = Color3.fromRGB(100, 150, 255),
		OutdoorAmbient = Color3.fromRGB(120, 180, 255),
		Brightness = 2,
		FogColor = Color3.fromRGB(100, 150, 255),
		FogEnd = 800,
		FogStart = 50
	},
	Forest = {
		Ambient = Color3.fromRGB(100, 200, 100),
		OutdoorAmbient = Color3.fromRGB(120, 220, 120),
		Brightness = 2.5,
		FogColor = Color3.fromRGB(100, 200, 100),
		FogEnd = 900,
		FogStart = 80
	},
	Ice = {
		Ambient = Color3.fromRGB(200, 230, 255),
		OutdoorAmbient = Color3.fromRGB(220, 240, 255),
		Brightness = 2.8,
		FogColor = Color3.fromRGB(200, 230, 255),
		FogEnd = 1200,
		FogStart = 150
	},
	Volcanic = {
		Ambient = Color3.fromRGB(255, 100, 50),
		OutdoorAmbient = Color3.fromRGB(255, 120, 70),
		Brightness = 1.5,
		FogColor = Color3.fromRGB(150, 50, 30),
		FogEnd = 600,
		FogStart = 30
	},
	Toxic = {
		Ambient = Color3.fromRGB(150, 255, 50),
		OutdoorAmbient = Color3.fromRGB(180, 255, 80),
		Brightness = 2,
		FogColor = Color3.fromRGB(150, 255, 50),
		FogEnd = 700,
		FogStart = 40
	},
	Crystal = {
		Ambient = Color3.fromRGB(200, 150, 255),
		OutdoorAmbient = Color3.fromRGB(220, 180, 255),
		Brightness = 3.5,
		FogColor = Color3.fromRGB(200, 150, 255),
		FogEnd = 1500,
		FogStart = 200
	},
	Glitch = {
		Ambient = Color3.fromRGB(255, 0, 255),
		OutdoorAmbient = Color3.fromRGB(255, 50, 255),
		Brightness = 2,
		FogColor = Color3.fromRGB(255, 0, 255),
		FogEnd = 500,
		FogStart = 20
	}
}

local function SaveOriginalLighting()
	if not next(OriginalLighting) then
		OriginalLighting = {
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			Brightness = Lighting.Brightness,
			FogColor = Lighting.FogColor,
			FogEnd = Lighting.FogEnd,
			FogStart = Lighting.FogStart
		}
	end
end

local function ApplyPlanetLighting(biomeName)
	local config = BiomeLighting[biomeName]
	if not config then return end
	
	-- Smooth transition
	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	
	game:GetService("TweenService"):Create(Lighting, tweenInfo, {
		Ambient = config.Ambient,
		OutdoorAmbient = config.OutdoorAmbient,
		Brightness = config.Brightness,
		FogColor = config.FogColor,
		FogEnd = config.FogEnd,
		FogStart = config.FogStart
	}):Play()
	
	print("🌍 Entered", biomeName, "biome atmosphere")
end

local function RestoreSpaceLighting()
	if not next(OriginalLighting) then return end
	
	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	
	game:GetService("TweenService"):Create(Lighting, tweenInfo, OriginalLighting):Play()
	
	print("🚀 Exited planet atmosphere - returned to space")
end

local function CheckInsideAtmosphere(playerPos, atmosphere)
	local distance = (playerPos - atmosphere.Position).Magnitude
	local radius = atmosphere.Size.X / 2
	return distance < radius
end

function PlanetAtmosphereController:KnitStart()
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart")
	
	SaveOriginalLighting()
	
	-- Check atmosphere every frame
	RunService.RenderStepped:Connect(function()
		if not rootPart or not rootPart.Parent then return end
		
		local playerPos = rootPart.Position
		local insidePlanet = nil
		
		-- Find closest planet atmosphere
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj.Name:match("^Planet_") then
				local atmosphere = obj:FindFirstChild("Atmosphere")
				if atmosphere and CheckInsideAtmosphere(playerPos, atmosphere) then
					insidePlanet = atmosphere
					break
				end
			end
		end
		
		-- Handle entering/exiting planet
		if insidePlanet and insidePlanet ~= CurrentPlanet then
			-- Entered new planet
			CurrentPlanet = insidePlanet
			local biomeName = insidePlanet:GetAttribute("BiomeName")
			if biomeName then
				ApplyPlanetLighting(biomeName)
			end
		elseif not insidePlanet and CurrentPlanet then
			-- Exited planet
			CurrentPlanet = nil
			RestoreSpaceLighting()
		end
	end)
	
	print("🌌 Planet Atmosphere Controller Online")
end

return PlanetAtmosphereController
