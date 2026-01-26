-- Server-side RemoteFunction handler for planet metadata
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ServerScriptService = game:GetService("ServerScriptService")
local PlanetService = require(ServerScriptService.Services.PlanetService)
local Promise = require(ReplicatedStorage.Packages.Promise)
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes") 
local GetPlanetsRemote = RemotesFolder:WaitForChild("GetPlanetsRemote")

-- [OPTIMIZATION] Rate Limiting Config
local REQUEST_COOLDOWN = 0.3 -- Giới hạn 1 request mỗi 0.3 giây
local lastRequestTimes = {}

-- Cleanup cooldown data when player leaves
Players.PlayerRemoving:Connect(function(player)
	lastRequestTimes[player] = nil
end)

GetPlanetsRemote.OnServerInvoke = function(player, clientSentPosition)
	-- [OPTIMIZATION 1] Rate Limiting Check
	local now = os.clock()
	local lastTime = lastRequestTimes[player] or 0
	if (now - lastTime) < REQUEST_COOLDOWN then
		return {}
	end
	lastRequestTimes[player] = now

	-- [OPTIMIZATION 2] Server Authority - Ignore client's 'position' argument
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return {}
	end
	local serverPosition = rootPart.Position

	-- Nếu muốn xử lý bất đồng bộ, có thể dùng Promise:
	-- return PlanetService:GetPlanetsNearPositionPromise(serverPosition):await()
	-- Hiện tại vẫn trả về sync để tương thích client cũ
	return PlanetService:GetPlanetsNearPosition(serverPosition)
end