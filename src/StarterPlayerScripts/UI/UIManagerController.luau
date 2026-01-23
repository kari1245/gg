local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local UIManagerController = Knit.CreateController { Name = "UIManagerController" }

function UIManagerController:KnitInit()
	self.scope = Fusion.scoped(Fusion)
	self.CurrentOpenUI = self.scope:Value(nil) -- Lưu tên UI đang mở
	self.UIStates = {} -- Lưu các IsOpen states của các UI
end

function UIManagerController:RegisterUI(name, isOpenState)
	self.UIStates[name] = isOpenState
	
	-- Observe khi UI này mở
	self.scope:Observer(isOpenState):onChange(function()
		local isOpen = Fusion.peek(isOpenState)
		if isOpen then
			self:SetOpenUI(name)
		end
	end)
end

function UIManagerController:SetOpenUI(name)
	local currentOpen = Fusion.peek(self.CurrentOpenUI)
	
	-- Nếu đang có UI khác mở, đóng nó lại
	if currentOpen and currentOpen ~= name then
		local oldState = self.UIStates[currentOpen]
		if oldState then
			oldState:set(false)
		end
	end
	
	self.CurrentOpenUI:set(name)
end

function UIManagerController:CloseAll()
	for _, state in pairs(self.UIStates) do
		state:set(false)
	end
	self.CurrentOpenUI:set(nil)
end

return UIManagerController
