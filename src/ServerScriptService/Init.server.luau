local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Load all Services automatically
for _, file in ipairs(ServerScriptService.Services:GetChildren()) do
    if file:IsA("ModuleScript") and file.Name:match("Service$") then
        require(file)
    end
end

Knit.Start():catch(warn):await()
print("[SERVER] Knit Started")