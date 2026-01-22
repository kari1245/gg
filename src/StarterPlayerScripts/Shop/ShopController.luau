local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local View = require(script.Parent.ShopView)

local ShopController = Knit.CreateController { Name = "ShopController" }

function ShopController:KnitStart()
	self.ShopService = Knit.GetService("ShopService")
	self.SoundController = Knit.GetController("SoundController")
	
	local scope = Fusion.scoped(Fusion)
	local IsOpen = scope:Value(false)
	local DailyItems = scope:Value({})
	
	-- Lấy dữ liệu shop
	self.ShopService:GetShopData():andThen(function(items)
		DailyItems:set(items or {})
	end)
	
	self.ShopService.ShopUpdated:Connect(function(items)
		print("🛒 Shop Updated Signal Received") -- Log kiểm tra
		DailyItems:set(items)
	end)
	
	local ui = View.New(scope, {
		IsOpen = IsOpen,
		DailyItems = DailyItems,
		
		OnToggle = function() 
			if self.SoundController then self.SoundController:Play("UI_Click") end
			IsOpen:set(not Fusion.peek(IsOpen))
		end,
		OnClose = function() IsOpen:set(false) end,
		
		OnBuy = function(hash)
			print("🛒 Clicking Buy for Hash:", hash) -- [QUAN TRỌNG] Log kiểm tra click
			
			self.ShopService:BuyNft(hash):andThen(function(success, msg)
				if success then
					print("✅ Buy Success!")
					if self.SoundController then self.SoundController:Play("SFX_Win") end
				else
					warn("⚠️ Buy Failed:", msg)
					if self.SoundController then self.SoundController:Play("UI_Error") end
				end
			end)
		end
	})
	
	ui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return ShopController