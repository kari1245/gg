local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local NftEarningService = Knit.CreateService {
	Name = "NftEarningService",
	Client = {}
}

local EarningConfig = GameConfig.NftEarning

function NftEarningService:KnitInit()
	self.DataService = Knit.GetService("DataService")
	self.InventoryService = Knit.GetService("InventoryService")
	self.EconomyService = Knit.GetService("EconomyService")
end

-- Initialize player data
local function getPlayerData(service, player)
	local profile = service.DataService:GetProfile(player)
	if not profile then return nil end
	
	-- Ensure NftEarning data exists in profile
	if not profile.Data.NftEarning then
		profile.Data.NftEarning = {
			StakedNfts = {},
			EquippedNfts = {}
		}
	end
	
	return profile.Data.NftEarning
end

function NftEarningService:KnitStart()
	local Players = game:GetService("Players")
	
	-- Passive income loop - every 60 seconds (only for EQUIPPED NFTs)
	task.spawn(function()
		while true do
			task.wait(60) -- Check every minute
			for _, player in ipairs(Players:GetPlayers()) do
				local data = getPlayerData(self, player)
				if data then
					self:ProcessEquippedRewards(player, data)
				end
			end
		end
	end)
	
	print("💎 [NftEarningService] NFT Earning System Online")
end

-- Process passive income for EQUIPPED NFTs only (called every minute)
function NftEarningService:ProcessEquippedRewards(player, data)
	local now = tick()
	local inventory = self.InventoryService.Client:GetData(player)
	
	-- Only process equipped NFTs
	for _, equippedId in ipairs(data.EquippedNfts) do
		-- Find NFT in inventory
		local nft = nil
		for _, item in ipairs(inventory) do
			if item.Hash == equippedId then
				nft = item
				break
			end
		end
		
		if nft then
			local rarity = nft.Rarity
			local hourlyRate = EarningConfig.Earning[rarity].HourlyRate
			
			-- Each NFT earns passive income per minute
			local rewardPerMinute = hourlyRate / 60
			local reward = math.floor(rewardPerMinute)
			
			if reward > 0 then
				self.EconomyService:ModifyWallet(player, reward)
				-- Track total earned for achievements
				local profile = self.DataService:GetProfile(player)
				if profile then
					profile.Data.TotalEarned = (profile.Data.TotalEarned or 0) + reward
					-- Check achievements after earning
					local AchievementService = Knit.GetService("AchievementService")
					AchievementService:Check(player)
				end
				print("💰 [NftEarning] Player", player.Name, "earned $"..reward.." from equipped", rarity, "NFT")
			end
		end
	end
end

-- Stake NFT
function NftEarningService.Client:StakeNft(player, nftId)
	local data = getPlayerData(self.Server, player)
	
	-- Check if NFT exists in inventory
	local inventory = self.Server.InventoryService.Client:GetData(player)
	local nft = nil
	for _, item in ipairs(inventory) do
		if item.Hash == nftId then
			nft = item
			break
		end
	end
	
	if not nft then
		return false, "NFT_NOT_FOUND"
	end
	
	-- Check if already staked or equipped
	for _, stake in ipairs(data.StakedNfts) do
		if stake.NftId == nftId then
			return false, "ALREADY_STAKED"
		end
	end
	
	for _, equippedId in ipairs(data.EquippedNfts) do
		if equippedId == nftId then
			return false, "ALREADY_EQUIPPED"
		end
	end
	
	-- Add to staking
	table.insert(data.StakedNfts, {
		NftId = nftId,
		Rarity = nft.Rarity,
		StartTime = tick()
	})
	
	print("🔒 [NftEarning] Player", player.Name, "staked", nft.Rarity, "NFT")
	return true, "SUCCESS"
end

-- Unstake NFT and collect rewards
function NftEarningService.Client:UnstakeNft(player, nftId)
	local data = getPlayerData(self.Server, player)
	
	-- Find staked NFT
	local stakeIndex = nil
	local stake = nil
	for i, s in ipairs(data.StakedNfts) do
		if s.NftId == nftId then
			stakeIndex = i
			stake = s
			break
		end
	end
	
	if not stake then
		return false, "NOT_STAKED", 0
	end
	
	-- Check minimum lock time
	local elapsedTime = tick() - stake.StartTime
	local minLockTime = EarningConfig.Staking[stake.Rarity].MinLockTime
	if elapsedTime < minLockTime then
		local remaining = math.ceil((minLockTime - elapsedTime) / 60)
		return false, "LOCK_TIME_REMAINING", remaining
	end
	
	-- Calculate final reward
	local elapsedHours = elapsedTime / 3600
	local hourlyRate = EarningConfig.Staking[stake.Rarity].HourlyRate
	local reward = math.floor(hourlyRate * elapsedHours)
	
	-- Give reward
	self.Server.EconomyService:ModifyWallet(player, reward)
	
	-- Remove from staking
	table.remove(data.StakedNfts, stakeIndex)
	
	print("🔓 [NftEarning] Player", player.Name, "unstaked NFT and earned $"..reward)
	return true, "SUCCESS", reward
end

-- Equip NFT for passive income
function NftEarningService.Client:EquipNft(player, nftId)
	local data = getPlayerData(self.Server, player)
	
	-- Check max slots (3 max)
	if #data.EquippedNfts >= EarningConfig.MaxEquippedSlots then
		return false, "MAX_SLOTS_REACHED"
	end
	
	-- Check if NFT exists
	local inventory = self.Server.InventoryService.Client:GetData(player)
	local nft = nil
	for _, item in ipairs(inventory) do
		if item.Hash == nftId then
			nft = item
			break
		end
	end
	
	if not nft then
		return false, "NFT_NOT_FOUND"
	end
	
	-- Check if already equipped or staked
	for _, equippedId in ipairs(data.EquippedNfts) do
		if equippedId == nftId then
			return false, "ALREADY_EQUIPPED"
		end
	end
	
	for _, stake in ipairs(data.StakedNfts) do
		if stake.NftId == nftId then
			return false, "ALREADY_STAKED"
		end
	end
	
	-- Equip
	print("🔍 [DEBUG] Before insert - data:", data)
	print("🔍 [DEBUG] Before insert - data.EquippedNfts:", data.EquippedNfts)
	print("🔍 [DEBUG] Before insert - count:", #data.EquippedNfts)
	print("🔍 [DEBUG] Inserting nftId:", nftId)
	
	table.insert(data.EquippedNfts, nftId)
	print("⚡ [NftEarning] Player", player.Name, "equipped", nft.Rarity, "NFT")
	return true, "SUCCESS"
end

-- Unequip NFT
function NftEarningService.Client:UnequipNft(player, nftId)
	local data = getPlayerData(self.Server, player)
	
	-- Find and remove
	for i, equippedId in ipairs(data.EquippedNfts) do
		if equippedId == nftId then
			table.remove(data.EquippedNfts, i)
			print("💤 [NftEarning] Player", player.Name, "unequipped NFT")
			return true, "SUCCESS"
		end
	end
	
	return false, "NOT_EQUIPPED"
end

-- Get staking info
function NftEarningService.Client:GetStakingInfo(player)
	local data = getPlayerData(self.Server, player)
	if not data then
		return { StakedNfts = {}, EquippedNfts = {} }
	end
	
	return {
		StakedNfts = data.StakedNfts or {},
		EquippedNfts = data.EquippedNfts or {}
	}
end

return NftEarningService
