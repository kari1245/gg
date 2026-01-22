local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local MatchService = Knit.CreateService {
	Name = "MatchService",
	Client = {
		MatchUpdate = Knit.CreateSignal(),
		GameOver = Knit.CreateSignal()
	}
}

local ActiveMatches = {}

-- [[ HELPER FUNCTIONS ]]
local Suits = {"Hearts", "Diamonds", "Clubs", "Spades"}
local Ranks = {
	{Rank = "2", Value = 2}, {Rank = "3", Value = 3}, {Rank = "4", Value = 4},
	{Rank = "5", Value = 5}, {Rank = "6", Value = 6}, {Rank = "7", Value = 7},
	{Rank = "8", Value = 8}, {Rank = "9", Value = 9}, {Rank = "10", Value = 10},
	{Rank = "J", Value = 10}, {Rank = "Q", Value = 10}, {Rank = "K", Value = 10},
	{Rank = "A", Value = 11}
}

local function CreateDeck()
	local deck = {}
	for _, suit in ipairs(Suits) do
		for _, rankData in ipairs(Ranks) do
			table.insert(deck, {Suit = suit, Rank = rankData.Rank, Value = rankData.Value})
		end
	end
	for i = #deck, 2, -1 do local j = math.random(i); deck[i], deck[j] = deck[j], deck[i] end
	return deck
end

local function CalculateScore(hand)
	local score, aces = 0, 0
	for _, card in ipairs(hand) do
		if card.Rank ~= "?" then
			score += card.Value
			if card.Rank == "A" then aces += 1 end
		end
	end
	while score > 21 and aces > 0 do score -= 10; aces -= 1 end
	return score
end

-- [[ LOGIC CHÍNH ]]
function MatchService:KnitInit()
	self.DataService = Knit.GetService("DataService")
	self.EconomyService = Knit.GetService("EconomyService")
end

function MatchService:UpdateMatch(player)
	local match = ActiveMatches[player]
	if match then
		self.Client.MatchUpdate:Fire(player, {
			State = match.State,
			PlayerHand = match.PlayerHand,
			DealerHand = match.DealerHand,
			PlayerScore = CalculateScore(match.PlayerHand),
			DealerScore = CalculateScore(match.DealerHand)
		})
	end
end

function MatchService:StartMatch(player, betAmount)
	if ActiveMatches[player] then return end

	betAmount = tonumber(betAmount) or 0
	betAmount = math.floor(betAmount)

	local min = GameConfig.Blackjack and GameConfig.Blackjack.MinBet or 50
	local max = GameConfig.Blackjack and GameConfig.Blackjack.MaxBet or 50000
	if betAmount < min or betAmount > max then return end

	local profile = self.DataService:GetProfile(player)
	if not profile then return end

	if profile.Data.Wallet < betAmount then return end
	self.EconomyService:ModifyWallet(player, -betAmount)

	local deck = CreateDeck()
	local pHand = { table.remove(deck, 1), table.remove(deck, 1) }
	local dCard1 = table.remove(deck, 1)
	local dCard2 = table.remove(deck, 1)
	local dHandVisual = { dCard1, {Rank="?", Suit="Hidden", Value=0} } 

	ActiveMatches[player] = {
		Deck = deck, PlayerHand = pHand, DealerHand = dHandVisual, HiddenCard = dCard2,
		State = "PLAYER_TURN", Bet = betAmount
	}

	if CalculateScore(pHand) == 21 then
		self:EndMatch(player, ActiveMatches[player], "BLACKJACK")
	else
		self:UpdateMatch(player)
	end
end

function MatchService:Hit(player)
	local match = ActiveMatches[player]
	if not match or match.State ~= "PLAYER_TURN" then return end
	table.insert(match.PlayerHand, table.remove(match.Deck, 1))
	if CalculateScore(match.PlayerHand) > 21 then self:EndMatch(player, match, "BUST")
	else self:UpdateMatch(player) end
end

function MatchService:Stand(player)
	local match = ActiveMatches[player]
	if not match or match.State ~= "PLAYER_TURN" then return end
	match.State = "DEALER_TURN"
	match.DealerHand[2] = match.HiddenCard
	self:UpdateMatch(player)

	task.spawn(function()
		task.wait(0.5)
		while CalculateScore(match.DealerHand) < 17 do
			table.insert(match.DealerHand, table.remove(match.Deck, 1))
			self:UpdateMatch(player)
			task.wait(0.5)
		end
		self:EndMatch(player, match, "COMPARE")
	end)
end

function MatchService:EndMatch(player, match, reason)
	match.State = "FINISHED"
	local pScore, dScore = CalculateScore(match.PlayerHand), CalculateScore(match.DealerHand)
	local result, winAmount = "LOSE", 0

	if reason == "BUST" then result = "LOSE"
	elseif reason == "BLACKJACK" then result = "BLACKJACK"; winAmount = math.floor(match.Bet * 2.5)
	else
		if dScore > 21 then result = "WIN"; winAmount = match.Bet * 2
		elseif pScore > dScore then result = "WIN"; winAmount = match.Bet * 2
		elseif pScore == dScore then result = "PUSH"; winAmount = match.Bet
		else result = "LOSE" end
	end

	if winAmount > 0 then
		self.EconomyService:ModifyWallet(player, winAmount)
	end

	local AchService = Knit.GetService("AchievementService")
	if (result == "WIN" or result == "BLACKJACK") and AchService then
		local profile = self.DataService:GetProfile(player)
		if profile then 
			profile.Data.Stats.Wins += 1 
			AchService:Check(player)
		end
	end

	-- [FIX] Thêm PlayerHand vào payload để Client không bị lỗi nil
	self.Client.GameOver:Fire(player, {
		Result = result, 
		WinAmount = winAmount,
		PlayerScore = pScore, 
		DealerScore = dScore, 
		PlayerHand = match.PlayerHand, -- [MỚI THÊM]
		DealerHand = match.DealerHand
	})
	ActiveMatches[player] = nil
end

function MatchService.Client:StartMatch(player, bet) return self.Server:StartMatch(player, bet) end
function MatchService.Client:Hit(player) return self.Server:Hit(player) end
function MatchService.Client:Stand(player) return self.Server:Stand(player) end

return MatchService