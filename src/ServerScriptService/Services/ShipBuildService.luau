--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local GRID_SIZE = 4

local ShipBuildService = Knit.CreateService {
	Name = "ShipBuildService",
	Client = {},
}

function ShipBuildService:KnitInit()
	local shipsFolder = Instance.new("Folder")
	shipsFolder.Name = "PlayerShips"
	shipsFolder.Parent = workspace
end

function ShipBuildService.Client:PlaceBlock(player: Player, blockType: string, cframe: CFrame)
	-- (Giữ nguyên code cũ của PlaceBlock...)
	if typeof(cframe) ~= "CFrame" or typeof(blockType) ~= "string" then return end
	
	local x = math.floor(cframe.Position.X / GRID_SIZE + 0.5) * GRID_SIZE
	local y = math.floor(cframe.Position.Y / GRID_SIZE + 0.5) * GRID_SIZE
	local z = math.floor(cframe.Position.Z / GRID_SIZE + 0.5) * GRID_SIZE
	local finalCF = CFrame.new(x, y, z)
	
	local overlapParams = OverlapParams.new()
	local parts = workspace:GetPartBoundsInBox(finalCF, Vector3.new(GRID_SIZE-0.1, GRID_SIZE-0.1, GRID_SIZE-0.1), overlapParams)
	if #parts > 0 then return end
	
	local newBlock = Instance.new("Part")
	newBlock.Name = blockType
	newBlock.Size = Vector3.new(GRID_SIZE, GRID_SIZE, GRID_SIZE)
	newBlock.CFrame = finalCF
	newBlock.Anchored = true
	newBlock.TopSurface = Enum.SurfaceType.Smooth
	newBlock.BottomSurface = Enum.SurfaceType.Smooth
	
	if blockType == "WoodBlock" then
		newBlock.Color = Color3.fromRGB(139, 69, 19)
		newBlock.Material = Enum.Material.Wood
	elseif blockType == "MetalBlock" then
		newBlock.Color = Color3.fromRGB(99, 102, 106)
		newBlock.Material = Enum.Material.Metal
	elseif blockType == "Engine" then
		newBlock.Color = Color3.fromRGB(255, 0, 0)
		newBlock.Material = Enum.Material.Neon
	elseif blockType == "PilotSeat" then
		newBlock:Destroy()
		newBlock = Instance.new("VehicleSeat")
		newBlock.Size = Vector3.new(GRID_SIZE, 1, GRID_SIZE)
		newBlock.CFrame = finalCF
		newBlock.Color = Color3.fromRGB(0, 255, 255)
	end
	
	newBlock:SetAttribute("Owner", player.UserId)
	newBlock.Parent = workspace.PlayerShips
end

-- [MỚI] Hàm xử lý xóa block
function ShipBuildService.Client:RemoveBlock(player: Player, targetPart: Instance)
	-- 1. Kiểm tra tồn tại
	if not targetPart or not targetPart:IsA("BasePart") then return end
	
	-- 2. Kiểm tra chủ sở hữu (Chỉ xóa được block của chính mình)
	local ownerId = targetPart:GetAttribute("Owner")
	if ownerId == player.UserId then
		-- Tạo hiệu ứng nổ nhỏ hoặc âm thanh nếu muốn
		targetPart:Destroy()
		print(player.Name, "deleted a block.")
	else
		warn("Cannot delete block owned by someone else.")
	end
end

return ShipBuildService