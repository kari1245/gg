local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local BlackjackView = require(script.Parent.BlackjackView)

local BlackjackController = Knit.CreateController { 
	Name = "BlackjackController" 
}

function BlackjackController:KnitInit()
	-- Create Fusion scope
	self.scope = Fusion.scoped(Fusion)
	
	-- Create state variables
	self.IsSitting = self.scope:Value(false)
	self.GameState = self.scope:Value("WAITING_BET")
	self.Dealer = self.scope:Value({ Hand = {}, Score = 0 })
	self.Result = self.scope:Value(nil)
	self.BetInput = self.scope:Value(50)
	self.MyHand = self.scope:Value({ Hand = {}, Score = 0 })
end

function BlackjackController:KnitStart()
	print("[BLACKJACK] Controller Starting...")
	local player = Players.LocalPlayer
	self.BlackjackService = Knit.GetService("BlackjackService")
	print("[BLACKJACK] Service connected:", self.BlackjackService)

	-- Server signals
	self.BlackjackService.GameUpdate:Connect(function(data)
		print("[BLACKJACK] GameUpdate received:", data)
		if not data then return end
		
		self.GameState:set(data.State or "WAITING_BET")
		
		if data.Dealer then
			self.Dealer:set({ 
				Hand = data.Dealer.Hand or {}, 
				Score = data.Dealer.Score or 0 
			})
		end
		
		if data.Hand then
			self.MyHand:set({ 
				Hand = data.Hand or {}, 
				Score = data.Score or 0 
			})
		end
		
		if data.Bet then
			self.BetInput:set(data.Bet)
		end
	end)

	self.BlackjackService.GameOver:Connect(function(result)
		print("[BLACKJACK] GameOver received:", result)
		self.Result:set(result)
		self.GameState:set("FINISHED")
		
		-- Auto return to bet screen after 3 seconds
		task.wait(3)
		self.GameState:set("WAITING_BET")
		self.Dealer:set({ Hand = {}, Score = 0 })
		self.MyHand:set({ Hand = {}, Score = 0 })
		self.Result:set(nil)
	end)
	
	-- Render UI
	self:RenderUI()
	print("[BLACKJACK] Controller Started!")
end

function BlackjackController:RenderUI()
	local ui = BlackjackView.New(self.scope, {
		IsSitting = self.IsSitting,
		GameState = self.GameState,
		Dealer = self.Dealer,
		Result = self.scope:Computed(function(use)
			local res = use(self.Result)
			if not res then return "" end
			if res.Result == "WIN" then
				return "YOU WIN! +$" .. res.WinAmount
			elseif res.Result == "LOSE" then
				return "YOU LOSE!"
			elseif res.Result == "PUSH" then
				return "PUSH! $" .. res.WinAmount
			end
			return ""
		end),
		BetInput = self.BetInput,
		MyHand = self.MyHand,
		
		OnLeave = function()
			self:Leave()
		end,
		
		OnPlaceBet = function()
			local bet = tonumber(Fusion.peek(self.BetInput)) or 50
			self:PlaceBet(bet)
		end,
		
		OnHit = function()
			self:Hit()
		end,
		
		OnStand = function()
			self:Stand()
		end
	})
	
	ui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	print("🃏 Blackjack UI Rendered!")
end

function BlackjackController:GetIsSitting()
	return self.IsSitting
end

function BlackjackController:GetGameState()
    return self.GameState
end

function BlackjackController:GetDealer()
    return self.Dealer
end

function BlackjackController:GetResult()
    return self.Result
end

function BlackjackController:GetBetInput()
    return self.BetInput
end

function BlackjackController:GetMyHand()
    return self.MyHand
end

function BlackjackController:Join()
	print("[BLACKJACK] Join called! Setting IsSitting to true")
	self.IsSitting:set(true)
	print("[BLACKJACK] IsSitting is now:", Fusion.peek(self.IsSitting))
	self.BlackjackService:JoinGame()
	print("[BLACKJACK] Join game request sent to server")
end

function BlackjackController:Leave()
    self.IsSitting:set(false)
    self.GameState:set("WAITING_BET")
    self.Dealer:set({ Hand = {}, Score = 0 })
    self.Result:set(nil)
    self.BetInput:set(50)
    self.MyHand:set({ Hand = {}, Score = 0 })
    self.BlackjackService:LeaveGame()
end

function BlackjackController:PlaceBet(amount)
    self.BetInput:set(amount)
    self.BlackjackService:PlaceBet(amount)
end

function BlackjackController:Hit()
    self.BlackjackService:Hit()
end

function BlackjackController:Stand()
    self.BlackjackService:Stand()
end

return BlackjackController