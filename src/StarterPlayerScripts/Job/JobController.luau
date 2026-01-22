local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local View = require(script.Parent.JobView)

local JobController = Knit.CreateController { Name = "JobController" }

function JobController:KnitStart()
	self.JobService = Knit.GetService("JobService")
	self.SoundController = Knit.GetController("SoundController")
	
	local scope = Fusion.scoped(Fusion)
	local IsWorking = scope:Value(false)
	local CurrentWord = scope:Value("...")
	
	local player = Players.LocalPlayer
	local function onChar(char)
		local hum = char:WaitForChild("Humanoid")
		hum.Seated:Connect(function(active, seat)
			local isJobSeat = (active and seat and seat.Name == "JobSeat")
			IsWorking:set(isJobSeat)
			if isJobSeat then
				self.JobService:RequestNewWord():andThen(function(word)
					CurrentWord:set(word)
				end)
			end
		end)
	end
	if player.Character then onChar(player.Character) end
	player.CharacterAdded:Connect(onChar)
	
	local ui = View.New(scope, {
		IsWorking = IsWorking,
		CurrentWord = CurrentWord,
		
		OnSubmit = function(text)
			-- [FIX] Đổi thành SubmitWork đúng với Service
			self.JobService:SubmitWork(text):andThen(function(success, msg)
				if success then
					if self.SoundController then self.SoundController:Play("SFX_Win") end
					self.JobService:RequestNewWord():andThen(function(w) CurrentWord:set(w) end)
				else
					if self.SoundController then self.SoundController:Play("UI_Error") end
				end
			end)
		end
	})
	ui.Parent = player:WaitForChild("PlayerGui")
end

return JobController