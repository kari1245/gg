local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local controllersFolder = script.Parent:WaitForChild("Controllers")
local controllers = {}

-- 1. Load Modules
for _, module in ipairs(controllersFolder:GetChildren()) do
	if module:IsA("ModuleScript") then
		local controller = require(module)
		controllers[controller.Name] = controller
	end
end

-- 2. Init Lifecycle
for _, controller in pairs(controllers) do
	if type(controller.Init) == "function" then
		controller:Init()
	end
end

-- 3. Start Lifecycle
for _, controller in pairs(controllers) do
	if type(controller.Start) == "function" then
		task.spawn(function()
			controller:Start()
		end)
	end
end

print("[CLIENT] Architecture Loaded")