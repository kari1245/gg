local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local View = require(script.Parent.BankView)

local BankController = Knit.CreateController { Name = "BankController" }

function BankController:KnitStart()
	self.EcoService = Knit.GetService("EconomyService")
	self.SoundController = Knit.GetController("SoundController")
	self.UIManager = Knit.GetController("UIManagerController")

	local scope = Fusion.scoped(Fusion)
	local IsOpen = scope:Value(false)
	local AmountInput = scope:Value("")
	
	-- Register với UIManager
	if self.UIManager then
		self.UIManager:RegisterUI("Bank", IsOpen)
	end

	-- Toggle Action (Để các controller khác có thể gọi nếu cần)
	function self:Toggle()
		if self.SoundController then self.SoundController:Play("UI_Click") end
		IsOpen:set(not Fusion.peek(IsOpen))
	end

	local function HandleTransaction(action)
		if self.SoundController then self.SoundController:Play("UI_Click") end

		local txt = Fusion.peek(AmountInput)
		local amount = tonumber(txt)

		if amount and amount > 0 then
			self.EcoService:Transfer(action, amount):andThen(function(success)
				if success then
					if self.SoundController then self.SoundController:Play("SFX_Cash") end
					AmountInput:set("") -- Xóa input nếu thành công
				else
					if self.SoundController then self.SoundController:Play("UI_Error") end
				end
			end)
		else
			if self.SoundController then self.SoundController:Play("UI_Error") end
		end
	end

	local ui = View.New(scope, {
		IsOpen = IsOpen, AmountInput = AmountInput,
		OnToggle = function() self:Toggle() end,
		OnClose = function() IsOpen:set(false) end,
		OnDeposit = function() HandleTransaction("DEPOSIT") end,
		OnWithdraw = function() HandleTransaction("WITHDRAW") end
	})

	ui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return BankController