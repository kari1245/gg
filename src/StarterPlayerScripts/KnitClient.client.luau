local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Root = script.Parent

-- Quét tất cả thư mục con (Achievement, Inventory, Economy...)
for _, folder in ipairs(Root:GetChildren()) do
	if folder:IsA("Folder") then
		-- Tìm file Controller trong folder đó
		for _, file in ipairs(folder:GetChildren()) do
			if file:IsA("ModuleScript") and file.Name:match("Controller$") then
				require(file)
			end
		end
	end
end

Knit.Start():andThen(function()
	print("✅ Knit Client Started (Flat Modular Structure)")
end):catch(warn)