local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local SpaceFlightController = Knit.CreateController { Name = "SpaceFlightController" }

-- Flight Settings
local FLIGHT_SPEED = 150 -- Base speed
local BOOST_MULTIPLIER = 3 -- Shift to boost
local ROTATION_SPEED = 0.05
local ACCELERATION = 15
local DECELERATION = 10

function SpaceFlightController:KnitStart()
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")
	
	-- Flight state
	local isFlying = false
	local currentVelocity = Vector3.zero
	local targetVelocity = Vector3.zero
	local bodyVelocity, bodyGyro
	
	-- Camera state
	local camera = workspace.CurrentCamera
	local cameraCFrame = camera.CFrame
	
	-- Input state
	local inputs = {
		Forward = false,
		Backward = false,
		Left = false,
		Right = false,
		Up = false,
		Down = false,
		Boost = false
	}
	
	-- Mobile UI button and references
	local flightButton
	local stroke
	local glow
	local textLabel
	
	-- Toggle flight mode
	local function ToggleFlight()
		isFlying = not isFlying
		
		if isFlying then
			-- Enable flight
			humanoid.PlatformStand = true
			
			-- Clean up any existing instances first
			if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
			if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
			
			-- Create BodyVelocity
			bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(4e4, 4e4, 4e4)
			bodyVelocity.Velocity = Vector3.zero
			bodyVelocity.Parent = rootPart
			
			-- Create BodyGyro for rotation
			bodyGyro = Instance.new("BodyGyro")
			bodyGyro.MaxTorque = Vector3.new(4e4, 4e4, 4e4)
			bodyGyro.P = 3000
			bodyGyro.D = 500
			bodyGyro.Parent = rootPart
			
			-- Change camera mode
			camera.CameraType = Enum.CameraType.Custom
			
			-- Update mobile button
			if flightButton and stroke and glow and textLabel then
				textLabel.Text = "[ LANDING ]"
				stroke.Color = Color3.fromRGB(255, 0, 100) -- GlitchRed
				textLabel.TextColor3 = Color3.fromRGB(255, 0, 100)
				glow.ImageColor3 = Color3.fromRGB(255, 0, 100)
			end
			
			print("🚀 Flight Mode: ON")
		else
			-- Disable flight - ensure complete cleanup
			if bodyVelocity and bodyVelocity.Parent then 
				bodyVelocity:Destroy() 
			end
			if bodyGyro and bodyGyro.Parent then 
				bodyGyro:Destroy() 
			end
			bodyVelocity = nil
			bodyGyro = nil
			
			-- Reset character state
			if humanoid and humanoid.Parent then
				humanoid.PlatformStand = false
			end
			
			-- Reset velocities
			if rootPart and rootPart.Parent then
				rootPart.AssemblyLinearVelocity = Vector3.zero
				rootPart.AssemblyAngularVelocity = Vector3.zero
			end
			
			currentVelocity = Vector3.zero
			targetVelocity = Vector3.zero
			
			-- Update mobile button
			if flightButton and stroke and glow and textLabel then
				textLabel.Text = "[ FLY ]"
				stroke.Color = Color3.fromRGB(0, 255, 255) -- NeonCyan
				textLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
				glow.ImageColor3 = Color3.fromRGB(0, 255, 255)
			end
			
			print("🚀 Flight Mode: OFF")
		end
	end
	
	-- Input handling
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		
		if input.KeyCode == Enum.KeyCode.F then
			ToggleFlight()
		elseif isFlying then
			if input.KeyCode == Enum.KeyCode.W then inputs.Forward = true
			elseif input.KeyCode == Enum.KeyCode.S then inputs.Backward = true
			elseif input.KeyCode == Enum.KeyCode.A then inputs.Left = true
			elseif input.KeyCode == Enum.KeyCode.D then inputs.Right = true
			elseif input.KeyCode == Enum.KeyCode.Space then inputs.Up = true
			elseif input.KeyCode == Enum.KeyCode.LeftControl then inputs.Down = true
			elseif input.KeyCode == Enum.KeyCode.LeftShift then inputs.Boost = true
			end
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.W then inputs.Forward = false
		elseif input.KeyCode == Enum.KeyCode.S then inputs.Backward = false
		elseif input.KeyCode == Enum.KeyCode.A then inputs.Left = false
		elseif input.KeyCode == Enum.KeyCode.D then inputs.Right = false
		elseif input.KeyCode == Enum.KeyCode.Space then inputs.Up = false
		elseif input.KeyCode == Enum.KeyCode.LeftControl then inputs.Down = false
		elseif input.KeyCode == Enum.KeyCode.LeftShift then inputs.Boost = false
		end
	end)
	
	-- Flight physics loop
	RunService.RenderStepped:Connect(function(dt)
		if not isFlying then return end
		if not rootPart or not rootPart.Parent then return end
		
		-- Calculate target velocity from inputs
		local inputVector = Vector3.zero
		
		if inputs.Forward then inputVector += camera.CFrame.LookVector end
		if inputs.Backward then inputVector -= camera.CFrame.LookVector end
		if inputs.Right then inputVector += camera.CFrame.RightVector end
		if inputs.Left then inputVector -= camera.CFrame.RightVector end
		if inputs.Up then inputVector += Vector3.new(0, 1, 0) end
		if inputs.Down then inputVector -= Vector3.new(0, 1, 0) end
		
		-- Normalize and apply speed
		if inputVector.Magnitude > 0 then
			inputVector = inputVector.Unit
			local speed = inputs.Boost and (FLIGHT_SPEED * BOOST_MULTIPLIER) or FLIGHT_SPEED
			targetVelocity = inputVector * speed
		else
			targetVelocity = Vector3.zero
		end
		
		-- Smooth acceleration/deceleration
		local rate = targetVelocity.Magnitude > 0 and ACCELERATION or DECELERATION
		currentVelocity = currentVelocity:Lerp(targetVelocity, math.min(dt * rate, 1))
		
		-- Apply velocity
		if bodyVelocity then
			bodyVelocity.Velocity = currentVelocity
		end
		
		-- Rotate to face camera direction
		if bodyGyro then
			bodyGyro.CFrame = camera.CFrame
		end
	end)
	
	-- Create mobile UI button (Cyber style)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FlightUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player:WaitForChild("PlayerGui")
	
	-- Home button (above fly button)
	local homeButton = Instance.new("TextButton")
	homeButton.Name = "HomeButton"
	homeButton.Size = UDim2.fromOffset(120, 60)
	homeButton.Position = UDim2.new(1, -140, 1, -150)
	homeButton.AnchorPoint = Vector2.new(0, 0)
	homeButton.BackgroundColor3 = Color3.fromRGB(5, 10, 15) -- DarkBg
	homeButton.BackgroundTransparency = 0.2
	homeButton.BorderSizePixel = 0
	homeButton.Text = ""
	homeButton.AutoButtonColor = false
	homeButton.Parent = screenGui
	
	local homeCorner = Instance.new("UICorner")
	homeCorner.CornerRadius = UDim.new(0, 8)
	homeCorner.Parent = homeButton
	
	local homeStroke = Instance.new("UIStroke")
	homeStroke.Color = Color3.fromRGB(255, 170, 0) -- NeonOrange
	homeStroke.Thickness = 2.5
	homeStroke.Transparency = 0
	homeStroke.Parent = homeButton
	
	local homeGlow = Instance.new("ImageLabel")
	homeGlow.Size = UDim2.fromScale(1.15, 1.15)
	homeGlow.Position = UDim2.fromScale(0.5, 0.5)
	homeGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	homeGlow.BackgroundTransparency = 1
	homeGlow.Image = "rbxassetid://5028857084"
	homeGlow.ImageColor3 = Color3.fromRGB(255, 170, 0) -- NeonOrange
	homeGlow.ImageTransparency = 0.65
	homeGlow.ZIndex = 0
	homeGlow.Parent = homeButton
	
	local homeTextLabel = Instance.new("TextLabel")
	homeTextLabel.Text = "[ HOME ]"
	homeTextLabel.Size = UDim2.fromScale(1, 1)
	homeTextLabel.BackgroundTransparency = 1
	homeTextLabel.TextColor3 = Color3.fromRGB(255, 170, 0) -- NeonOrange
	homeTextLabel.Font = Enum.Font.Code
	homeTextLabel.TextSize = 16
	homeTextLabel.TextStrokeTransparency = 0.5
	homeTextLabel.ZIndex = 2
	homeTextLabel.Parent = homeButton
	
	-- Home button click handler
	homeButton.MouseButton1Click:Connect(function()
		if rootPart and rootPart.Parent then
			-- Teleport to home planet spawn (0, 3000, 0)
			local HOME_PLANET_HEIGHT = 3000
			rootPart.CFrame = CFrame.new(0, HOME_PLANET_HEIGHT + 50, 0) -- +50 to spawn above ground
			print("🏠 Teleported to Home Planet")
		end
	end)
	
	flightButton = Instance.new("TextButton")
	flightButton.Name = "FlightButton"
	flightButton.Size = UDim2.fromOffset(120, 60)
	flightButton.Position = UDim2.new(1, -140, 1, -80)
	flightButton.AnchorPoint = Vector2.new(0, 0)
	flightButton.BackgroundColor3 = Color3.fromRGB(5, 10, 15) -- DarkBg
	flightButton.BackgroundTransparency = 0.2
	flightButton.BorderSizePixel = 0
	flightButton.Text = ""
	flightButton.AutoButtonColor = false
	flightButton.Parent = screenGui
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = flightButton
	
	-- Add cyber stroke
	stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 255, 255) -- NeonCyan
	stroke.Thickness = 2.5
	stroke.Transparency = 0
	stroke.Parent = flightButton
	
	-- Add glow effect
	glow = Instance.new("ImageLabel")
	glow.Size = UDim2.fromScale(1.15, 1.15)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundTransparency = 1
	glow.Image = "rbxassetid://5028857084"
	glow.ImageColor3 = Color3.fromRGB(0, 255, 255) -- NeonCyan
	glow.ImageTransparency = 0.65
	glow.ZIndex = 0
	glow.Parent = flightButton
	
	-- Add text label with proper formatting like sidebar buttons
	textLabel = Instance.new("TextLabel")
	textLabel.Text = "[ FLY ]"
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.fromRGB(0, 255, 255) -- NeonCyan
	textLabel.Font = Enum.Font.Code
	textLabel.TextSize = 16
	textLabel.TextStrokeTransparency = 0.5
	textLabel.ZIndex = 2
	textLabel.Parent = flightButton
	glow.Image = "rbxassetid://5028857084"
	glow.ImageColor3 = Color3.fromRGB(0, 255, 255) -- NeonCyan
	glow.ImageTransparency = 0.65
	glow.ZIndex = 0
	glow.Parent = flightButton
	
	-- Button click handler
	flightButton.MouseButton1Click:Connect(function()
		ToggleFlight()
	end)
	
	-- Don't auto-enable flight - let player press F when ready
	print("🚀 Space Flight Controller Ready! Press F to toggle flight mode")
	print("Controls: WASD = Move, Space = Up, Ctrl = Down, Shift = Boost")
end

return SpaceFlightController
