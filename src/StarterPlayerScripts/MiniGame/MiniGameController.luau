local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local View = require(script.Parent.MiniGameView)

local MiniGameController = Knit.CreateController { Name = "MiniGameController" }

function MiniGameController:KnitStart()
	self.SoundController = Knit.GetController("SoundController")
	self.UIManager = Knit.GetController("UIManagerController")
	self.MatchController = Knit.GetController("MatchController")
	
	local scope = Fusion.scoped(Fusion)
	local IsOpen = scope:Value(false)
	
	-- Register với UIManager
	if self.UIManager then
		self.UIManager:RegisterUI("MiniGame", IsOpen)
	end
	
	-- Render UI
	local ui = View.New(scope, {
		IsOpen = IsOpen,
		
		OnToggle = function()
			if self.SoundController then self.SoundController:Play("UI_Click") end
			IsOpen:set(not Fusion.peek(IsOpen))
		end,
		
		OnClose = function()
			if self.SoundController then self.SoundController:Play("UI_Close") end
			IsOpen:set(false)
		end,
		
		OnPlayBlackjack = function()
			if self.SoundController then self.SoundController:Play("UI_Click") end
			-- Trigger match controller to join game
			if self.MatchController and self.MatchController.JoinGameDirectly then
				self.MatchController:JoinGameDirectly()
			end
			IsOpen:set(false)
		end
	})
	
	ui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	
	print("🎮 MiniGame Controller Ready!")
end

return MiniGameController
