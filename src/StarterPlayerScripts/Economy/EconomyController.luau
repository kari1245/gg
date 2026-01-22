local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local View = require(script.Parent.EconomyView)

local EconomyController = Knit.CreateController { Name = "EconomyController" }

function EconomyController:KnitStart()
	self.EcoService = Knit.GetService("EconomyService")
	
	local scope = Fusion.scoped(Fusion)
	local Wallet = scope:Value(0)
	local Vault = scope:Value(0)
	
	-- [FIX] Lắng nghe sự kiện từ Server (Khi làm Job hoặc mua đồ xong)
	self.EcoService.MoneyUpdated:Connect(function(w, v)
		Wallet:set(w)
		Vault:set(v)
	end)
	
	-- Lấy dữ liệu lần đầu
	self.EcoService:GetData():andThen(function(w, v)
		Wallet:set(w or 0)
		Vault:set(v or 0)
	end)
	
	local ui = View.New(scope, {
		Wallet = Wallet,
		Vault = Vault
	})
	
	ui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return EconomyController