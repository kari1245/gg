local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local FlyController = {}
FlyController.Name = "FlyController"

-- Private State
local _isFlying = false
local _bodyVelocity = nil 
local _baseSpeed = 2000 
local _boostSpeed = 4000 
local _camera = workspace.CurrentCamera

function FlyController:Start()
	print("[FlyController] Started")
	
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
		
		local att = Instance.new("Attachment")
		att.Name = "FlyAttachment"
		att.Parent = root
		
		local lv = Instance.new("LinearVelocity")
		lv.Name = "FlyVelocity"
		lv.Attachment0 = att
		lv.MaxForce = math.huge 
		lv.VectorVelocity = Vector3.zero
		lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.Parent = root
		
		_bodyVelocity = {VelocityInstance = lv, Attachment = att}
		print("✈️ Super Flight: ON")
	else
		if hum then 
			hum.PlatformStand = false 
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		
		if _bodyVelocity then
			if _bodyVelocity.VelocityInstance then _bodyVelocity.VelocityInstance:Destroy() end
			if _bodyVelocity.Attachment then _bodyVelocity.Attachment:Destroy() end
			_bodyVelocity = nil
		end
		if root then root.AssemblyLinearVelocity = Vector3.zero end
		print("✈️ Super Flight: OFF")
	end
end

function FlyController:OnRenderStep(dt: number)
	if _isFlying and _bodyVelocity and _bodyVelocity.VelocityInstance then
		local moveVec = Vector3.zero
		local currentSpeed = _baseSpeed
		
		local camCF = _camera.CFrame
		
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
		
		if moveVec.Magnitude > 0 then
			moveVec = moveVec.Unit * currentSpeed
		end
		
		_bodyVelocity.VelocityInstance.VectorVelocity = moveVec
	end
end

return FlyController