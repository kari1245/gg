local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local CosmeticSystem = Knit.CreateService { Name = "CosmeticSystem", Client = {} }

function CosmeticSystem:UpdateVisual(player, itemId)
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end

	-- Xóa visual cũ
	local old = head:FindFirstChild("CosmeticDisplay")
	if old then old:Destroy() end

	if not itemId then return end -- Unequip

	local item = GameConfig.GetItemInfo(itemId)
	if item and item.Image then
		-- Tạo BillboardGui chứa hình ảnh
		local bb = Instance.new("BillboardGui")
		bb.Name = "CosmeticDisplay"
		bb.Size = UDim2.new(0, 30, 0, 30) -- Kích thước icon
		bb.StudsOffset = Vector3.new(1.5, 1, 0) -- Bay lơ lửng bên phải đầu
		bb.AlwaysOnTop = true
		bb.Adornee = head
		bb.Parent = head

		local img = Instance.new("ImageLabel")
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 1
		img.Image = item.Image
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = bb

		-- Hiệu ứng bay lên xuống nhẹ
		task.spawn(function()
			local t = 0
			while bb.Parent do
				t += task.wait()
				bb.StudsOffset = Vector3.new(1.5, 1 + math.sin(t * 2) * 0.2, 0)
			end
		end)
	end
end

return CosmeticSystem