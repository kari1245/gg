local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local View = require(script.Parent.AchievementView)

local AchievementController = Knit.CreateController { Name = "AchievementController" }

function AchievementController:KnitStart()
	self.AchService = Knit.GetService("AchievementService")

	local scope = Fusion.scoped(Fusion)
	local Unlocked = scope:Value({})
	local Current = scope:Value("NO_DATA")
	local IsOpen = scope:Value(false)

	self.AchService.AchievementUpdated:Connect(function(list, cur)
		Unlocked:set(list or {})
		if cur ~= Fusion.peek(Current) then Current:set(cur) end
	end)

	self.AchService:GetData():andThen(function(list, cur)
		if list then Unlocked:set(list); Current:set(cur) end
	end)

	local ui = View.New(scope, {
		UnlockedList = Unlocked, CurrentTitle = Current, IsOpen = IsOpen,
		OnToggle = function() IsOpen:set(not Fusion.peek(IsOpen)) end,
		OnClose = function() IsOpen:set(false) end,
		OnEquip = function(title)
			local old = Fusion.peek(Current)
			Current:set(title)
			self.AchService:EquipTitle(title):andThen(function(ok)
				if not ok then Current:set(old) end
			end)
		end
	})
	ui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return AchievementController