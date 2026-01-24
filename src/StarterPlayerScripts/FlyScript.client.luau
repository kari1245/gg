-- FlyScript: Temporary script to let the player fly
-- Place this in StarterPlayerScripts for local testing

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

local flying = false
local normalSpeed = 100
local fastSpeed = 400
local speed = normalSpeed
local direction = Vector3.new()

-- Key mapping (W = tiến, S = lùi)
local keyMap = {
	[Enum.KeyCode.W] = Vector3.new(0, 0, 1),
	[Enum.KeyCode.S] = Vector3.new(0, 0, -1),
	[Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
	[Enum.KeyCode.D] = Vector3.new(1, 0, 0),
	[Enum.KeyCode.Space] = Vector3.new(0, 1, 0),
	[Enum.KeyCode.LeftControl] = Vector3.new(0, -1, 0),
}

local bodyVelocity = nil

local moveKeys = {}

local function updateDirection()
	direction = Vector3.new()
	for key, vec in pairs(moveKeys) do
		direction = direction + vec
	end
	if direction.Magnitude > 0 then
		direction = direction.Unit
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if keyMap[input.KeyCode] then
		moveKeys[input.KeyCode] = keyMap[input.KeyCode]
		updateDirection()
	elseif input.KeyCode == Enum.KeyCode.F then
		flying = not flying
		if flying then
			humanoid.PlatformStand = true
			if not bodyVelocity then
				bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
				bodyVelocity.P = 5000
				bodyVelocity.Velocity = Vector3.new()
				bodyVelocity.Parent = humanoidRootPart
			end
		else
			humanoid.PlatformStand = false
			if bodyVelocity then
				bodyVelocity:Destroy()
				bodyVelocity = nil
			end
			humanoidRootPart.AssemblyLinearVelocity = Vector3.new()
		end
	elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		speed = fastSpeed
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if keyMap[input.KeyCode] then
		moveKeys[input.KeyCode] = nil
		updateDirection()
	elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		speed = normalSpeed
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if flying and bodyVelocity then
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
		local targetVel = moveVec * speed
		bodyVelocity.Velocity = bodyVelocity.Velocity:Lerp(targetVel, math.clamp(dt*10,0,1))
	end
end)

print("[FlyScript] Press F to toggle fly mode. Use WASD, Space, Ctrl to move.")
