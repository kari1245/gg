local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

-- [IMPORT VIEW]
local AchievementView = require(script.Parent.AchievementView) 

local AchievementController = Knit.CreateController { Name = "AchievementController" }

function AchievementController:KnitInit()
	self.scope = Fusion.scoped(Fusion)
	self.UnlockedTitles = self.scope:Value({})
	self.CurrentTitle = self.scope:Value("NO_DATA")
	self.isOpen = self.scope:Value(false)
end

function AchievementController:KnitStart()
	self.AchService = Knit.GetService("AchievementService")
	self.SoundController = Knit.GetController("SoundController")
	self.UIManager = Knit.GetController("UIManagerController")
	
	-- Register với UIManager
	if self.UIManager then
		self.UIManager:RegisterUI("Achievement", self.isOpen)
	end

	self.AchService.AchievementUpdated:Connect(function(list, current)
		self.UnlockedTitles:set(list or {})
		if current ~= Fusion.peek(self.CurrentTitle) then
			self.CurrentTitle:set(current or "NO_DATA")
		end
	end)

	self.AchService:GetData():andThen(function(list, current)
		if list then
			self.UnlockedTitles:set(list)
			self.CurrentTitle:set(current)
		end
	end)

	self:RenderUI()
end

function AchievementController:Toggle()
	if self.SoundController then self.SoundController:Play("UI_Click") end
	self.isOpen:set(not Fusion.peek(self.isOpen))
end

function AchievementController:RenderUI()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	self.scope:New "ScreenGui" {
		Parent = playerGui, Name = "UI_Achievement", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			-- [GỌI VIEW RIÊNG]
			AchievementView.New(self.scope, {
				UnlockedList = self.UnlockedTitles,
				CurrentTitle = self.CurrentTitle,
				IsOpen = self.isOpen,

				OnToggle = function() self:Toggle() end,
				OnClose = function() self.isOpen:set(false) end,

				OnEquip = function(title)
					local prev = Fusion.peek(self.CurrentTitle)

					-- Optimistic Update: Cập nhật UI ngay lập tức để người chơi thấy phản hồi nhanh
					self.CurrentTitle:set(title)
					if self.SoundController then self.SoundController:Play("UI_Click") end

					self.AchService:EquipTitle(title):andThen(function(ok)
						if ok then
							-- [FIX] Nếu thành công, phát tiếng Win (Màu xanh đã được View xử lý dựa trên CurrentTitle)
							if self.SoundController then self.SoundController:Play("SFX_Win") end
						else
							-- Nếu thất bại (hack/lỗi), quay lại title cũ
							self.CurrentTitle:set(prev)
							if self.SoundController then self.SoundController:Play("UI_Error") end
						end
					end)
				end
			})
		}
	}
end

return AchievementController