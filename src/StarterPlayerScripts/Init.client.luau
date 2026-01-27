local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [FIX] Cast to any to prevent strict analysis issues
local Knit = require(ReplicatedStorage.Packages.Knit) :: any

-- [FIX] Reference the RUNNING folder in PlayerScripts, not the template in StarterPlayer
local Controllers = script.Parent:WaitForChild("Controllers")

-- [ARCHITECTURAL FIX] Use Knit's built-in loader.
-- This automatically loads all ModuleScripts in the folder.
Knit.AddControllers(Controllers)

Knit.Start():catch(warn):await()
print("[CLIENT] Knit Started")