local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local JobService = Knit.CreateService { Name = "JobService", Client = {} }

local COOLDOWN = 1.2
local LastSubmission = {}

function JobService:KnitInit()
	self.DataService = Knit.GetService("DataService")
	self.EconomyService = Knit.GetService("EconomyService") -- [FIX] Cần cái này để trả lương

	Players.PlayerRemoving:Connect(function(player) LastSubmission[player] = nil end)
end

function JobService:CompleteJob(player)
	local now = os.clock()
	local last = LastSubmission[player] or 0

	-- 1. Anti-Spam
	if (now - last) < COOLDOWN then return false end

	-- 2. Check Ngồi Ghế
	local char = player.Character
	local hum = char and char:FindFirstChild("Humanoid")
	local seat = hum and hum.SeatPart
	if not seat or seat.Name ~= "JobSeat" then return false end

	LastSubmission[player] = now

	-- 3. Trả Lương [FIX] Dùng EconomyService
	local reward = GameConfig.JobSystem.Reward or 50
	local success = self.EconomyService:ModifyWallet(player, reward)

	if success then
		print("💻 Job Paid:", player.Name, "+$"..reward)
		return true
	end
	return false
end

function JobService.Client:SubmitJob(player) 
	return self.Server:CompleteJob(player) 
end

return JobService