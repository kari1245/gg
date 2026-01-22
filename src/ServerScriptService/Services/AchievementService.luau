local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local AchievementService = Knit.CreateService {
	Name = "AchievementService",
	Client = { AchievementUpdated = Knit.CreateSignal() }
}

-- Hàm Update Visual (Chạy mượt, không yield)
local function UpdateOverhead(player, title)
	if not player then return end
	task.spawn(function()
		-- Đợi tối đa 10s để nhân vật load
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
		lbl.Text = "<" .. (title or "NO_DATA") .. ">"
		lbl.TextColor3 = GameConfig.Colors.Gold
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

-- [FIX QUAN TRỌNG Ở ĐÂY]
function AchievementService:OnDataLoaded(player, data)
	-- 1. Kiểm tra ngay lập tức xem stats hiện tại có đạt achievement nào không
	-- (Ví dụ: Mới vào có sẵn 1000$ -> Phải unlock luôn title 500$)
	self:Check(player)

	-- 2. Sau khi Check xong (đã unlock title mới nếu có), mới gửi về Client
	-- Lưu ý: Hàm Check đã update data, nên ta cần lấy lại data mới nhất nếu muốn chắc ăn,
	-- hoặc chỉ cần gọi Check là đủ vì Check sẽ tự Fire Client nếu có thay đổi.
	-- Tuy nhiên, để an toàn cho lần load đầu, ta vẫn Fire force 1 lần.
	self.Client.AchievementUpdated:Fire(player, data.UnlockedTitles, data.CurrentTitle)

	-- 3. Hiện visual
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
			if ach.Type == "Wins" and data.Stats.Wins >= ach.Val then passed = true end

			if passed then
				table.insert(data.UnlockedTitles, ach.Title)
				print("🏆 UNLOCKED (Init Check):", ach.Title)
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