local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Load all Controllers automatically
for _, file in ipairs(StarterPlayer.StarterPlayerScripts.Controllers:GetChildren()) do
    if file:IsA("ModuleScript") and file.Name:match("Controller$") then
        require(file)
    end
end

Knit.Start():catch(warn):await()
print("[CLIENT] Knit Started")