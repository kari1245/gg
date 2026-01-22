local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local JobService = Knit.CreateService {
	Name = "JobService",
	Client = {}
}

local MiningConfig = GameConfig.MiningSystem

-- Player mining data
local PlayerMiningData = {}
-- userId -> { LastMineTime = tick() }

function JobService:KnitInit()
	self.EconomyService = Knit.GetService("EconomyService")
end

function JobService:KnitStart()
	local Players = game:GetService("Players")
	
	-- Connect PlayerRemoving
	Players.PlayerRemoving:Connect(function(player)
		self:PlayerRemoving(player)
	end)
	
	print("⛏️ [JobService] Mining System Online")
end

-- Initialize player data
local function getPlayerData(player)
	local userId = player.UserId
	if not PlayerMiningData[userId] then
		PlayerMiningData[userId] = {
			LastMineTime = 0
		}
	end
	return PlayerMiningData[userId]
end

-- Mine action với anti-cheat
function JobService.Client:Mine(player)
	local data = getPlayerData(player)
	local now = tick()
	
	print("⛏️ [JobService] Mine request from", player.Name)
	
	-- Check cooldown
	local timeSinceLastMine = now - data.LastMineTime
	if timeSinceLastMine < MiningConfig.MineCooldown then
		print("⛏️ [JobService] COOLDOWN for", player.Name)
		return false, "COOLDOWN_ACTIVE", 0
	end
	
	-- Update last mine time
	data.LastMineTime = now
	
	-- Calculate reward (weighted random)
	local totalWeight = 0
	for _, reward in ipairs(MiningConfig.Rewards) do
		totalWeight = totalWeight + reward.Weight
	end
	
	local roll = math.random(1, totalWeight)
	local currentWeight = 0
	local selectedReward = MiningConfig.Rewards[1].Amount
	
	for _, reward in ipairs(MiningConfig.Rewards) do
		currentWeight = currentWeight + reward.Weight
		if roll <= currentWeight then
			selectedReward = reward.Amount
			break
		end
	end
	
	-- Give reward
	self.Server.EconomyService:ModifyWallet(player, selectedReward)
	
	print("⛏️ [JobService] Mining SUCCESS for", player.Name, "- Reward:", selectedReward)
	
	return true, "SUCCESS", selectedReward
end

-- Cleanup khi player rời
function JobService:PlayerRemoving(player)
	PlayerMiningData[player.UserId] = nil
end

return JobService