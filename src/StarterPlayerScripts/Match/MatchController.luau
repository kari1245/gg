local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local View = require(script.Parent.MatchView)

local MatchController = Knit.CreateController { Name = "MatchController" }

function MatchController:KnitStart()
	self.MatchService = Knit.GetService("MatchService")

	local scope = Fusion.scoped(Fusion)
	local IsSitting = scope:Value(false)
	local CurrentSeat = scope:Value(nil)
	
	-- Game state
	local GameState = scope:Value("WAITING_BET") -- WAITING_BET, MATCHMAKING, DEALING, PLAYER_TURN, DEALER_TURN, FINISHED
	local PlayersState = scope:Value({}) -- Array of player states
	local Dealer = scope:Value({ Hand = {}, Score = 0 })
	local CurrentPlayerIndex = scope:Value(0)
	local Result = scope:Value("")
	local BetInput = scope:Value(50)
	local MyHand = scope:Value({ Hand = {}, Score = 0, Bet = 0 }) -- Hand của player hiện tại
	
	-- Lobby state
	local LobbyPlayers = scope:Value({})
	local MaxPlayers = scope:Value(3)
	local CountdownTimer = scope:Value(0)

	-- Seat Logic (optional - keep for backward compatibility)
	local player = Players.LocalPlayer
	
	-- Public method to join game directly (without seat)
	function self:JoinGameDirectly()
		if not Fusion.peek(IsSitting) then
			print("[MATCH CTRL] Joining game directly (no seat)")
			IsSitting:set(true)
			CurrentSeat:set("DirectJoin")
			self.MatchService:JoinGame("DirectJoin")
		end
	end
	
	-- Public method to leave game
	function self:LeaveGameDirectly()
		if Fusion.peek(IsSitting) then
			print("[MATCH CTRL] Leaving game")
			self.MatchService:LeaveGame(Fusion.peek(CurrentSeat))
			IsSitting:set(false)
			CurrentSeat:set(nil)
		end
	end
	
	local function onChar(char)
		local hum = char:WaitForChild("Humanoid")
		hum.Seated:Connect(function(active, seat)
			if active and seat and seat.Name == "GameSeat" then
				local seatName = seat:GetFullName()
				print("[MATCH CTRL] Sat on", seatName)
				CurrentSeat:set(seatName)
				IsSitting:set(true)
				self.MatchService:JoinGame(seatName)
			elseif not active then
				if Fusion.peek(IsSitting) and Fusion.peek(CurrentSeat) then
					print("[MATCH CTRL] Left seat")
					self.MatchService:LeaveGame(Fusion.peek(CurrentSeat))
					IsSitting:set(false)
					CurrentSeat:set(nil)
				end
			end
		end)
	end
	if player.Character then onChar(player.Character) end
	player.CharacterAdded:Connect(onChar)

	-- Server signals
	self.MatchService.LobbyUpdate:Connect(function(d)
		print("[MATCH CTRL] Lobby update:", d)
		GameState:set(d.State)
		LobbyPlayers:set(d.Players)
		MaxPlayers:set(d.MaxPlayers)
		CountdownTimer:set(d.Timer or 0)
	end)
	
	self.MatchService.TimerUpdate:Connect(function(d)
		CountdownTimer:set(d.Timer)
	end)
	
	self.MatchService.MatchUpdate:Connect(function(d)
		print("[MATCH CTRL] Match update:", d)
		GameState:set(d.State)
		PlayersState:set(d.Players)
		Dealer:set(d.Dealer)
		CurrentPlayerIndex:set(d.CurrentPlayerIndex)
		
		-- Tìm hand của player hiện tại
		for _, p in ipairs(d.Players) do
			if p.Name == player.Name then
				MyHand:set({ Hand = p.Hand, Score = p.Score, Bet = p.Bet })
				break
			end
		end
	end)

	self.MatchService.GameOver:Connect(function(d)
		print("[MATCH CTRL] Game over:", d)
		Result:set(d.Result .. " [$"..d.WinAmount.."]")
	end)

	local ui = View.New(scope, {
		IsSitting = IsSitting,
		GameState = GameState,
		Players = PlayersState,
		Dealer = Dealer,
		CurrentPlayerIndex = CurrentPlayerIndex,
		Result = Result,
		BetInput = BetInput,
		LobbyPlayers = LobbyPlayers,
		MaxPlayers = MaxPlayers,
		CountdownTimer = CountdownTimer,
		MyHand = MyHand,
		OnPlaceBet = function()
			local seat = Fusion.peek(CurrentSeat)
			local bet = Fusion.peek(BetInput)
			if seat and bet then
				self.MatchService:PlaceBet(seat, bet)
			end
		end,
		OnHit = function()
			local seat = Fusion.peek(CurrentSeat)
			if seat then
				self.MatchService:Hit(seat)
			end
		end,
		OnStand = function()
			local seat = Fusion.peek(CurrentSeat)
			if seat then
				self.MatchService:Stand(seat)
			end
		end,
		OnLeave = function()
			self:LeaveGameDirectly()
		end
	})
	ui.Parent = player:WaitForChild("PlayerGui")
end

return MatchController