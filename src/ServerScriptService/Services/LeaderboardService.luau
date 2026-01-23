local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)

local LeaderboardService = Knit.CreateService { Name = "LeaderboardService" }

function LeaderboardService:KnitInit()
	self.DataService = Knit.GetService("DataService")
	self.EconomyService = Knit.GetService("EconomyService")
end

function LeaderboardService:KnitStart()
	Players.PlayerAdded:Connect(function(player)
		self:SetupLeaderstats(player)
	end)
	
	-- Setup cho players đã có sẵn
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function() self:SetupLeaderstats(player) end)
	end
end

function LeaderboardService:SetupLeaderstats(player)
	-- Đợi profile load xong
	local profile = self.DataService:WaitForProfile(player)
	if not profile then return end
	
	-- Tạo folder leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	-- Tạo StringValue để hiển thị tổng giá trị
	local totalValue = Instance.new("StringValue")
	totalValue.Name = "💎 Net Worth"
	totalValue.Value = "$0"
	totalValue.Parent = leaderstats
	
	-- Update lần đầu
	self:UpdateLeaderboard(player)
	
	-- Lắng nghe thay đổi từ EconomyService
	if self.EconomyService and self.EconomyService.MoneyUpdated then
		self.EconomyService.MoneyUpdated:Connect(function(targetPlayer)
			if targetPlayer == player then
				self:UpdateLeaderboard(player)
			end
		end)
	end
end

function LeaderboardService:UpdateLeaderboard(player)
	local profile = self.DataService:GetProfile(player)
	if not profile then return end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	
	local netWorthValue = leaderstats:FindFirstChild("💎 Net Worth")
	if not netWorthValue then return end
	
	-- Tính tổng: Wallet + Vault + NFT Value
	local wallet = profile.Data.Wallet or 0
	local vault = profile.Data.Vault or 0
	local nftValue = 0
	
	-- Tính tổng giá trị NFT
	for _, nft in ipairs(profile.Data.NftInventory or {}) do
		nftValue = nftValue + (nft.Price or 0)
	end
	
	local total = wallet + vault + nftValue
	
	-- Format số tiền
	local formatted
	if total >= 1e10 then
		if total >= 1e12 then formatted = string.format("%.1fT", total/1e12)
		elseif total >= 1e9 then formatted = string.format("%.1fB", total/1e9)
		elseif total >= 1e6 then formatted = string.format("%.1fM", total/1e6)
		else formatted = string.format("%.1fK", total/1e3) end
	else
		formatted = tostring(math.floor(total)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	end
	
	netWorthValue.Value = "$" .. formatted
end

-- Public method để các service khác có thể trigger update
function LeaderboardService:RefreshPlayer(player)
	self:UpdateLeaderboard(player)
end

return LeaderboardService
