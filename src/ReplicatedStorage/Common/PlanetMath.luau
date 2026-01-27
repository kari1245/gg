local PlanetMath = {}

-- Copy logic Random từ code cũ của bạn
function PlanetMath.SeededRandom(seed: number, min: number?, max: number?): number
	local x = math.sin(seed) * 10000
	local frac = x - math.floor(x)
	if min and max then return min + frac * (max - min) end
	return frac
end

function PlanetMath.GetGridJitter(seed: number, amount: number): number
	local x = math.sin(seed) * 10000
	return (x - math.floor(x)) * 2 * amount - amount
end

-- Logic tạo vị trí Objects (Cây, Đá) chuyển về đây
-- Trả về danh sách dữ liệu nhẹ để Client loop qua và Clone model
function PlanetMath.GenerateVegetationData(seed: number, size: number, worldPos: Vector3)
	local objects = {}
	local groundDiameter = math.min(size * 0.4, size * 0.98)
	local groundArea = groundDiameter * groundDiameter
	
	-- Tính toán mật độ (Logic cũ)
	local treeDensity = math.clamp(math.floor(groundArea * 0.0012), 12, 120)
	local rockDensity = math.clamp(math.floor(groundArea * 0.0007), 6, 60)
	
	local numTrees = math.floor(PlanetMath.SeededRandom(seed + 8888, 0, treeDensity + 0.99))
	local numRocks = math.floor(PlanetMath.SeededRandom(seed + 9999, 0, rockDensity + 0.99))
	
	local objectMap = {}
	local tileY = 3
	local groundY = worldPos.Y

	-- 1. Tạo dữ liệu Cây
	for i = 1, numTrees do
		local objSeed = seed + i * 1009 + 20000
		local relX = PlanetMath.SeededRandom(objSeed + 1, -0.5, 0.5) * (groundDiameter * 0.98)
		local relZ = PlanetMath.SeededRandom(objSeed + 2, -0.5, 0.5) * (groundDiameter * 0.98)
		
		local posX = worldPos.X + relX 
		local posY = groundY + tileY/2 
		local posZ = worldPos.Z + relZ
		local key = math.floor(posX*10)..","..math.floor(posZ*10) -- Key đơn giản hơn
		
		if not objectMap[key] then
			local treeType = tostring(math.clamp(math.floor(PlanetMath.SeededRandom(objSeed + 20000, 1, 5.99)), 1, 5))
			local rotY = PlanetMath.SeededRandom(objSeed + 30000, 0, 360)
			local scale = 0.85 + PlanetMath.SeededRandom(objSeed + 40000, 0, 0.3)
			
			table.insert(objects, {
				Type = "Tree", 
				Model = treeType, -- Tên model trong ReplicatedStorage.Trees
				PosX = posX, PosY = posY, PosZ = posZ, 
				RotY = rotY, 
				Scale = scale
			})
			objectMap[key] = true
		end
	end

	-- 2. Tạo dữ liệu Đá
	for i = 1, numRocks do
		local objSeed = seed + i * 2009 + 30000
		local relX = PlanetMath.SeededRandom(objSeed + 1, -0.5, 0.5) * (groundDiameter * 0.98)
		local relZ = PlanetMath.SeededRandom(objSeed + 2, -0.5, 0.5) * (groundDiameter * 0.98)
		
		local posX = worldPos.X + relX
		local posY = groundY + tileY/2
		local posZ = worldPos.Z + relZ
		local key = math.floor(posX*10)..","..math.floor(posZ*10)
		
		if not objectMap[key] then
			local rockType = tostring(math.clamp(math.floor(PlanetMath.SeededRandom(objSeed + 30000, 1, 5.99)), 1, 5))
			local rotY = PlanetMath.SeededRandom(objSeed + 35000, 0, 360)
			local scale = 0.85 + PlanetMath.SeededRandom(objSeed + 45000, 0, 0.3)
			
			table.insert(objects, {
				Type = "Rock", 
				Model = rockType, -- Tên model trong ReplicatedStorage.Rocks
				PosX = posX, PosY = posY, PosZ = posZ, 
				RotY = rotY, 
				Scale = scale
			})
			objectMap[key] = true
		end
	end
	
	return objects
end

return PlanetMath