local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)
local ProfileStore = require(ReplicatedStorage.Packages.ProfileStore)

local DataService = Knit.CreateService { Name = "DataService" }

local ProfileTemplate = {
	Wallet = GameConfig.StartingWallet,
	Vault = GameConfig.StartingVault,
	TotalEarned = 0, -- Track total money earned from NFTs for achievements
	UnlockedTitles = { "NO_DATA" },
	CurrentTitle = "NO_DATA",
	NftInventory = {},
	NftShopData = {
		Items = {},
		LastRefreshDay = 0 -- Lưu ngày refresh (dạng số ngày kể từ epoch)
	}
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
				
				-- Initialize TotalEarned for existing profiles
				if not profile.Data.TotalEarned then
					profile.Data.TotalEarned = 0
				end
				
				-- Báo data đã load
				Knit.GetService("InventoryService"):OnDataLoaded(player, profile.Data)
				Knit.GetService("AchievementService"):OnDataLoaded(player, profile.Data)
				Knit.GetService("ShopService"):GenerateDailyShop(player)
				Knit.GetService("EconomyService"):OnDataLoaded(player, profile.Data)
				
				-- Spawn player on home planet
				task.defer(function()
					local char = player.Character or player.CharacterAdded:Wait()
					if char then
						-- Wait for home planet spawn location
						local homeSpawn = workspace:WaitForChild("HomeSpawn", 5)
						if homeSpawn then
							local rootPart = char:WaitForChild("HumanoidRootPart")
							rootPart.CFrame = homeSpawn.CFrame + Vector3.new(0, 5, 0)
							print("🚀 Spawned", player.Name, "on home planet")
						else
						-- Fallback: spawn above home planet at safe height
						local rootPart = char:WaitForChild("HumanoidRootPart")
						rootPart.CFrame = CFrame.new(0, 3100, 0) -- Y=3100 matches new home planet height + buffer
							print("⚠️ Fallback spawn for", player.Name)
						end
					end
				end)
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