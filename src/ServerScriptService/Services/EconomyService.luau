local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local EconomyService = Knit.CreateService {
	Name = "EconomyService",
	Client = {
		MoneyUpdated = Knit.CreateSignal(),
	}
}

function EconomyService:KnitInit()
	self.DataService = Knit.GetService("DataService")
end

function EconomyService:OnDataLoaded(player, data)
	self.Client.MoneyUpdated:Fire(player, data.Wallet, data.Vault)
	
	-- Trigger leaderboard update
	task.defer(function()
		local LeaderboardService = Knit.GetService("LeaderboardService")
		if LeaderboardService then
			LeaderboardService:RefreshPlayer(player)
		end
	end)
end

function EconomyService:ModifyWallet(player, amount)
	local profile = self.DataService:GetProfile(player)
	if not profile then return false end
	profile.Data.Wallet += amount
	self.Client.MoneyUpdated:Fire(player, profile.Data.Wallet, profile.Data.Vault)
	
	-- Refresh leaderboard
	task.defer(function()
		local LeaderboardService = Knit.GetService("LeaderboardService")
		if LeaderboardService then
			LeaderboardService:RefreshPlayer(player)
		end
	end)
	
	return true
end

function EconomyService:ModifyVault(player, amount)
	local profile = self.DataService:GetProfile(player)
	if not profile then return false end
	profile.Data.Vault += amount
	self.Client.MoneyUpdated:Fire(player, profile.Data.Wallet, profile.Data.Vault)
	
	-- Refresh leaderboard
	task.defer(function()
		local LeaderboardService = Knit.GetService("LeaderboardService")
		if LeaderboardService then
			LeaderboardService:RefreshPlayer(player)
		end
	end)
	
	return true
end

-- [FIX] Thêm hàm Transfer cho Bank
function EconomyService:Transfer(player, action, amount)
	local profile = self.DataService:GetProfile(player)
	if not profile then return false end
	local data = profile.Data
	
	amount = tonumber(amount)
	if not amount or amount <= 0 then return false end
	
	if action == "DEPOSIT" then
		if data.Wallet >= amount then
			data.Wallet -= amount
			data.Vault += amount
			self.Client.MoneyUpdated:Fire(player, data.Wallet, data.Vault)
			
			-- Refresh leaderboard
			task.defer(function()
				local LeaderboardService = Knit.GetService("LeaderboardService")
				if LeaderboardService then
					LeaderboardService:RefreshPlayer(player)
				end
			end)
			
			return true
		end
	elseif action == "WITHDRAW" then
		if data.Vault >= amount then
			data.Vault -= amount
			data.Wallet += amount
			self.Client.MoneyUpdated:Fire(player, data.Wallet, data.Vault)
			
			-- Refresh leaderboard
			task.defer(function()
				local LeaderboardService = Knit.GetService("LeaderboardService")
				if LeaderboardService then
					LeaderboardService:RefreshPlayer(player)
				end
			end)
			
			return true
		end
	end
	return false
end

-- Expose hàm Transfer và GetData cho Client
function EconomyService.Client:Transfer(player, action, amount)
	return self.Server:Transfer(player, action, amount)
end

function EconomyService.Client:GetData(player)
	local profile = self.Server.DataService:WaitForProfile(player) -- Dùng WaitForProfile
	if profile then
		return profile.Data.Wallet, profile.Data.Vault
	end
	return 0, 0
end

return EconomyService