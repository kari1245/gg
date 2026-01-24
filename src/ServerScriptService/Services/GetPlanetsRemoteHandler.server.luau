-- Server-side RemoteFunction handler for planet metadata
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlanetService = require(script.Parent.PlanetService)
local GetPlanetsRemote = ReplicatedStorage:WaitForChild("GetPlanetsRemote")

GetPlanetsRemote.OnServerInvoke = function(player, position)
	-- Validate input
	if typeof(position) ~= "Vector3" then
		warn("[GetPlanetsRemote] Invalid position from client", player, position)
		return {}
	end
	-- Call the existing logic
	return PlanetService:GetPlanetsNearPosition(position)
end
