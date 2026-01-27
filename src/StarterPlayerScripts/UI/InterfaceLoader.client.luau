-- Modules
local HUD = require(script.Parent.HUD)
local SciFiMenu = require(script.Parent.SciFiMenu)

-- Init
print("[Interface] Mounting components...")

-- 1. Khởi tạo Menu trước (để HUD có thể gọi nó)
local menuApi = SciFiMenu.Mount()

-- 2. Khởi tạo HUD và truyền menuApi vào để nút bấm có thể bật tắt Menu
HUD.Mount(menuApi)

print("[Interface] Ready.")