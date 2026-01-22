local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GameConfig = require(ReplicatedStorage.Common.GameConfig)

local ShopView = {}

local function CyberButton(scope, props)
	local isHover = scope:Value(false)
	local scale = scope:Spring(scope:Computed(function(use) return use(isHover) and 1.05 or 1 end), 40, 1)
	
	return scope:New "TextButton" {
		Text = "", Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = Color3.fromRGB(20, 25, 35),
		
		-- [FIX 1] Dùng Computed để tự động mờ đi khi Disabled
		BackgroundTransparency = scope:Computed(function(use)
			return use(props.Disabled) and 0.5 or 0
		end),
		
		AutoButtonColor = false,
		
		[Fusion.OnEvent "MouseEnter"] = function() 
			-- [FIX 2] Dùng peek để check đúng giá trị
			if not Fusion.peek(props.Disabled) then isHover:set(true) end 
		end,
		
		[Fusion.OnEvent "MouseLeave"] = function() isHover:set(false) end,
		
		[Fusion.OnEvent "Activated"] = function() 
			-- [FIX 3] QUAN TRỌNG NHẤT: Dùng peek để lấy giá trị boolean
			local isDisabled = Fusion.peek(props.Disabled)
			
			if not isDisabled and props.OnClick then 
				props.OnClick() -- Gọi hàm mua
			end 
		end,
		
		[Fusion.Children] = {
			scope:New "UIScale" { Scale = scale },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" {
				Thickness = 2, Transparency = 0,
				[Fusion.Children] = {
					scope:New "UIGradient" {
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, props.Color or Color3.new(1,1,1)),
							ColorSequenceKeypoint.new(1, Color3.new(0,0,0))
						},
						Rotation = 90
					}
				}
			},
			scope:New "TextLabel" {
				Text = props.Text or "",
				Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
				TextColor3 = props.Color,
				Font = Enum.Font.GothamBlack, TextSize = 14,
				ZIndex = 2
			}
		}
	}
end

function ShopView.New(scope, props)
	local inspectItem = scope:Value(nil)
	
	return scope:New "ScreenGui" {
		Name = "UI_Shop", ResetOnSpawn = false, DisplayOrder = 20,
		[Fusion.Children] = {
			CyberButton(scope, {
				Text = "NFTs", Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0, 20, 0.5, 60),
				Color = Color3.fromRGB(0, 255, 255), OnClick = props.OnToggle
			}),

			-- SHOP MODAL
			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(props.IsOpen) end),
				Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(10, 15, 20),
				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },
					scope:New "UIStroke" { Thickness = 3, Color = Color3.fromRGB(0, 200, 255) },
					
					scope:New "TextLabel" { Text = "NFT MARKETPLACE", Size = UDim2.new(1,0,0,50), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(0,255,255), Font = Enum.Font.GothamBlack, TextSize = 30 },
					CyberButton(scope, { Text = "X", Size = UDim2.fromOffset(40,40), Position = UDim2.new(1,-10,0,10), AnchorPoint = Vector2.new(1,0), Color = Color3.fromRGB(255,50,50), OnClick = props.OnClose }),

					scope:New "ScrollingFrame" {
						Size = UDim2.new(1, -20, 1, -60), Position = UDim2.new(0, 10, 0, 60),
						BackgroundTransparency = 1, AutomaticCanvasSize = "Y", CanvasSize = UDim2.new(),
						[Fusion.Children] = {
							scope:New "UIGridLayout" { CellSize = UDim2.new(0, 200, 0, 120), CellPadding = UDim2.new(0, 10, 0, 10) },
							scope:ForValues(props.DailyItems, function(use, inner, item)
								local rarityInfo = GameConfig.NftRarities[item.Rarity] or GameConfig.NftRarities.Common
								local color = rarityInfo.Color
								local sold = item.Sold == true
								
								return inner:New "TextButton" {
									BackgroundColor3 = Color3.fromRGB(20, 25, 30), AutoButtonColor = false,
									[Fusion.OnEvent "Activated"] = function() inspectItem:set(item) end,
									[Fusion.Children] = {
										inner:New "UICorner" { CornerRadius = UDim.new(0, 8) },
										inner:New "UIStroke" { Color = color, Thickness = 2, Transparency = sold and 0.8 or 0 },
										inner:New "TextLabel" {
											Text = string.sub(item.Hash, 1, 8) .. "...", 
											Size = UDim2.new(1,0,0.4,0), Position = UDim2.fromScale(0, 0.1),
											BackgroundTransparency = 1, TextColor3 = color, Font = Enum.Font.Code, TextSize = 20
										},
										inner:New "TextLabel" {
											Text = sold and "SOLD OUT" or "$"..item.Price,
											Size = UDim2.new(1,0,0.3,0), Position = UDim2.fromScale(0, 0.6),
											BackgroundTransparency = 1, TextColor3 = sold and Color3.fromRGB(100,100,100) or Color3.fromRGB(0,255,100), Font = Enum.Font.GothamBold, TextSize = 18
										}
									}
								}
							end)
						}
					}
				}
			},

			-- INSPECT MODAL
			scope:New "Frame" {
				Visible = scope:Computed(function(use) return use(inspectItem) ~= nil end),
				Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.5, ZIndex = 10,
				[Fusion.Children] = {
					scope:New "Frame" {
						Size = UDim2.fromOffset(400, 300), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(15, 20, 25),
						[Fusion.Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
							scope:New "UIStroke" { Color = Color3.fromRGB(255, 255, 255), Thickness = 2 },
							
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) local item = use(inspectItem); return item and ("HASH: " .. item.Hash) or "" end),
								Size = UDim2.new(0.9, 0, 0, 100), Position = UDim2.new(0.05, 0, 0.1, 0),
								BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(0, 255, 255), 
								Font = Enum.Font.Code, TextSize = 24, TextWrapped = true
							},
							
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) local item = use(inspectItem); return item and ("RARITY: " .. item.Rarity:upper()) or "" end),
								Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromScale(0, 0.5),
								BackgroundTransparency = 1, TextColor3 = scope:Computed(function(use)
									local item = use(inspectItem)
									return item and (GameConfig.NftRarities[item.Rarity] or {}).Color or Color3.new(1,1,1)
								end), Font = Enum.Font.GothamBlack, TextSize = 20
							},

							-- NÚT MUA (Đã sửa Disabled logic ở hàm CyberButton trên)
							CyberButton(scope, {
								Text = scope:Computed(function(use) 
									local item = use(inspectItem)
									return item and (item.Sold and "SOLD" or "BUY ($"..item.Price..")") or ""
								end),
								Size = UDim2.new(0.4, 0, 0, 50), Position = UDim2.new(0.3, 0, 0.7, 0),
								Color = Color3.fromRGB(0, 255, 100),
								Disabled = scope:Computed(function(use) local item = use(inspectItem); return item and item.Sold end),
								OnClick = function() 
									local item = Fusion.peek(inspectItem)
									if item and not item.Sold then 
										props.OnBuy(item.Hash) 
										inspectItem:set(nil)
									end
								end
							}),
							
							CyberButton(scope, {
								Text = "CLOSE", Size = UDim2.new(0.2, 0, 0, 30), Position = UDim2.new(0.4, 0, 0.9, 0),
								Color = Color3.fromRGB(255, 100, 100),
								OnClick = function() inspectItem:set(nil) end
							})
						}
					}
				}
			}
		}
	}
end

return ShopView