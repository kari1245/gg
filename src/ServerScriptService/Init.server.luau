local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local servicesFolder = ServerScriptService:WaitForChild("Services")
local services = {}

-- 1. Load Modules
for _, module in ipairs(servicesFolder:GetChildren()) do
	if module:IsA("ModuleScript") then
		local service = require(module)
		services[service.Name] = service
	end
end

-- 2. Init Lifecycle
for _, service in pairs(services) do
	if type(service.Init) == "function" then
		service:Init()
	end
end

-- 3. Start Lifecycle
for _, service in pairs(services) do
	if type(service.Start) == "function" then
		task.spawn(function()
			service:Start()
		end)
	end
end

print("[SERVER] Architecture Loaded")