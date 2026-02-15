local UserInputService = game:GetService("UserInputService")
local BuildService = game:GetService("Players")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

local flying = false
local speed = 100
local lastJumpTime = 0
local jumpCount = 0

local bodyGyro = nil
local bodyVelocity = nil

local function startFlight()
	if flying then return end
	flying = true
	
	-- Create Physics
	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.P = 9e4
	bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
	bodyGyro.cframe = RootPart.CFrame
	bodyGyro.Parent = RootPart

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.velocity = Vector3.new(0, 0, 0)
	bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
	bodyVelocity.Parent = RootPart

	Humanoid.PlatformStand = true
end

local function stopFlight()
	if not flying then return end
	flying = false
	
	if bodyGyro then bodyGyro:Destroy() end
	if bodyVelocity then bodyVelocity:Destroy() end
	
	if Humanoid then
		Humanoid.PlatformStand = false
        Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function onUpdate()
	if not flying or not RootPart then return end
	
	local look = Camera.CFrame.LookVector
	bodyGyro.cframe = Camera.CFrame
	bodyVelocity.velocity = look * speed
end

UserInputService.JumpRequest:Connect(function()
    local now = tick()
    if now - lastJumpTime < 0.4 then
        -- Double Jump
        if flying then
            stopFlight()
        else
            startFlight()
        end
        lastJumpTime = 0 -- Reset
    else
        lastJumpTime = now
    end
end)

RunService:BindToRenderStep("FlyStep", Enum.RenderPriority.Character.Value, onUpdate)

Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
    stopFlight()
end)
