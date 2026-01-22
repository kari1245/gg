local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local View = require(script.Parent.ShopView)

local ShopController = Knit.CreateController { Name = "ShopController" }

function ShopController:KnitStart()
	self.ShopService = Knit.GetService("ShopService")
	self.InvService = Knit.GetService("InventoryService")
	self.SoundController = Knit.GetController("SoundController")

	local scope = Fusion.scoped(Fusion)
	local DailyItems = scope:Value({})
	local OwnedItems = scope:Value({})
	local IsOpen = scope:Value(false)

	-- Lấy danh sách shop
	self.ShopService:GetDailyShop():andThen(function(items)
		DailyItems:set(items or {})
	end)

	-- Lắng nghe inventory để biết đã mua gì chưa (để hiện nút Owned)
	self.InvService.InventoryUpdated:Connect(function(c) OwnedItems:set(c or {}) end)
	self.InvService:GetData():andThen(function(c) if c then OwnedItems:set(c) end end)

	local ui = View.New(scope, {
		DailyItems = DailyItems, OwnedItems = OwnedItems, IsOpen = IsOpen,
		OnToggle = function() 
			if self.SoundController then self.SoundController:Play("UI_Click") end
			IsOpen:set(not Fusion.peek(IsOpen)) 
		end,
		OnClose = function() IsOpen:set(false) end,
		OnBuy = function(itemId)
			if self.SoundController then self.SoundController:Play("UI_Click") end
			self.ShopService:BuyItem(itemId):andThen(function(success)
				if success then
					if self.SoundController then self.SoundController:Play("SFX_Win") end
				else
					if self.SoundController then self.SoundController:Play("UI_Error") end
				end
			end)
		end
	})
	ui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return ShopController