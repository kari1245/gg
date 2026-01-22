local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local EconomyService = Knit.CreateService {
	Name = "EconomyService",
	Client = { MoneyUpdated = Knit.CreateSignal() }
}

function EconomyService:KnitInit()
	self.DataService = Knit.GetService("DataService")
end

-- [QUAN TRỌNG] Hàm này bắt buộc phải có để DataService gọi
function EconomyService:OnDataLoaded(player, data)
	-- Gửi tiền về Client ngay khi dữ liệu load xong
	self.Client.MoneyUpdated:Fire(player, data.Wallet, data.Vault)
end

function EconomyService:ModifyWallet(player, amount)
	local profile = self.DataService:GetProfile(player)
	if not profile then return false end

	local data = profile.Data
	if data.Wallet + amount < 0 then return false end

	data.Wallet += amount
	self.Client.MoneyUpdated:Fire(player, data.Wallet, data.Vault)

	local AchService = Knit.GetService("AchievementService")
	if AchService then 
		AchService:Check(player) 
	end

	return true
end

function EconomyService:ModifyVault(player, action, amount)
	local profile = self.DataService:GetProfile(player)
	if not profile or amount <= 0 then return false end
	local data = profile.Data

	if action == "DEPOSIT" and data.Wallet >= amount then
		data.Wallet -= amount; data.Vault += amount
	elseif action == "WITHDRAW" and data.Vault >= amount then
		data.Vault -= amount; data.Wallet += amount
	else return false end

	self.Client.MoneyUpdated:Fire(player, data.Wallet, data.Vault)
	return true
end

function EconomyService.Client:GetMoney(player)
	local profile = self.Server.DataService:GetProfile(player)
	if profile then return profile.Data.Wallet, profile.Data.Vault end
	return 0, 0
end

function EconomyService.Client:Transfer(player, action, amount)
	return self.Server:ModifyVault(player, action, amount)
end

return EconomyService