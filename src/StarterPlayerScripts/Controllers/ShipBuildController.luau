--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local GRID_SIZE = 4
local MAX_BUILD_DIST = 50

local ShipBuildController = Knit.CreateController { Name = "ShipBuildController" }

function ShipBuildController:KnitStart()
	self.ShipBuildService = Knit.GetService("ShipBuildService")
	self.Mouse = Players.LocalPlayer:GetMouse()
	
	self.SelectedBlockType = nil :: string?
	self.GhostPart = nil :: BasePart?
	
	-- [MỚI] SelectionBox để highlight block muốn xóa
	self.DeleteSelectionBox = Instance.new("SelectionBox")
	self.DeleteSelectionBox.Color3 = Color3.fromRGB(255, 0, 0)
	self.DeleteSelectionBox.LineThickness = 0.05
	self.DeleteSelectionBox.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	self.TargetDeletePart = nil :: BasePart?

	RunService.RenderStepped:Connect(function()
		self:UpdateLoop()
	end)
	
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:HandleClick()
		end
	end)
end

-- Hàm hủy bỏ chế độ xây dựng (Được gọi từ UI nút Stop)
function ShipBuildController:CancelBuild()
	self:SelectBlock(nil)
end

function ShipBuildController:SelectBlock(blockName: string?)
	self.SelectedBlockType = blockName
	
	-- Reset trạng thái cũ
	if self.GhostPart then self.GhostPart:Destroy() self.GhostPart = nil end
	self.DeleteSelectionBox.Adornee = nil
	self.TargetDeletePart = nil
	
	if not blockName then return end -- Nếu cancel thì dừng tại đây

	if blockName == "TRASH" then
		-- Chế độ xóa: Không cần tạo ghost part
	else
		-- Chế độ xây: Tạo ghost part
		local ghost = Instance.new("Part")
		ghost.Name = "GhostBlock"
		ghost.Size = Vector3.new(GRID_SIZE, GRID_SIZE, GRID_SIZE)
		ghost.Transparency = 0.5
		ghost.CanCollide = false
		ghost.Anchored = true
		ghost.Material = Enum.Material.ForceField
		ghost.Color = Color3.fromRGB(0, 255, 0)
		ghost.Parent = workspace
		self.GhostPart = ghost
	end
end

function ShipBuildController:UpdateLoop()
	if not self.SelectedBlockType then return end
	
	local mouseRay = self.Mouse.UnitRay
	local params = RaycastParams.new()
	-- Lọc bỏ nhân vật và ghost part
	params.FilterDescendantsInstances = {
		self.GhostPart, 
		Players.LocalPlayer.Character
	}
	params.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * MAX_BUILD_DIST, params)
	
	if self.SelectedBlockType == "TRASH" then
		-- [LOGIC XÓA] Tìm part của người chơi
		if result and result.Instance and result.Instance:GetAttribute("Owner") == Players.LocalPlayer.UserId then
			self.TargetDeletePart = result.Instance
			self.DeleteSelectionBox.Adornee = result.Instance
		else
			self.TargetDeletePart = nil
			self.DeleteSelectionBox.Adornee = nil
		end
	elseif self.GhostPart then
		-- [LOGIC XÂY]
		if result then
			local pos = result.Position
			local normal = result.Normal
			local targetPos = pos + (normal * (GRID_SIZE / 2))
			local snappedX = math.floor(targetPos.X / GRID_SIZE + 0.5) * GRID_SIZE
			local snappedY = math.floor(targetPos.Y / GRID_SIZE + 0.5) * GRID_SIZE
			local snappedZ = math.floor(targetPos.Z / GRID_SIZE + 0.5) * GRID_SIZE
			
			self.GhostPart.CFrame = CFrame.new(snappedX, snappedY, snappedZ)
			self.GhostPart.Color = Color3.fromRGB(0, 255, 0)
		else
			self.GhostPart.CFrame = CFrame.new(0, -999, 0)
		end
	end
end

function ShipBuildController:HandleClick()
	if not self.SelectedBlockType then return end
	
	if self.SelectedBlockType == "TRASH" then
		-- [ACTION XÓA]
		if self.TargetDeletePart then
			self.ShipBuildService:RemoveBlock(self.TargetDeletePart)
			-- Reset selection tạm thời để tránh lỗi visual
			self.DeleteSelectionBox.Adornee = nil
			self.TargetDeletePart = nil
		end
	else
		-- [ACTION XÂY]
		if self.GhostPart and self.GhostPart.Position.Y > -500 then
			self.ShipBuildService:PlaceBlock(self.SelectedBlockType, self.GhostPart.CFrame)
		end
	end
end

return ShipBuildController