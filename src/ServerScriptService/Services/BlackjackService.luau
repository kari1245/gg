local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local BlackjackService = Knit.CreateService {
	Name = "BlackjackService",
	Client = {
		GameUpdate = Knit.CreateSignal(),
		GameOver = Knit.CreateSignal()
	}
}

-- Active games for each player
local ActiveGames = {} -- [Player] = GameState

-- Card data
local Suits = {"Hearts", "Diamonds", "Clubs", "Spades"}
local Ranks = {
	{Rank = "2", Value = 2}, {Rank = "3", Value = 3}, {Rank = "4", Value = 4},
	{Rank = "5", Value = 5}, {Rank = "6", Value = 6}, {Rank = "7", Value = 7},
	{Rank = "8", Value = 8}, {Rank = "9", Value = 9}, {Rank = "10", Value = 10},
	{Rank = "J", Value = 10}, {Rank = "Q", Value = 10}, {Rank = "K", Value = 10},
	{Rank = "A", Value = 11}
}

-- Helper: Create shuffled deck
local function CreateDeck()
	local deck = {}
	for _, suit in ipairs(Suits) do
		for _, rankData in ipairs(Ranks) do
			table.insert(deck, {Suit = suit, Rank = rankData.Rank, Value = rankData.Value})
		end
	end
	for i = #deck, 2, -1 do
		local j = math.random(i)
		deck[i], deck[j] = deck[j], deck[i]
	end
	return deck
end

-- Helper: Calculate hand score
local function CalculateScore(hand)
	local score, aces = 0, 0
	for _, card in ipairs(hand) do
		if card.Rank ~= "?" then
			score += card.Value
			if card.Rank == "A" then
				aces += 1
			end
		end
	end
	while score > 21 and aces > 0 do
		score -= 10
		aces -= 1
	end
	return score
end

-- Helper: Deal a card from deck
local function DealCard(deck)
	return table.remove(deck, 1)
end

-- Helper: Send game state to player
local function SendGameUpdate(player, game)
	local dealerHand = {}
	for i, card in ipairs(game.Dealer.Hand) do
		if game.State == "PLAYER_TURN" and i == 1 then
			table.insert(dealerHand, {Suit = "?", Rank = "?", Value = 0})
		else
			table.insert(dealerHand, card)
		end
	end

	BlackjackService.Client.GameUpdate:Fire(player, {
		State = game.State,
		Dealer = {
			Hand = dealerHand,
			Score = game.State == "PLAYER_TURN" and 0 or CalculateScore(game.Dealer.Hand)
		},
		Hand = game.PlayerHand,
		Score = CalculateScore(game.PlayerHand),
		Bet = game.Bet
	})
end

-- Service initialization
function BlackjackService:KnitInit()
	self.DataService = Knit.GetService("DataService")
	self.EconomyService = Knit.GetService("EconomyService")
end

function BlackjackService:KnitStart()
	Players.PlayerRemoving:Connect(function(player)
		if ActiveGames[player] then
			ActiveGames[player] = nil
		end
	end)
end

-- Join game
function BlackjackService.Client:JoinGame(player)
	print("[BLACKJACK] Player", player.Name, "joined")
	
	if ActiveGames[player] then
		print("[BLACKJACK] Player already in game")
		return false
	end
	
	ActiveGames[player] = {
		PlayerHand = {},
		Dealer = { Hand = {} },
		Deck = CreateDeck(),
		State = "WAITING_BET",
		Bet = 0
	}
	
	return true
end

-- Leave game
function BlackjackService.Client:LeaveGame(player)
	print("[BLACKJACK] Player", player.Name, "left")
	
	local game = ActiveGames[player]
	if not game then return end
	
	-- Refund bet if game was in progress
	if game.Bet > 0 and game.State ~= "FINISHED" then
		BlackjackService.EconomyService:ModifyWallet(player, game.Bet)
	end
	
	ActiveGames[player] = nil
end

-- Place bet
function BlackjackService.Client:PlaceBet(player, amount)
	local game = ActiveGames[player]
	if not game then
		return false, "NOT_IN_GAME"
	end
	
	if game.State ~= "WAITING_BET" then
		return false, "GAME_IN_PROGRESS"
	end
	
	if amount < GameConfig.Blackjack.MinBet or amount > GameConfig.Blackjack.MaxBet then
		return false, "INVALID_BET"
	end
	
	-- Check player balance
	local profile = BlackjackService.DataService:GetProfile(player)
	if not profile or profile.Data.Wallet < amount then
		return false, "INSUFFICIENT_FUNDS"
	end
	
	-- Deduct bet
	local success = BlackjackService.EconomyService:ModifyWallet(player, -amount)
	if not success then
		return false, "TRANSACTION_FAILED"
	end
	
	game.Bet = amount
	game.State = "DEALING"
	
	-- Reset deck if needed
	if #game.Deck < 20 then
		game.Deck = CreateDeck()
	end
	
	-- Deal initial cards
	game.PlayerHand = {
		DealCard(game.Deck),
		DealCard(game.Deck)
	}
	
	game.Dealer.Hand = {
		DealCard(game.Deck),
		DealCard(game.Deck)
	}
	
	local playerScore = CalculateScore(game.PlayerHand)
	local dealerScore = CalculateScore(game.Dealer.Hand)
	
	-- Check for blackjack
	if playerScore == 21 then
		game.State = "DEALER_TURN"
		task.wait(0.5)
		BlackjackService:_ResolveDealerTurn(player, game)
		return true
	end
	
	game.State = "PLAYER_TURN"
	SendGameUpdate(player, game)
	
	return true
end

-- Player hits
function BlackjackService.Client:Hit(player)
	local game = ActiveGames[player]
	if not game or game.State ~= "PLAYER_TURN" then
		return false
	end
	
	table.insert(game.PlayerHand, DealCard(game.Deck))
	local score = CalculateScore(game.PlayerHand)
	
	if score > 21 then
		-- Player busts
		game.State = "FINISHED"
		SendGameUpdate(player, game)
		
		BlackjackService.Client.GameOver:Fire(player, {
			Result = "LOSE",
			WinAmount = 0
		})
		
		task.delay(3, function()
			if ActiveGames[player] then
				ActiveGames[player].State = "WAITING_BET"
				ActiveGames[player].PlayerHand = {}
				ActiveGames[player].Dealer.Hand = {}
				ActiveGames[player].Bet = 0
			end
		end)
	else
		SendGameUpdate(player, game)
	end
	
	return true
end

-- Player stands
function BlackjackService.Client:Stand(player)
	local game = ActiveGames[player]
	if not game or game.State ~= "PLAYER_TURN" then
		return false
	end
	
	game.State = "DEALER_TURN"
	BlackjackService:_ResolveDealerTurn(player, game)
	
	return true
end

-- Resolve dealer turn
function BlackjackService:_ResolveDealerTurn(player, game)
	SendGameUpdate(player, game)
	task.wait(1)
	
	-- Dealer draws until 17 or higher
	while CalculateScore(game.Dealer.Hand) < 17 do
		table.insert(game.Dealer.Hand, DealCard(game.Deck))
		SendGameUpdate(player, game)
		task.wait(1)
	end
	
	local playerScore = CalculateScore(game.PlayerHand)
	local dealerScore = CalculateScore(game.Dealer.Hand)
	
	game.State = "FINISHED"
	SendGameUpdate(player, game)
	
	local result, winAmount
	
	if dealerScore > 21 then
		result = "WIN"
		winAmount = game.Bet * 2
	elseif playerScore > dealerScore then
		result = "WIN"
		winAmount = game.Bet * 2
	elseif playerScore == dealerScore then
		result = "PUSH"
		winAmount = game.Bet
	else
		result = "LOSE"
		winAmount = 0
	end
	
	if winAmount > 0 then
		BlackjackService.EconomyService:ModifyWallet(player, winAmount)
	end
	
	BlackjackService.Client.GameOver:Fire(player, {
		Result = result,
		WinAmount = winAmount
	})
	
	-- Reset game after delay
	task.delay(3, function()
		if ActiveGames[player] then
			ActiveGames[player].State = "WAITING_BET"
			ActiveGames[player].PlayerHand = {}
			ActiveGames[player].Dealer.Hand = {}
			ActiveGames[player].Bet = 0
		end
	end)
end

return BlackjackService
