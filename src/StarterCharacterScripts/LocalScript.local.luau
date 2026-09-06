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
local runSnd:Sound = root:WaitForChild("Running")

local runAnim = animator:LoadAnimation(ReplicatedStorage.Animations.RunAnim)
runAnim.Priority = Enum.AnimationPriority.Action

local lastTap,timeLimit = 0,2
local runKey = Enum.KeyCode.LeftShift
local info = TweenInfo.new(0.25,Enum.EasingStyle.Linear)
local parametrs = {
	topSpeed = 35,
	minSpeed = 22,
	volumeTop = 0.9,
	volumeMinRun = 0.75,
	volumeMin = 0.65,
	playbackTop = 2.25;
	playbackMin = 1.85
}
local function Lerp(n,m,x)
	return n + (m - n) * x
end

local function Run()
	
	if humanoid.WalkSpeed < parametrs.topSpeed and tick()-lastTap < timeLimit then
		humanoid.WalkSpeed = Lerp(humanoid.WalkSpeed,parametrs.topSpeed,0.1)
		runSnd.Volume = parametrs.volumeTop
		runSnd.PlaybackSpeed = Lerp(runSnd.PlaybackSpeed,parametrs.playbackTop,0.1)
	else
		humanoid.WalkSpeed = Lerp(humanoid.WalkSpeed,parametrs.minSpeed,0.025)
		runSnd.Volume = parametrs.volumeMinRun
		runSnd.PlaybackSpeed = Lerp(runSnd.PlaybackSpeed,parametrs.playbackMin,0.1)
	end
end

local function StopRun()
	humanoid.WalkSpeed = 16
	runSnd.Volume = parametrs.volumeMin
	runSnd.PlaybackSpeed = parametrs.playbackMin
	Tween:Create(camera,info,{FieldOfView = 70}):Play()
	runAnim:Stop()
	char:SetAttribute("Running",false)
end

local function CheckIfStopped()
	local moveVelocity = humanoid:GetMoveVelocity()
	local relativeVelocity = root.CFrame:VectorToObjectSpace(moveVelocity)
	if relativeVelocity.Z > 0.5 then
		runAnim:AdjustSpeed(-1)
	end
	
	if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		runAnim:AdjustSpeed(0.45)
	elseif relativeVelocity.Z < 0.5 then
		runAnim:AdjustSpeed(humanoid.WalkSpeed/24)
	end	
	
	if char:GetAttribute("Running") and not runAnim.IsPlaying then
		runAnim:Play()
		lastTap = tick()
	end
end	



RunService.Heartbeat:Connect(function(delta)
	local key = UIS:IsKeyDown(runKey)
	local magnitude = humanoid.MoveDirection.Magnitude
	local shouldRun = key == true 
	local isAttacking = char:GetAttribute("Attacking")
	
	if isAttacking and char:GetAttribute("Running") then
		StopRun()
	end
	
	if isAttacking then return end
	
	if shouldRun and not char:GetAttribute("Running") and not isAttacking and magnitude > 0 then
		Run()
		lastTap = tick()
		Tween:Create(camera,info,{FieldOfView = 80}):Play()
		runAnim:Play()
		char:SetAttribute("Running",true)
	elseif 	char:GetAttribute("Running") and not isAttacking and magnitude > 0 then
		Run()
	elseif magnitude == 0 and char:GetAttribute("Running")  then
		StopRun()
	end

	if char:GetAttribute("Running") then CheckIfStopped() end
	if char:GetAttribute("InDash") then runSnd.Volume = 0
	elseif runSnd.Volume == 0 and not char:GetAttribute("InDash") then
		runSnd.Volume = parametrs.volumeMin
	end
end)