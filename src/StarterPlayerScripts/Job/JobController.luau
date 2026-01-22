local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)
local View = require(script.Parent.JobView)

local JobController = Knit.CreateController { Name = "JobController" }

local MiningConfig = GameConfig.MiningSystem

function JobController:KnitStart()
	self.JobService = Knit.GetService("JobService")
	self.SoundController = Knit.GetController("SoundController")
	
	local scope = Fusion.scoped(Fusion)
	local IsWorking = scope:Value(false)
	local TotalMined = scope:Value(0)
	local TotalEarned = scope:Value(0)
	local LastReward = scope:Value(0)
	local StatusText = scope:Value("START_AUTO-MINE")
	local IsAutoMining = scope:Value(false)
	
	local player = Players.LocalPlayer
	local currentSeat = nil
	local isMining = false
	local autoMineLoop = nil
	
	-- Auto-mine function
	local function performAutoMine()
		if not Fusion.peek(IsAutoMining) or not Fusion.peek(IsWorking) then
			return
		end
		
		if isMining then return end
		
		isMining = true
		StatusText:set("MINING...")
		
		self.JobService:Mine():andThen(function(success, message, reward)
			isMining = false
			
			if success then
				TotalMined:set(Fusion.peek(TotalMined) + 1)
				TotalEarned:set(Fusion.peek(TotalEarned) + reward)
				LastReward:set(reward)
				
				if self.SoundController then 
					self.SoundController:Play("SFX_Win") 
				end
				
				StatusText:set("MINED_+$"..reward.."!")
			else
				if message == "COOLDOWN_ACTIVE" then
					StatusText:set("COOLING_DOWN...")
				end
				
				if self.SoundController then 
					self.SoundController:Play("UI_Error") 
				end
			end
		end):catch(function(err)
			isMining = false
			warn("Mining error:", err)
			StatusText:set("ERROR_OCCURRED")
		end)
	end
	
	-- Auto-mine loop
	local function startAutoMineLoop()
		if autoMineLoop then return end
		
		autoMineLoop = task.spawn(function()
			while Fusion.peek(IsAutoMining) and Fusion.peek(IsWorking) do
				performAutoMine()
				task.wait(MiningConfig.MineCooldown + 0.1)
			end
			autoMineLoop = nil
		end)
	end
	
	local function stopAutoMineLoop()
		if autoMineLoop then
			task.cancel(autoMineLoop)
			autoMineLoop = nil
		end
	end
	
	local function onChar(char)
		local hum = char:WaitForChild("Humanoid")
		print("⛏️ [JobController] Character loaded, connecting Seated event")
		hum.Seated:Connect(function(active, seat)
			print("⛏️ [JobController] Seated event:", active, seat and seat.Name or "nil")
			local isJobSeat = (active and seat and seat.Name == "JobSeat")
			print("⛏️ [JobController] isJobSeat:", isJobSeat)
			IsWorking:set(isJobSeat)
			currentSeat = isJobSeat and seat or nil
			
			if isJobSeat then
				-- Reset stats
				TotalMined:set(0)
				TotalEarned:set(0)
				LastReward:set(0)
				StatusText:set("START_AUTO-MINE")
				
				print("⛏️ [JobController] Starting work session")
			else
				print("⛏️ [JobController] Stopped working")
				-- Stop auto-mining when leaving seat
				IsAutoMining:set(false)
				stopAutoMineLoop()
			end
		end)
	end
	if player.Character then onChar(player.Character) end
	player.CharacterAdded:Connect(onChar)
	
	print("⛏️ [JobController] Creating UI with props:")
	print("  - IsWorking:", Fusion.peek(IsWorking))
	print("  - Stamina:", Fusion.peek(Stamina))
	print("  - MaxStamina:", Fusion.peek(MaxStamina))
	
	local ui = View.New(scope, {
		IsWorking = IsWorking,
		TotalMined = TotalMined,
		TotalEarned = TotalEarned,
		LastReward = LastReward,
		StatusText = StatusText,
		IsAutoMining = IsAutoMining,
		
		OnToggleAutoMine = function()
			if not Fusion.peek(IsWorking) then
				StatusText:set("SIT_IN_JOB_SEAT!")
				if self.SoundController then 
					self.SoundController:Play("UI_Error") 
				end
				return
			end
			
			local newState = not Fusion.peek(IsAutoMining)
			IsAutoMining:set(newState)
			
			if newState then
				StatusText:set("AUTO-MINING_STARTED")
				startAutoMineLoop()
				if self.SoundController then 
					self.SoundController:Play("UI_Click") 
				end
			else
				StatusText:set("AUTO-MINING_STOPPED")
				stopAutoMineLoop()
				if self.SoundController then 
					self.SoundController:Play("UI_Click") 
				end
			end
		end,
		
		OnExit = function()
			if currentSeat and player.Character then
				local hum = player.Character:FindFirstChild("Humanoid")
				if hum then
					hum.Sit = false
				end
			end
		end
	})
	ui.Parent = player:WaitForChild("PlayerGui")
end

return JobController