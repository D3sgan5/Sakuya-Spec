local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")


if script.Parent == StarterPlayer.StarterCharacterScripts then return end

local camera = workspace.CurrentCamera
local plr = Players.LocalPlayer
local char = script.Parent
local root = char:WaitForChild("HumanoidRootPart")
local humanoid:Humanoid = char:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")
local lastKey = Enum.KeyCode.A
local timeBetween = 0
local timeLimit = 0.3

local animFolder = ReplicatedStorage.Animations.Dashes:GetChildren()
local animMass = {}
for _, anim in pairs(animFolder) do
	animMass[anim.Name] = anim
end

local dashes = {
	['Forward'] = animator:LoadAnimation(animMass["Forward"]),
	['Backward'] = animator:LoadAnimation(animMass["Backward"]),
	['Left'] = animator:LoadAnimation(animMass["Left"]),
	['Right'] = animator:LoadAnimation(animMass["Right"]),
}

for _, track:AnimationTrack in dashes do
	track.Priority = Enum.AnimationPriority.Action2
end

local wayToGo = {
	['Forward'] = 1,
	['Backward'] = -1,
	['Left'] = -1,
	['Right'] = 1,
}
local keys = {
	["W"] = Enum.KeyCode.W,
	["S"] =Enum.KeyCode.S,
	["A"] =Enum.KeyCode.A,
	["D"] =Enum.KeyCode.D,
}

local function GetDashDirection(keycode:Enum.KeyCode)
	local moveVelocity = humanoid:GetMoveVelocity()
	local relativeVelocity = root.CFrame:VectorToObjectSpace(moveVelocity)
	local speed = humanoid.WalkSpeed
	
	if keycode == keys["W"] then
		return 'Forward'
	elseif keycode == keys["S"] then
		return 'Backward'
	elseif keycode == keys["D"] then
		return 'Right'
	elseif keycode == keys["A"] then
		return 'Left'
	elseif moveVelocity.Magnitude == 0 then
		return 'Forward'
	end
	
end
local function StopAnims()
	for _, track:AnimationTrack in pairs(animator:GetPlayingAnimationTracks()) do
		track:Stop()
	end
end

local function Dash(keycode)
	StopAnims()
	local dashDirection = GetDashDirection(keycode)
	local track:AnimationTrack = dashes[dashDirection]
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Parent = root
	bodyVelocity.MaxForce = Vector3.new(100000,100000,100000)
	local power = 200
	local speed = humanoid.WalkSpeed
	humanoid.WalkSpeed = 0
	
	
	if dashDirection == "Forward" or dashDirection == "Backward" then
		bodyVelocity.Velocity = root.CFrame.LookVector * power * wayToGo[dashDirection]
	else
		bodyVelocity.Velocity = root.CFrame.RightVector * power * wayToGo[dashDirection]
	end
	
	track:Play()
	track:AdjustSpeed(2)
	local tw = Tween:Create(bodyVelocity,TweenInfo.new(track.Length+0.1,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Velocity = Vector3.new(0,0,0)})
	tw:Play()
	track.Stopped:Once(function()
		tw:Cancel()
		bodyVelocity:Destroy()
		char:SetAttribute("InDash",nil)
		humanoid.WalkSpeed = speed
		char:SetAttribute("Running",true)
	end)
end

UIS.InputBegan:Connect(function(input)
	local inDash = char:GetAttribute("InDash")
	if keys[input.KeyCode.Name] and not inDash then
		if input.KeyCode == lastKey and tick()-timeBetween < timeLimit then
			char:SetAttribute("InDash",true)
			Dash(input.KeyCode)
		else
			lastKey = input.KeyCode
			timeBetween = tick()
		end
	end
end)
	