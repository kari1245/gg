-- Setup space environment
local Lighting = game:GetService("Lighting")

-- Defer heavy loading to improve initial game load time
task.defer(function()
	-- Space lighting settings
	Lighting.Ambient = Color3.fromRGB(30, 30, 40) -- Increased ambient light
	Lighting.Brightness = 2 -- Increased brightness
	Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
	Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
	Lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 70) -- Brighter outdoor
	Lighting.FogEnd = 100000 -- Reduced fog distance for better visibility
	Lighting.FogStart = 0

	-- Wait a bit before loading skybox assets
	task.wait(0.5)

	-- Remove default skybox if exists
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") then
			child:Destroy()
		end
	end

	-- Create starfield skybox with ContentProvider preload
	local sky = Instance.new("Sky")
	sky.Name = "SpaceSkybox"
	
	-- Preload skybox assets asynchronously
	local skyboxAssets = {
		"rbxassetid://159454299",
		"rbxassetid://159454296",
		"rbxassetid://159454293",
		"rbxassetid://159454286",
		"rbxassetid://159454300",
		"rbxassetid://159454288"
	}
	
	task.spawn(function()
		game:GetService("ContentProvider"):PreloadAsync(skyboxAssets)
	end)
	
	sky.SkyboxBk = skyboxAssets[1]
	sky.SkyboxDn = skyboxAssets[2]
	sky.SkyboxFt = skyboxAssets[3]
	sky.SkyboxLf = skyboxAssets[4]
	sky.SkyboxRt = skyboxAssets[5]
	sky.SkyboxUp = skyboxAssets[6]
	sky.StarCount = 5000
	sky.Parent = Lighting

	-- Add atmosphere for space feel
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.1
	atmosphere.Offset = 0
	atmosphere.Color = Color3.fromRGB(10, 10, 20)
	atmosphere.Decay = Color3.fromRGB(5, 5, 10)
	atmosphere.Glare = 0
	atmosphere.Haze = 0
	atmosphere.Parent = Lighting

	print("🌌 Space environment configured!")
end)
