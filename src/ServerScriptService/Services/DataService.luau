local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)
local ProfileStore = require(ReplicatedStorage.Packages.ProfileStore)

local DataService = Knit.CreateService { Name = "DataService" }

local ProfileTemplate = {
	Wallet = GameConfig.StartingWallet,
	Vault = GameConfig.StartingVault,
	Stats = { Wins = 0, Losses = 0 },
	UnlockedTitles = { "NO_DATA" },
	CurrentTitle = "NO_DATA",
	NftInventory = {}
}

local GameProfileStore = ProfileStore.New("Production_NFT_v3", ProfileTemplate) -- Đổi key v3 để reset data sạch sẽ
local Profiles = {}

function DataService:GetProfile(player)
	return Profiles[player]
end

-- [QUAN TRỌNG] Hàm này giúp các Service khác chờ Data load xong
function DataService:WaitForProfile(player)
	if Profiles[player] then return Profiles[player] end
	
	local start = os.time()
	while not Profiles[player] do
		if not player.Parent then return nil end
		if os.time() - start > 10 then return nil end
		task.wait(0.1)
	end
	return Profiles[player]
end

function DataService:KnitInit()
	local function LoadProfile(player)
		local profile = GameProfileStore:StartSessionAsync("Player_" .. player.UserId, {
			Cancel = function() return player.Parent ~= Players end,
		})

		if profile then
			profile:AddUserId(player.UserId)
			profile:Reconcile()
			
			profile.OnSessionEnd:Connect(function()
				Profiles[player] = nil
				if player.Parent == Players then player:Kick("Session Lock Released") end
			end)

			if player:IsDescendantOf(Players) then
				Profiles[player] = profile
				
				-- Báo data đã load
				Knit.GetService("InventoryService"):OnDataLoaded(player, profile.Data)
				Knit.GetService("AchievementService"):OnDataLoaded(player, profile.Data)
				Knit.GetService("ShopService"):GenerateDailyShop(player)
				Knit.GetService("EconomyService"):OnDataLoaded(player, profile.Data)
			else
				profile:EndSession()
			end
		else
			player:Kick("Unable to load data. Please rejoin.")
		end
	end

	Players.PlayerAdded:Connect(LoadProfile)
	Players.PlayerRemoving:Connect(function(player) Profiles[player] = nil end)
	
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(LoadProfile, player) end
end

return DataService