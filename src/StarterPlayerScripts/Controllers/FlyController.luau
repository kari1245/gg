local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local FlyController = {}
FlyController.Name = "FlyController"

-- Private State
local _isFlying = false
local _bodyVelocity = nil 
local _bodyGyro = nil  -- Thêm BodyGyro để giữ hướng
local _baseSpeed = 2000 
local _boostSpeed = 4000 
local _camera = workspace.CurrentCamera

-- Mobile Controls
local _mobileGui = nil
local _flyButton = nil
local _joystick = nil
local _joystickCenter = nil
local _joystickKnob = nil
local _touchingJoystick = false
local _joystickInput = Vector2.zero

function FlyController:CreateMobileUI()
	if not UserInputService.TouchEnabled then return end
	
	-- Tạo ScreenGui
	_mobileGui = Instance.new("ScreenGui")
	_mobileGui.Name = "FlyMobileGui"
	_mobileGui.ResetOnSpawn = false
	_mobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Nút Fly (góc phải)
	_flyButton = Instance.new("TextButton")
	_flyButton.Name = "FlyButton"
	_flyButton.Size = UDim2.new(0, 70, 0, 70)
	_flyButton.Position = UDim2.new(1, -85, 1, -85)
	_flyButton.AnchorPoint = Vector2.new(0, 0)
	_flyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	_flyButton.BackgroundTransparency = 0.3
	_flyButton.Text = "✈️"
	_flyButton.TextSize = 32
	_flyButton.TextColor3 = Color3.new(1, 1, 1)
	_flyButton.Parent = _mobileGui
	
	local flyCorner = Instance.new("UICorner")
	flyCorner.CornerRadius = UDim.new(0.5, 0)
	flyCorner.Parent = _flyButton
	
	_flyButton.MouseButton1Click:Connect(function()
		self:Toggle()
		if _isFlying then
			_flyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		else
			_flyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		end
	end)
	
	-- Joystick (góc trái)
	_joystick = Instance.new("Frame")
	_joystick.Name = "Joystick"
	_joystick.Size = UDim2.new(0, 150, 0, 150)
	_joystick.Position = UDim2.new(0, 30, 1, -180)
	_joystick.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	_joystick.BackgroundTransparency = 0.5
	_joystick.Parent = _mobileGui
	
	local joystickCorner = Instance.new("UICorner")
	joystickCorner.CornerRadius = UDim.new(0.5, 0)
	joystickCorner.Parent = _joystick
	
	_joystickKnob = Instance.new("Frame")
	_joystickKnob.Name = "Knob"
	_joystickKnob.Size = UDim2.new(0, 60, 0, 60)
	_joystickKnob.Position = UDim2.new(0.5, 0, 0.5, 0)
	_joystickKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	_joystickKnob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	_joystickKnob.BackgroundTransparency = 0.3
	_joystickKnob.Parent = _joystick
	
	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(0.5, 0)
	knobCorner.Parent = _joystickKnob
	
	_joystickCenter = _joystick.AbsolutePosition + (_joystick.AbsoluteSize / 2)
	
	-- Nút lên/xuống
	local upButton = Instance.new("TextButton")
	upButton.Name = "UpButton"
	upButton.Size = UDim2.new(0, 60, 0, 60)
	upButton.Position = UDim2.new(0, 200, 1, -250)
	upButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	upButton.BackgroundTransparency = 0.3
	upButton.Text = "↑"
	upButton.TextSize = 28
	upButton.TextColor3 = Color3.new(1, 1, 1)
	upButton.Parent = _mobileGui
	
	local upCorner = Instance.new("UICorner")
	upCorner.CornerRadius = UDim.new(0.3, 0)
	upCorner.Parent = upButton
	
	local downButton = Instance.new("TextButton")
	downButton.Name = "DownButton"
	downButton.Size = UDim2.new(0, 60, 0, 60)
	downButton.Position = UDim2.new(0, 200, 1, -180)
	downButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	downButton.BackgroundTransparency = 0.3
	downButton.Text = "↓"
	downButton.TextSize = 28
	downButton.TextColor3 = Color3.new(1, 1, 1)
	downButton.Parent = _mobileGui
	
	local downCorner = Instance.new("UICorner")
	downCorner.CornerRadius = UDim.new(0.3, 0)
	downCorner.Parent = downButton
	
	-- Xử lý joystick input
	local function updateJoystick(input)
		_joystickCenter = _joystick.AbsolutePosition + (_joystick.AbsoluteSize / 2)
		local delta = Vector2.new(input.Position.X, input.Position.Y) - _joystickCenter
		local distance = math.min(delta.Magnitude, 45)
		local direction = delta.Unit
		
		if delta.Magnitude > 0 then
			_joystickKnob.Position = UDim2.new(0.5, direction.X * distance, 0.5, direction.Y * distance)
			_joystickInput = direction * (distance / 45)
		else
			_joystickKnob.Position = UDim2.new(0.5, 0, 0.5, 0)
			_joystickInput = Vector2.zero
		end
	end
	
	UserInputService.TouchStarted:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		local inputPos = Vector2.new(input.Position.X, input.Position.Y)
		_joystickCenter = _joystick.AbsolutePosition + (_joystick.AbsoluteSize / 2)
		
		if (inputPos - _joystickCenter).Magnitude <= 75 then
			_touchingJoystick = true
			updateJoystick(input)
		end
	end)
	
	UserInputService.TouchMoved:Connect(function(input, gameProcessed)
		if _touchingJoystick then
			updateJoystick(input)
		end
	end)
	
	UserInputService.TouchEnded:Connect(function(input, gameProcessed)
		_touchingJoystick = false
		_joystickKnob.Position = UDim2.new(0.5, 0, 0.5, 0)
		_joystickInput = Vector2.zero
	end)
	
	-- Lưu state của nút
	_mobileGui:SetAttribute("UpTouching", false)
	_mobileGui:SetAttribute("DownTouching", false)
	
	upButton.MouseButton1Down:Connect(function() _mobileGui:SetAttribute("UpTouching", true) end)
	upButton.MouseButton1Up:Connect(function() _mobileGui:SetAttribute("UpTouching", false) end)
	downButton.MouseButton1Down:Connect(function() _mobileGui:SetAttribute("DownTouching", true) end)
	downButton.MouseButton1Up:Connect(function() _mobileGui:SetAttribute("DownTouching", false) end)
	
	_mobileGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function FlyController:Start()
	print("[FlyController] Started")
	
	-- Tạo UI cho mobile
	self:CreateMobileUI()
	
	-- PC Controls
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.F then
			self:Toggle()
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		self:OnRenderStep(dt)
	end)
end

function FlyController:Toggle()
	_isFlying = not _isFlying
	
	local player = Players.LocalPlayer
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid") :: Humanoid
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart
	
	if _isFlying then
		if hum then 
			hum.PlatformStand = true 
			hum:ChangeState(Enum.HumanoidStateType.Physics) 
		end
		
		-- Tạo Attachment
		local att = Instance.new("Attachment")
		att.Name = "FlyAttachment"
		att.Parent = root
		
		-- LinearVelocity để di chuyển
		local lv = Instance.new("LinearVelocity")
		lv.Name = "FlyVelocity"
		lv.Attachment0 = att
		lv.MaxForce = math.huge 
		lv.VectorVelocity = Vector3.zero
		lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.Parent = root
		
		-- AlignOrientation để giữ hướng nhân vật
		local ao = Instance.new("AlignOrientation")
		ao.Name = "FlyOrientation"
		ao.Attachment0 = att
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.MaxTorque = 10000
		ao.Responsiveness = 200
		ao.RigidityEnabled = true
		ao.Parent = root
		
		_bodyVelocity = {VelocityInstance = lv, Attachment = att, Orientation = ao}
		print("✈️ Super Flight: ON")
	else
		if hum then 
			hum.PlatformStand = false 
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		
		if _bodyVelocity then
			if _bodyVelocity.VelocityInstance then _bodyVelocity.VelocityInstance:Destroy() end
			if _bodyVelocity.Orientation then _bodyVelocity.Orientation:Destroy() end
			if _bodyVelocity.Attachment then _bodyVelocity.Attachment:Destroy() end
			_bodyVelocity = nil
		end
		if root then 
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
		print("✈️ Super Flight: OFF")
	end
end

function FlyController:OnRenderStep(dt: number)
	if _isFlying and _bodyVelocity and _bodyVelocity.VelocityInstance then
		local moveVec = Vector3.zero
		local currentSpeed = _baseSpeed
		
		local camCF = _camera.CFrame
		local root = Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		
		-- PC Controls
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			currentSpeed = _boostSpeed
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveVec += camCF.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveVec -= camCF.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveVec -= camCF.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveVec += camCF.RightVector
		end
		
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			moveVec += Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			moveVec -= Vector3.new(0, 1, 0)
		end
		
		-- Mobile Controls
		if _joystickInput.Magnitude > 0 then
			local forward = camCF.LookVector * _joystickInput.Y
			local right = camCF.RightVector * _joystickInput.X
			moveVec += (forward + right)
		end
		
		if _mobileGui then
			if _mobileGui:GetAttribute("UpTouching") then
				moveVec += Vector3.new(0, 1, 0)
			end
			if _mobileGui:GetAttribute("DownTouching") then
				moveVec -= Vector3.new(0, 1, 0)
			end
		end
		
		if moveVec.Magnitude > 0 then
			moveVec = moveVec.Unit * currentSpeed
		end
		
		_bodyVelocity.VelocityInstance.VectorVelocity = moveVec
		
		-- Giữ hướng nhân vật theo camera (chỉ trục Y)
		if root and _bodyVelocity.Orientation then
			local cameraCFrame = _camera.CFrame
			-- Tạo CFrame chỉ xoay theo trục Y (ngang), không xoay theo trục X (lên xuống)
			local lookVector = cameraCFrame.LookVector
			local flatLookVector = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
			local targetCFrame = CFrame.lookAt(root.Position, root.Position + flatLookVector)
			
			_bodyVelocity.Orientation.CFrame = targetCFrame
		end
	end
end

return FlyController