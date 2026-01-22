local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.Knit)

-- Load tất cả Services
local servicesFolder = ServerScriptService:WaitForChild("Services")
for _, module in ipairs(servicesFolder:GetChildren()) do
	if module:IsA("ModuleScript") then
		require(module)
	end
end

Knit.Start():andThen(function()
	print("✅ [SERVER] GLITCH.21 SYSTEM ONLINE")
end):catch(warn)