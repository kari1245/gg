local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local View = require(script.Parent.JobView)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local JobController = Knit.CreateController { Name = "JobController" }

function JobController:KnitStart()
	self.JobService = Knit.GetService("JobService")
	self.SoundController = Knit.GetController("SoundController")

	local scope = Fusion.scoped(Fusion)
	local IsWorking = scope:Value(false)
	local CurrentWord = scope:Value("BOOT...")

	-- Logic Seat
	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid").Seated:Connect(function(active, seat)
			if active and seat and seat.Name == "JobSeat" then
				local words = GameConfig.JobSystem.Words
				CurrentWord:set(words[math.random(1, #words)])
				IsWorking:set(true)
			else
				IsWorking:set(false)
			end
		end)
	end)

	local ui = View.New(scope, {
		IsWorking = IsWorking, CurrentWord = CurrentWord,
		OnSubmit = function(text)
			local target = Fusion.peek(CurrentWord)
			if text == target then
				self.JobService:SubmitJob(text)
				if self.SoundController then self.SoundController:Play("SFX_Win") end
				-- New Word
				local words = GameConfig.JobSystem.Words
				CurrentWord:set(words[math.random(1, #words)])
			else
				if self.SoundController then self.SoundController:Play("UI_Error") end
			end
		end
	})
	ui.Parent = player:WaitForChild("PlayerGui")
end

return JobController