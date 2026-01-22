local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local Knit = require(ReplicatedStorage.Packages.Knit)

local SoundController = Knit.CreateController { Name = "SoundController" }

-- [FIX] Đã xóa UI_Error và SFX_Cash bị lỗi quyền
local SFX = {
	UI_Click = "rbxassetid://6042053626", -- Tiếng Click UI nhẹ nhàng
	UI_Hover = "rbxassetid://6895079853", -- Tiếng lướt chuột
	SFX_Win  = "rbxassetid://12221967",   -- Tiếng Coin/Thắng (Kinh điển)
}

function SoundController:KnitStart()
	self.Sounds = {}

	-- Tạo folder chứa Sound nếu chưa có
	local soundFolder = workspace:FindFirstChild("GlobalSounds") or Instance.new("Folder")
	soundFolder.Name = "GlobalSounds"
	soundFolder.Parent = workspace

	-- Tạo Sound Instance
	for name, id in pairs(SFX) do
		local s = Instance.new("Sound")
		s.Name = name
		s.SoundId = id
		s.Volume = 0.5
		s.Parent = soundFolder
		self.Sounds[name] = s
	end

	-- Preload
	task.spawn(function()
		local list = {}
		for _, s in pairs(self.Sounds) do table.insert(list, s) end

		-- Dùng pcall để an toàn
		local success, err = pcall(function()
			if #list > 0 then
				ContentProvider:PreloadAsync(list)
			end
		end)

		if success then
			print("🔊 Sound System Loaded (Lite)")
		end
	end)
end

function SoundController:Play(name)
	local sound = self.Sounds[name]
	if sound then
		sound:Play()
	else
		-- Im lặng nếu không tìm thấy sound (để tránh lỗi code ở các Controller khác)
	end
end

return SoundController