-- Server-side RemoteFunction handler for planet metadata
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlanetService = require(script.Parent.PlanetService)
local GetPlanetsRemote = ReplicatedStorage:WaitForChild("GetPlanetsRemote")

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
		-- Nếu spam quá nhanh, trả về rỗng hoặc cảnh báo nhẹ (không kick ngay để tránh false positive do lag)
		return {} 
	end
	lastRequestTimes[player] = now

	-- [OPTIMIZATION 2] Server Authority - Ignote client's 'position' argument
	-- Server tự xác định vị trí của Player để đảm bảo tính trung thực.
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	
	if not rootPart then
		-- Player chưa load xong nhân vật hoặc đã chết
		return {}
	end

	local serverPosition = rootPart.Position

	-- Gọi logic lấy Planet dựa trên vị trí THỰC TẾ của player trên server
	return PlanetService:GetPlanetsNearPosition(serverPosition)
end