--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local FlyController = Knit.CreateController { Name = "FlyController" }

-- Configuration
local NORMAL_SPEED = 100
local FAST_SPEED = 400

-- State
local _isFlying = false
local _speed = NORMAL_SPEED
local _moveKeys = {}
local _bodyVelocity: BodyVelocity? = nil

local KEY_MAP = {
	[Enum.KeyCode.W] = Vector3.new(0, 0, 1),
	[Enum.KeyCode.S] = Vector3.new(0, 0, -1),
	[Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
	[Enum.KeyCode.D] = Vector3.new(1, 0, 0),
	[Enum.KeyCode.Space] = Vector3.new(0, 1, 0),
	[Enum.KeyCode.LeftControl] = Vector3.new(0, -1, 0),
}

function FlyController:KnitStart()
    print("[FlyController] Started. Press F to fly.")
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if KEY_MAP[input.KeyCode] then
            _moveKeys[input.KeyCode] = KEY_MAP[input.KeyCode]
        elseif input.KeyCode == Enum.KeyCode.F then
            self:ToggleFlight()
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            _speed = FAST_SPEED
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if KEY_MAP[input.KeyCode] then
            _moveKeys[input.KeyCode] = nil
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            _speed = NORMAL_SPEED
        end
    end)
    
    RunService.RenderStepped:Connect(function(dt)
        self:OnRenderStep(dt)
    end)
end

function FlyController:ToggleFlight()
    _isFlying = not _isFlying
    local player = Players.LocalPlayer
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid") :: Humanoid
    local root = char:FindFirstChild("HumanoidRootPart") :: BasePart
    
    if _isFlying then
        if hum then hum.PlatformStand = true end
        if not _bodyVelocity then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bv.P = 5000
            bv.Velocity = Vector3.new()
            bv.Parent = root
            _bodyVelocity = bv
        end
    else
        if hum then hum.PlatformStand = false end
        if _bodyVelocity then
            _bodyVelocity:Destroy()
            _bodyVelocity = nil
        end
        if root then root.AssemblyLinearVelocity = Vector3.new() end
    end
end

function FlyController:OnRenderStep(dt: number)
    if _isFlying and _bodyVelocity then
        local direction = Vector3.new()
        for _, vec in pairs(_moveKeys) do
            direction += vec
        end
        if direction.Magnitude > 0 then direction = direction.Unit end
        
        local camera = workspace.CurrentCamera
        local moveVec = Vector3.new()
        
        if direction.Magnitude > 0 then
			local camCF = camera.CFrame
			local forward = camCF.LookVector * direction.Z
			local right = camCF.RightVector * direction.X
			local up = camCF.UpVector * direction.Y
			moveVec = (forward + right + up)
			if moveVec.Magnitude > 0 then
				moveVec = moveVec.Unit
			end
		end
        
        local targetVel = moveVec * _speed
		_bodyVelocity.Velocity = _bodyVelocity.Velocity:Lerp(targetVel, math.clamp(dt*10,0,1))
    end
end

return FlyController