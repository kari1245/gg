local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local ProfileStore = require(ReplicatedStorage.Packages.ProfileStore)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local ProfileTemplate = {
	Wallet = GameConfig.StartingWallet,
	Vault = GameConfig.StartingVault,
	Stats = { Wins = 0, Losses = 0 },
	UnlockedTitles = { "NO_DATA" },
	CurrentTitle = "NO_DATA",
	Cosmetics = {},
	EquippedItem = nil
}

local GameProfileStore = ProfileStore.New("GLITCH_DATA_V20_FINAL", ProfileTemplate)

local DataService = Knit.CreateService {
	Name = "DataService",
	Client = { DataChanged = Knit.CreateSignal(), TitlesUpdated = Knit.CreateSignal() }
}

local Profiles = {}

function DataService:KnitInit()
	local function onPlayerAdded(player)
		local profile = GameProfileStore:StartSessionAsync(tostring(player.UserId), {
			Cancel = function() return player.Parent ~= Players end
		})

		if profile then
			profile:AddUserId(player.UserId)
			profile:Reconcile()
			profile.OnSessionEnd:Connect(function()
				Profiles[player] = nil
				player:Kick("Session Ended")
			end)

			if player:IsDescendantOf(Players) then
				Profiles[player] = profile
				-- Data đã tải xong, giờ mới báo cho các Service khác
				Knit.GetService("EconomyService"):OnDataLoaded(player, profile.Data)
				Knit.GetService("InventoryService"):OnDataLoaded(player, profile.Data)
				Knit.GetService("AchievementService"):OnDataLoaded(player, profile.Data)
			else
				profile:EndSession()
			end
		else
			player:Kick("Data Load Failed")
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(p) if Profiles[p] then Profiles[p]:EndSession() end end)
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, p) end
end

function DataService:GetProfile(player)
	-- [FIX] Chỉ đơn giản trả về Profiles[player] (có thể là nil nếu đang load)
	-- Không warn ở đây để tránh spam console khi nhân vật spawn trước data
	return Profiles[player]
end

function DataService.Client:GetProfileData(player)
	local profile = Profiles[player]
	if profile then return profile.Data end
end

return DataService