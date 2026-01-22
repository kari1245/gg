local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local AchievementService = Knit.CreateService {
	Name = "AchievementService",
	Client = { AchievementUpdated = Knit.CreateSignal() }
}

-- Hàm Update Visual (Overhead)
local function UpdateOverhead(player, title)
	if not player then return end
	task.spawn(function()
		if not player.Parent then return end
		local char = player.Character or player.CharacterAdded:Wait()
		local head = char:WaitForChild("Head", 10)
		if not head then return end

		local old = head:FindFirstChild("OverheadTitle")
		if old then old:Destroy() end

		local ui = Instance.new("BillboardGui")
		ui.Name = "OverheadTitle"
		ui.Size = UDim2.new(0, 250, 0, 60)
		ui.StudsOffset = Vector3.new(0, 3.5, 0)
		ui.AlwaysOnTop = true
		ui.Parent = head

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		-- Nếu title là NO_DATA thì ẩn hoặc hiện text mặc định
		local displayTitle = (title == "NO_DATA") and "NO TITLE" or title
		lbl.Text = "<" .. displayTitle .. ">"

		-- [FIX] Màu xanh nếu là title xịn, màu xám nếu là NO_DATA
		if title == "NO_DATA" then
			lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
		else
			lbl.TextColor3 = GameConfig.Colors.Gold or Color3.fromRGB(255, 200, 0)
		end

		lbl.TextStrokeTransparency = 0
		lbl.Font = Enum.Font.Code
		lbl.TextSize = 24
		lbl.Parent = ui
	end)
end

function AchievementService:KnitInit()
	self.DataService = Knit.GetService("DataService")

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			local profile = self.DataService:GetProfile(player)
			if profile then UpdateOverhead(player, profile.Data.CurrentTitle) end
		end)
	end)
end

function AchievementService:OnDataLoaded(player, data)
	self:Check(player)
	self.Client.AchievementUpdated:Fire(player, data.UnlockedTitles, data.CurrentTitle)
	if player.Character then 
		UpdateOverhead(player, data.CurrentTitle) 
	end
end

function AchievementService:Check(player)
	local profile = self.DataService:GetProfile(player)
	if not profile then return end
	local data = profile.Data

	local changed = false
	for _, ach in ipairs(GameConfig.Achievements) do
		local has = false
		for _, t in ipairs(data.UnlockedTitles) do 
			if t == ach.Title then has = true; break end 
		end

		if not has then
			local passed = false
			if ach.Type == "Wallet" and data.Wallet >= ach.Val then passed = true end

			if passed then
				table.insert(data.UnlockedTitles, ach.Title)
				print("🏆 UNLOCKED:", ach.Title)
				changed = true
			end
		end
	end

	if changed then
		self.Client.AchievementUpdated:Fire(player, data.UnlockedTitles, data.CurrentTitle)
	end
end

function AchievementService.Client:EquipTitle(player, title)
	local profile = self.Server.DataService:GetProfile(player)
	if not profile then return false end
	local data = profile.Data

	-- [FIX] Cho phép equip NO_DATA luôn thành công
	if title == "NO_DATA" then
		data.CurrentTitle = title
		UpdateOverhead(player, title)
		self.Server.Client.AchievementUpdated:Fire(player, data.UnlockedTitles, title)
		return true
	end

	-- Check sở hữu các title khác
	local has = false
	for _, t in ipairs(data.UnlockedTitles) do 
		if t == title then has = true; break end 
	end

	if has then
		data.CurrentTitle = title
		UpdateOverhead(player, title)
		self.Server.Client.AchievementUpdated:Fire(player, data.UnlockedTitles, data.CurrentTitle)
		return true
	end

	return false
end

function AchievementService.Client:GetData(player)
	local profile = self.Server.DataService:GetProfile(player)
	if profile then return profile.Data.UnlockedTitles, profile.Data.CurrentTitle end
end

return AchievementService