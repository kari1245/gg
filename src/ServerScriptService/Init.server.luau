local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- [FIX] Cast to any to prevent strict analysis issues with the package
local Knit = require(ReplicatedStorage.Packages.Knit) :: any

-- [ARCHITECTURAL FIX] Use Knit's built-in loader instead of manual loops.
-- This is cleaner and resolves the "Unknown require" type error.
Knit.AddServices(ServerScriptService.Services)

Knit.Start():catch(warn):await()
print("[SERVER] Knit Started")