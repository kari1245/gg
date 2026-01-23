local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local MatchService = Knit.CreateService {
	Name = "MatchService",
	Client = {
		MatchUpdate = Knit.CreateSignal(),
		GameOver = Knit.CreateSignal(),
		LobbyUpdate = Knit.CreateSignal(),
		TimerUpdate = Knit.CreateSignal()
	}
}

-- Lưu game state theo seat
local ActiveGames = {} -- [SeatName] = GameState
local PlayerSeats = {} -- [Player] = SeatName

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

local function BroadcastToPlayers(seatName, signal, data)
	local game = ActiveGames[seatName]
	if not game then return end
	for _, playerData in ipairs(game.Players) do
		if playerData.Player and playerData.Player.Parent then
			signal:Fire(playerData.Player, data)
		end
	end
end

-- [[ LOGIC CHÍNH ]]
function MatchService:KnitInit()
	self.DataService = Knit.GetService("DataService")
	self.EconomyService = Knit.GetService("EconomyService")
end

function MatchService:KnitStart()
	-- Cleanup khi player rời game
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		local seatName = PlayerSeats[player]
		if seatName then
			self:LeaveGame(player, seatName)
		end
	end)
end

-- JOIN GAME
function MatchService:JoinGame(player, seatName)
	print("[MATCH] Player", player.Name, "joining seat", seatName)
	
	-- Tạo game mới nếu chưa có
	if not ActiveGames[seatName] then
		ActiveGames[seatName] = {
			Players = {},
			Dealer = { Hand = {}, Score = 0 },
			Deck = {},
			State = "WAITING_BET", -- WAITING_BET -> MATCHMAKING -> DEALING -> PLAYER_TURN -> DEALER_TURN -> FINISHED
			CurrentPlayerIndex = 1,
			MatchmakingTimer = nil,
			GameTimer = nil,
			TurnTimeout = nil
		}
	end
	
	local game = ActiveGames[seatName]
	
	-- Không cho join nếu đang trong game
	if game.State ~= "WAITING_BET" and game.State ~= "MATCHMAKING" then
		return false, "GAME_IN_PROGRESS"
	end
	
	-- Kiểm tra đã full chưa
	if #game.Players >= GameConfig.Blackjack.MaxPlayers then
		return false, "FULL"
	end
	
	-- Kiểm tra đã join chưa
	for _, p in ipairs(game.Players) do
		if p.Player == player then
			return false, "ALREADY_JOINED"
		end
	end
	
	-- Thêm player vào game với bet = 0 (chưa bet)
	table.insert(game.Players, {
		Player = player,
		Hand = {},
		Score = 0,
		Bet = 0,
		State = "WAITING", -- WAITING -> ACTIVE -> BUST -> STAND -> FINISHED
		HasActed = false
	})
	
	PlayerSeats[player] = seatName
	
	-- Broadcast lobby update
	self:BroadcastLobby(seatName)
	
	return true, "JOINED"
end

-- LEAVE GAME
function MatchService:LeaveGame(player, seatName)
	print("[MATCH] Player", player.Name, "leaving seat", seatName)
	
	local game = ActiveGames[seatName]
	if not game then return end
	
	-- Remove player
	for i, p in ipairs(game.Players) do
		if p.Player == player then
			-- Refund bet nếu đang chơi
			if p.Bet > 0 and game.State ~= "FINISHED" then
				self.EconomyService:ModifyWallet(player, p.Bet)
			end
			table.remove(game.Players, i)
			break
		end
	end
	
	PlayerSeats[player] = nil
	
	-- Nếu không còn player nào, cleanup game
	if #game.Players == 0 then
		if game.MatchmakingTimer then task.cancel(game.MatchmakingTimer) end
		if game.GameTimer then task.cancel(game.GameTimer) end
		if game.TurnTimeout then task.cancel(game.TurnTimeout) end
		ActiveGames[seatName] = nil
	else
		self:BroadcastLobby(seatName)
		-- Nếu đang trong player turn và player vừa rời là current player, chuyển turn
		if game.State == "PLAYER_TURN" then
			local currentPlayer = game.Players[game.CurrentPlayerIndex]
			if not currentPlayer or currentPlayer.Player == player then
				self:CheckNextTurn(seatName)
			end
		end
	end
end

-- BROADCAST LOBBY
function MatchService:BroadcastLobby(seatName)
	local game = ActiveGames[seatName]
	if not game then return end
	
	local playerList = {}
	for i, p in ipairs(game.Players) do
		table.insert(playerList, {
			Name = p.Player.Name,
			Bet = p.Bet,
			Index = i
		})
	end
	
	BroadcastToPlayers(seatName, self.Client.LobbyUpdate, {
		State = game.State,
		Players = playerList,
		MaxPlayers = GameConfig.Blackjack.MaxPlayers,
		Timer = game.Timer or 0
	})
end

-- COUNTDOWN TIMER
function MatchService:StartTimer(seatName, duration, onComplete)
	local game = ActiveGames[seatName]
	if not game then return end
	
	game.Timer = duration
	self:BroadcastLobby(seatName)
	
	for i = duration, 0, -1 do
		game.Timer = i
		BroadcastToPlayers(seatName, self.Client.TimerUpdate, { Timer = i })
		if i == 0 then break end
		task.wait(1)
	end
	
	if onComplete then onComplete() end
end

-- START MATCHMAKING (sau khi player đã bet)
function MatchService:StartMatchmaking(seatName)
	local game = ActiveGames[seatName]
	if not game then return end
	
	print("[MATCH] Starting matchmaking for", seatName)
	game.State = "MATCHMAKING"
	self:BroadcastLobby(seatName)
	
	-- Countdown 5s để tìm đối thủ
	self:StartTimer(seatName, GameConfig.Blackjack.LobbyWaitTime, function()
		if not game then return end
		
		-- Nếu không đủ người, thêm AI dealer
		if #game.Players == 1 then
			print("[MATCH] Only 1 player, playing with AI dealer")
		end
		
		self:StartDealing(seatName)
	end)
end

-- PLACE BET
function MatchService:PlaceBet(player, seatName, betAmount)
	local game = ActiveGames[seatName]
	if not game or (game.State ~= "WAITING_BET" and game.State ~= "MATCHMAKING") then return false end
	
	betAmount = math.floor(tonumber(betAmount) or 0)
	local min = GameConfig.Blackjack.MinBet
	local max = GameConfig.Blackjack.MaxBet
	
	if betAmount < min or betAmount > max then return false end
	
	local profile = self.DataService:GetProfile(player)
	if not profile or profile.Data.Wallet < betAmount then return false end
	
	-- Tìm player trong game
	for _, p in ipairs(game.Players) do
		if p.Player == player then
			-- Refund bet cũ nếu có
			if p.Bet > 0 then
				self.EconomyService:ModifyWallet(player, p.Bet)
			end
			-- Trừ tiền và set bet mới
			self.EconomyService:ModifyWallet(player, -betAmount)
			p.Bet = betAmount
			self:BroadcastLobby(seatName)
			
			-- Start matchmaking timer nếu chưa có
			if not game.MatchmakingTimer then
				game.MatchmakingTimer = task.spawn(function()
					self:StartMatchmaking(seatName)
				end)
			end
			
			return true
		end
	end
	
	return false
end

-- START DEALING CARDS
function MatchService:StartDealing(seatName)
	local game = ActiveGames[seatName]
	if not game then return end
	
	print("[MATCH] Dealing cards for", seatName)
	game.State = "DEALING"
	game.Deck = CreateDeck()
	
	-- Chia 2 lá cho mỗi player
	for _, p in ipairs(game.Players) do
		p.Hand = { table.remove(game.Deck, 1), table.remove(game.Deck, 1) }
		p.Score = CalculateScore(p.Hand)
		p.State = "ACTIVE"
		p.HasActed = false
	end
	
	-- Chia 2 lá cho dealer (1 lá úp)
	local dCard1 = table.remove(game.Deck, 1)
	local dCard2 = table.remove(game.Deck, 1)
	game.Dealer.Hand = { dCard1, {Rank="?", Suit="Hidden", Value=0} }
	game.Dealer.HiddenCard = dCard2
	game.Dealer.Score = CalculateScore({dCard1})
	
	game.CurrentPlayerIndex = 1
	game.State = "PLAYER_TURN"
	
	self:BroadcastGameState(seatName)
	
	-- Auto check blackjack
	for _, p in ipairs(game.Players) do
		if p.Score == 21 then
			p.State = "BLACKJACK"
			p.HasActed = true
		end
	end
	
	-- Start first player's turn with timeout
	local firstPlayer = game.Players[game.CurrentPlayerIndex]
	if firstPlayer and not firstPlayer.HasActed then
		local timeoutId = {}
		game.TurnTimeout = timeoutId
		task.spawn(function()
			self:StartTimer(seatName, 10, function()
				if game.TurnTimeout == timeoutId and firstPlayer and not firstPlayer.HasActed then
					print("[MATCH] Player", firstPlayer.Player.Name, "timeout - auto STAND")
					firstPlayer.State = "STAND"
					firstPlayer.HasActed = true
					self:BroadcastGameState(seatName)
					task.wait(0.5)
					self:CheckNextTurn(seatName)
				end
			end)
		end)
	else
		self:CheckNextTurn(seatName)
	end
end

-- BROADCAST GAME STATE
function MatchService:BroadcastGameState(seatName)
	local game = ActiveGames[seatName]
	if not game then return end
	
	local playerStates = {}
	for i, p in ipairs(game.Players) do
		table.insert(playerStates, {
			Name = p.Player.Name,
			Hand = p.Hand,
			Score = p.Score,
			Bet = p.Bet,
			State = p.State,
			IsCurrent = (i == game.CurrentPlayerIndex)
		})
	end
	
	BroadcastToPlayers(seatName, self.Client.MatchUpdate, {
		State = game.State,
		Players = playerStates,
		Dealer = {
			Hand = game.Dealer.Hand,
			Score = game.Dealer.Score
		},
		CurrentPlayerIndex = game.CurrentPlayerIndex
	})
end

-- HIT (RÚT BÀI)
function MatchService:Hit(player, seatName)
	local game = ActiveGames[seatName]
	if not game or game.State ~= "PLAYER_TURN" then return false end
	
	local currentPlayer = game.Players[game.CurrentPlayerIndex]
	if not currentPlayer or currentPlayer.Player ~= player then return false end
	if currentPlayer.HasActed then return false end
	
	-- Mark timeout as cancelled (không cancel thread đang chạy)
	game.TurnTimeout = nil
	
	-- Rút bài
	table.insert(currentPlayer.Hand, table.remove(game.Deck, 1))
	currentPlayer.Score = CalculateScore(currentPlayer.Hand)
	
	-- Check bust
	if currentPlayer.Score > 21 then
		currentPlayer.State = "BUST"
		currentPlayer.HasActed = true
		self:BroadcastGameState(seatName)
		task.wait(1)
		self:CheckNextTurn(seatName)
	else
		self:BroadcastGameState(seatName)
		-- Restart timeout sau khi HIT
		local timeoutId = {}
		game.TurnTimeout = timeoutId
		task.spawn(function()
			self:StartTimer(seatName, 10, function()
				if game.TurnTimeout == timeoutId and currentPlayer and not currentPlayer.HasActed then
					print("[MATCH] Player", currentPlayer.Player.Name, "timeout - auto STAND")
					currentPlayer.State = "STAND"
					currentPlayer.HasActed = true
					self:BroadcastGameState(seatName)
					task.wait(0.5)
					self:CheckNextTurn(seatName)
				end
			end)
		end)
	end
	
	return true
end

-- STAND (DỪNG RÚT)
function MatchService:Stand(player, seatName)
	local game = ActiveGames[seatName]
	if not game or game.State ~= "PLAYER_TURN" then return false end
	
	local currentPlayer = game.Players[game.CurrentPlayerIndex]
	if not currentPlayer or currentPlayer.Player ~= player then return false end
	if currentPlayer.HasActed then return false end
	
	-- Mark timeout as cancelled (không cancel thread đang chạy)
	game.TurnTimeout = nil
	
	currentPlayer.State = "STAND"
	currentPlayer.HasActed = true
	
	self:BroadcastGameState(seatName)
	task.wait(0.5)
	self:CheckNextTurn(seatName)
	
	return true
end

-- CHECK NEXT TURN
function MatchService:CheckNextTurn(seatName)
	local game = ActiveGames[seatName]
	if not game then return end
	
	-- Mark timeout as cancelled (không cancel thread đang chạy)
	game.TurnTimeout = nil
	
	-- Tìm player tiếp theo chưa act
	local foundNext = false
	for i = game.CurrentPlayerIndex + 1, #game.Players do
		if not game.Players[i].HasActed then
			game.CurrentPlayerIndex = i
			foundNext = true
			self:BroadcastGameState(seatName)
			
			-- Start 10s timeout for player turn
			local timeoutId = {}
			game.TurnTimeout = timeoutId
			task.spawn(function()
				self:StartTimer(seatName, 10, function()
					-- Auto STAND if player doesn't act in time
					local currentPlayer = game.Players[game.CurrentPlayerIndex]
					if game.TurnTimeout == timeoutId and currentPlayer and not currentPlayer.HasActed then
						print("[MATCH] Player", currentPlayer.Player.Name, "timeout - auto STAND")
						currentPlayer.State = "STAND"
						currentPlayer.HasActed = true
						self:BroadcastGameState(seatName)
						task.wait(0.5)
						self:CheckNextTurn(seatName)
					end
				end)
			end)
			
			return
		end
	end
	
	-- Nếu không còn player nào, chuyển sang dealer turn
	if not foundNext then
		self:DealerTurn(seatName)
	end
end

-- DEALER TURN
function MatchService:DealerTurn(seatName)
	local game = ActiveGames[seatName]
	if not game then return end
	
	print("[MATCH] Dealer turn for", seatName)
	game.State = "DEALER_TURN"
	
	-- Lật lá úp
	game.Dealer.Hand[2] = game.Dealer.HiddenCard
	game.Dealer.Score = CalculateScore(game.Dealer.Hand)
	self:BroadcastGameState(seatName)
	
	task.wait(1)
	
	-- Dealer rút bài đến khi >= 17
	while game.Dealer.Score < 17 do
		table.insert(game.Dealer.Hand, table.remove(game.Deck, 1))
		game.Dealer.Score = CalculateScore(game.Dealer.Hand)
		self:BroadcastGameState(seatName)
		task.wait(1)
	end
	
	self:FinishGame(seatName)
end

-- FINISH GAME
function MatchService:FinishGame(seatName)
	local game = ActiveGames[seatName]
	if not game then return end
	
	print("[MATCH] Finishing game for", seatName)
	game.State = "FINISHED"
	
	local dealerScore = game.Dealer.Score
	local dealerBust = dealerScore > 21
	
	-- Tính kết quả cho từng player
	for _, p in ipairs(game.Players) do
		local result = "LOSE"
		local winAmount = 0
		
		if p.State == "BUST" then
			result = "BUST"
		elseif p.State == "BLACKJACK" then
			result = "BLACKJACK"
			winAmount = math.floor(p.Bet * 2.5)
		elseif dealerBust then
			result = "WIN"
			winAmount = p.Bet * 2
		elseif p.Score > dealerScore then
			result = "WIN"
			winAmount = p.Bet * 2
		elseif p.Score == dealerScore then
			result = "PUSH"
			winAmount = p.Bet
		else
			result = "LOSE"
		end
		
		if winAmount > 0 then
			self.EconomyService:ModifyWallet(p.Player, winAmount)
		end
		
		-- Fire individual result
		self.Client.GameOver:Fire(p.Player, {
			Result = result,
			WinAmount = winAmount,
			PlayerScore = p.Score,
			DealerScore = dealerScore,
			DealerBust = dealerBust
		})
	end
	
	-- Đợi 5s rồi bắt đầu game mới nếu còn người chơi
	game.GameTimer = task.spawn(function()
		self:StartTimer(seatName, GameConfig.Blackjack.GameEndWaitTime, function()
			if #game.Players > 0 then
				game.State = "WAITING_BET"
				-- Reset hands và bet
				for _, p in ipairs(game.Players) do
					p.Hand = {}
					p.Score = 0
					p.Bet = 0
					p.State = "WAITING"
					p.HasActed = false
				end
				game.Dealer.Hand = {}
				game.Dealer.Score = 0
				game.MatchmakingTimer = nil
				self:BroadcastLobby(seatName)
			else
				ActiveGames[seatName] = nil
			end
		end)
	end)
end

-- CLIENT FUNCTIONS
function MatchService.Client:JoinGame(player, seatName)
	return self.Server:JoinGame(player, seatName)
end

function MatchService.Client:LeaveGame(player, seatName)
	return self.Server:LeaveGame(player, seatName)
end

function MatchService.Client:PlaceBet(player, seatName, bet)
	return self.Server:PlaceBet(player, seatName, bet)
end

function MatchService.Client:Hit(player, seatName)
	return self.Server:Hit(player, seatName)
end

function MatchService.Client:Stand(player, seatName)
	return self.Server:Stand(player, seatName)
end

return MatchService