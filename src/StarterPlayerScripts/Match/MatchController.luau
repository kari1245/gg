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
	local PlayerHand = scope:Value({})
	local DealerHand = scope:Value({})
	local Result = scope:Value("PLACE BET")
	local BetInput = scope:Value(50)

	-- Seat Logic
	local player = Players.LocalPlayer
	local function onChar(char)
		local hum = char:WaitForChild("Humanoid")
		hum.Seated:Connect(function(active, seat)
			IsSitting:set(active and seat and seat.Name == "GameSeat")
		end)
	end
	if player.Character then onChar(player.Character) end
	player.CharacterAdded:Connect(onChar)

	self.MatchService.MatchUpdate:Connect(function(d)
		-- [FIX] Thêm or {} để tránh lỗi nil
		PlayerHand:set(d.PlayerHand or {})
		DealerHand:set(d.DealerHand or {})
	end)

	self.MatchService.GameOver:Connect(function(d)
		-- [FIX] Thêm or {} để tránh lỗi nil
		PlayerHand:set(d.PlayerHand or {})
		DealerHand:set(d.DealerHand or {})
		Result:set(d.Result .. " [$"..d.WinAmount.."]")
	end)

	local ui = View.New(scope, {
		IsSitting = IsSitting, PlayerHand = PlayerHand, DealerHand = DealerHand, Result = Result, BetInput = BetInput,
		OnStart = function() 
			self.MatchService:StartMatch(Fusion.peek(BetInput)) 
			Result:set("PLAYING...")
		end,
		OnHit = function() self.MatchService:Hit() end,
		OnStand = function() self.MatchService:Stand() end
	})
	ui.Parent = player:WaitForChild("PlayerGui")
end

return MatchController