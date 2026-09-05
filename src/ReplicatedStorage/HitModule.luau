local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local M1Event = ReplicatedStorage:WaitForChild("M1Event")

local animFolder = ReplicatedStorage.Animations
local audio = ReplicatedStorage.Audio
local effects = ReplicatedStorage.Effects

local KnockbackModule = require(script.Parent:WaitForChild("KnockbackModule"))
local SoundModule = require(ReplicatedStorage.SoundModule)

local HitModule = {}

local knockTable = {}
local ForceTable = {}

function HitModule.ForceForward(victim,attacker)
	local root = attacker:WaitForChild("HumanoidRootPart")
	local bv = Instance.new("BodyPosition")
	bv.Position = (attacker.HumanoidRootPart.CFrame * CFrame.new(0,0,-12)).Position
	bv.P = 5000
	bv.MaxForce = Vector3.new(100000,0,100000)
	bv.Parent = victim.HumanoidRootPart
	game.Debris:AddItem(bv,0.5)
	if not knockTable[victim] then
		knockTable[victim] = {}
	else
		table.insert(knockTable[victim],bv)
	end
end

function HitModule.lerp(a,b,c)
	return (a + (b - a)) * c
end

function HitModule.ApplyKnockback(victim:Model,attacker:Model,position:Vector3)
	if not ForceTable[victim] then
		ForceTable[victim] = KnockbackModule.new(1,Vector3.new(0,0,0),workspace.Map:GetChildren(),2,1,0.4,20,false,victim)
	end
	HitModule.ClearForce(victim)
	local player = Players:GetPlayerFromCharacter(victim)
	local humanoid:Humanoid = victim:FindFirstChild("Humanoid")
	local hitSnd = audio.KnockbackSnd
	
	local root = victim:WaitForChild("HumanoidRootPart")
	local attackerRoot = attacker:WaitForChild("HumanoidRootPart")
	local rootJoint = root:WaitForChild("RootJoint")
	local goal,start
	local force = 6
	if position then
		force = 30
		ForceTable[victim]:ChangeGravity(0)
	else
		ForceTable[victim]:ChangeGravity(1)
	end
	
	if not position then
		goal = attacker.HumanoidRootPart.CFrame * CFrame.new(0,7,-10) .Position
		start = attacker.HumanoidRootPart.CFrame * CFrame.new(0,0,-2)
	else
		goal = position
		start = root.CFrame * CFrame.new(0,0,-2)

	end
	local direction = attackerRoot.CFrame.LookVector
	local normalizedDirection = Vector3.new(direction.X,0,direction.Z).Unit
	
	local alignOr = CFrame.new(attackerRoot.Position,attackerRoot.Position+normalizedDirection) * CFrame.Angles(math.rad(90), 0, math.rad(-180))
	if not player then
		root:SetNetworkOwner(nil)
		humanoid.PlatformStand = true
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		SoundModule.PlaySound(hitSnd,root,true)
		ForceTable[victim]:Fire(start.Position,goal,force,root,alignOr)
	end
	
end

function HitModule.StopAnims(animator:Animator)
	for _,track in animator:GetPlayingAnimationTracks() do
		track:Stop()
	end
end

function HitModule.PlayStuff(victim:Model)
	local root:BasePart = victim:FindFirstChild("HumanoidRootPart")
	local humanoid:Humanoid = victim:FindFirstChild("Humanoid")
	local animator:Animator = humanoid:FindFirstChild("Animator")
	local animFolder = animFolder.Combat.Hitted:GetChildren()
	local anim = animator:LoadAnimation(animFolder[math.random(1,#animFolder)])
	local hitSnd = audio.HitSnd
	
	HitModule.StopAnims(animator)
	SoundModule.PlaySound(hitSnd,root,false)
	anim:Play()
end

function HitModule.HitEffects(victim:Model)
	local vfx = effects.SlashImpact.Main:Clone()
	local root = victim:FindFirstChild("HumanoidRootPart")
	vfx.Parent = root
	for _,vfx in vfx:GetChildren() do
		vfx:Emit(1)
	end
	game:GetService("Debris"):AddItem(vfx,0.5)
	
	--for _, part in victim:GetChildren() do
	--	if part:IsA("BasePart") then
	--		local weld = Instance.new("WeldConstraint")
	--		local clone = part:Clone()
	--		clone:ClearAllChildren()
	--		clone.Material = Enum.Material.Neon
	--		clone.CanCollide = false
	--		clone.Massless = true
	--		clone.Color = Color3.fromRGB(255, 0, 0)
	--		clone.Transparency = 0.8
	--		clone.Parent = part
	--		weld.Parent = clone
	--		weld.Part0 = part
	--		weld.Part1 = clone
			
	--		if part.Name ~= "Head" then
	--			TweenService:Create(clone,TweenInfo.new(0.3),{Size = clone.Size * 1.25}):Play()
	--		end
	--		TweenService:Create(clone,TweenInfo.new(0.3),{Transparency = 1}):Play()
	--		game.Debris:AddItem(clone,0.3)
			
	--	end
	--end
end

function HitModule.ClearForce(victim)
	if not knockTable[victim] then return end
	for _,bv in knockTable[victim] do
		bv:Destroy()
	end
end

function HitModule.onHit(hitChars,attacker:Model,knockback,goal)
	
	for _, char in hitChars do
		if not knockback then
			HitModule.ForceForward(char,attacker)
			HitModule.PlayStuff(char)
			HitModule.HitEffects(char)
		else
			task.spawn(function()
				HitModule.ApplyKnockback(char,attacker,goal)
			end)
		end
	end
end

return HitModule
