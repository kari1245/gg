local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local JobService = Knit.CreateService {
	Name = "JobService",
	Client = {
		SubmitWork = Knit.CreateSignal() -- Client gọi hàm này (RemoteFunction style)
	}
}

-- Lưu từ khóa hiện tại của mỗi người chơi
local ActiveJobs = {}

function JobService:KnitInit()
	self.EconomyService = Knit.GetService("EconomyService")
end

-- [NEW] Hàm Client gọi để lấy từ khóa mới
function JobService.Client:RequestNewWord(player)
	local words = GameConfig.JobSystem.Words
	local word = words[math.random(1, #words)]
	ActiveJobs[player] = word
	return word
end

-- [FIX] Check đúng từ khóa Server đang lưu
function JobService.Client:SubmitWork(player, inputWord)
	local correctWord = ActiveJobs[player]
	
	if not correctWord then return false, "No active job" end
	
	if inputWord == correctWord then
		local reward = GameConfig.JobSystem.Reward
		self.Server.EconomyService:ModifyWallet(player, reward)
		
		-- Reset job
		ActiveJobs[player] = nil
		
		return true, "Correct! +$" .. reward
	else
		return false, "Invalid Hash!"
	end
end

return JobService