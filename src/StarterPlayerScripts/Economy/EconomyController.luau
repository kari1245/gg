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

	self.EcoService.MoneyUpdated:Connect(function(w, v) Wallet:set(w); Vault:set(v) end)
	self.EcoService:GetMoney():andThen(function(w, v) Wallet:set(w); Vault:set(v) end)

	local ui = View.New(scope, { Wallet = Wallet, Vault = Vault })
	ui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return EconomyController