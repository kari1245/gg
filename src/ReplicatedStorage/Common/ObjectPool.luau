-- [MODULE] ObjectPool.luau
-- Hệ thống tái sử dụng vật thể (Object Pooling System)
local ObjectPool = {}
ObjectPool.__index = ObjectPool

function ObjectPool.new(template: Instance, initSize: number)
	local self = setmetatable({}, ObjectPool)
	self.Template = template
	self.Available = {} -- Kho chứa đồ chưa dùng
	self.Container = nil -- Folder chứa đồ ẩn
	
	-- Tạo kho chứa ẩn dưới lòng đất hoặc xa vô tận
	local folder = Instance.new("Folder")
	folder.Name = "Pool_" .. template.Name
	folder.Parent = workspace
	self.Container = folder
	
	-- Pre-fill (Tạo sẵn một lượng nhất định)
	for i = 1, initSize or 10 do
		local item = self:CreateNew()
		self:Return(item) -- [FIXED] Sửa PutBack thành Return
	end
	
	return self
end

function ObjectPool:CreateNew()
	local clone = self.Template:Clone()
	return clone
end

-- Lấy vật thể ra dùng
function ObjectPool:Get()
	local item
	if #self.Available > 0 then
		item = table.remove(self.Available)
	else
		item = self:CreateNew()
	end
	return item
end

-- Trả vật thể về kho
function ObjectPool:Return(item: Instance)
	if not item then return end
	
	-- Reset trạng thái cơ bản để tránh lỗi hiển thị khi lấy ra lần sau
	if item:IsA("Model") then
		item:PivotTo(CFrame.new(0, -99999, 0)) -- Đưa xuống lòng đất
	elseif item:IsA("BasePart") then
		item.CFrame = CFrame.new(0, -99999, 0)
		item.Anchored = true
	end
	
	item.Parent = self.Container
	table.insert(self.Available, item)
end

function ObjectPool:Destroy()
	if self.Container then
		self.Container:Destroy()
	end
	self.Available = {}
	self.Template = nil
end

return ObjectPool