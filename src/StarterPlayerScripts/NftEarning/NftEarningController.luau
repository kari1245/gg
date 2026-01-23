local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local View = require(script.Parent.NftEarningView)

local NftEarningController = Knit.CreateController({
	Name = "NftEarningController"
})

function NftEarningController:KnitStart()
	print("🎮 NftEarningController starting...")
	
	local Player = Players.LocalPlayer
	local PlayerGui = Player:WaitForChild("PlayerGui")
	
	-- Get Services
	self.NftService = Knit.GetService("NftEarningService")
	self.InventoryService = Knit.GetService("InventoryService")
	self.SoundController = Knit.GetController("SoundController")
	self.UIManager = Knit.GetController("UIManagerController")
	
	-- Fusion scope
	local scope = Fusion.scoped(Fusion)
	
	-- States
	local IsOpen = scope:Value(false)
	
	-- Register với UIManager
	if self.UIManager then
		self.UIManager:RegisterUI("NftEarning", IsOpen)
	end
	local AllNfts = scope:Value({})
	local StakingInfo = scope:Value({ StakedNfts = {}, EquippedNfts = {} })
	local CurrentTab = scope:Value("All") -- Default tab
	
	-- Rarity order for sorting (Glitch > Legendary > Epic > Rare > Uncommon > Common)
	local RarityOrder = {
		Glitch = 6,
		Legendary = 5,
		Epic = 4,
		Rare = 3,
		Uncommon = 2,
		Common = 1
	}
	
	-- Computed: All NFTs sorted by rarity (descending) with equipped status
	local AllNftsSorted = scope:Computed(function(use)
		local all = use(AllNfts)
		local info = use(StakingInfo)
		local nfts = {}
		
		-- Add equipped status to each NFT
		for _, nft in ipairs(all) do
			local isEquipped = false
			for _, equippedId in ipairs(info and info.EquippedNfts or {}) do
				if nft.Hash == equippedId then
					isEquipped = true
					break
				end
			end
			
			table.insert(nfts, {
				Hash = nft.Hash,
				Rarity = nft.Rarity,
				Price = nft.Price,
				Timestamp = nft.Timestamp,
				IsEquipped = isEquipped
			})
		end
		
		-- Sort by rarity (highest first)
		table.sort(nfts, function(a, b)
			return (RarityOrder[a.Rarity] or 0) > (RarityOrder[b.Rarity] or 0)
		end)
		
		return nfts
	end)
	
	-- Functions
	local function RefreshData()
		-- Get all NFTs from inventory
		self.InventoryService:GetData():andThen(function(nfts)
			if nfts then
				AllNfts:set(nfts)
			end
		end):catch(function(err)
			warn("Failed to get inventory:", err)
		end)
		
		-- Get staking info
		self.NftService:GetStakingInfo():andThen(function(info)
			if info then
				StakingInfo:set(info)
			end
		end):catch(function(err)
			warn("Failed to get staking info:", err)
		end)
	end
	
	local function OnToggle()
		local newState = not Fusion.peek(IsOpen)
		IsOpen:set(newState)
		
		if newState then
			RefreshData()
			if self.SoundController then
				self.SoundController:Play("UI_Click")
			end
		else
			if self.SoundController then
				self.SoundController:Play("UI_Click")
			end
		end
	end
	
	local function OnClose()
		IsOpen:set(false)
		if self.SoundController then
			self.SoundController:Play("UI_Click")
		end
	end
	
	local function OnTabChange(newTab)
		CurrentTab:set(newTab)
		if self.SoundController then
			self.SoundController:Play("UI_Click")
		end
	end
	
	local function OnToggleEquip(nftId, isCurrentlyEquipped)
		if self.SoundController then
			self.SoundController:Play("UI_Click")
		end
		
		local success, result, message = pcall(function()
			if isCurrentlyEquipped then
				return self.NftService:UnequipNft(nftId):await()
			else
				return self.NftService:EquipNft(nftId):await()
			end
		end)
		
		if success and result then
			-- Service returned (true, "SUCCESS")
			RefreshData()
			if self.SoundController then
				self.SoundController:Play("SFX_Win")
			end
		else
			-- Failed: either pcall error or service returned (false, error_msg)
			local errorMsg = success and message or result
			warn("Failed to toggle equip NFT:", errorMsg)
		end
	end
	
	-- Create UI
	local ui = View.New(scope, {
		IsOpen = IsOpen,
		AllNfts = AllNftsSorted,
		OnToggle = OnToggle,
		OnClose = OnClose,
		OnToggleEquip = OnToggleEquip
	})
	
	ui.Parent = PlayerGui
	
	print("✅ NftEarningController UI created and parented!")
	
	-- Public methods
	self.Toggle = OnToggle
	self.RefreshData = RefreshData
	
	-- Auto-refresh every 30 seconds
	task.spawn(function()
		while true do
			task.wait(30)
			if Fusion.peek(IsOpen) then
				RefreshData()
			end
		end
	end)
end

return NftEarningController
