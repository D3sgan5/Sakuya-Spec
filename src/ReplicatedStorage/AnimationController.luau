local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local hitboxModule = require(ReplicatedStorage.HitboxClass)
local hitboxTypes = require(ReplicatedStorage.HitboxClass.Types)
local hitModule = require(ReplicatedStorage.HitModule)
local soundModule = require(ReplicatedStorage.SoundModule)

local Animations = ReplicatedStorage.Animations
local Audio = ReplicatedStorage:WaitForChild("Audio")
local Effects = ReplicatedStorage:WaitForChild("Effects")


local AnimationController = {}
AnimationController.__index = AnimationController

function AnimationController.new(char)
	local self = {
		loadedAnimations = false,
		char = char,
		humanoid = char:FindFirstChild("Humanoid"),
		tracks = {},
		lastHit = nil,
		connection = nil
	}
	
	setmetatable(self, AnimationController)
	
	self:LoadAnimation()
	
	return self
end

function AnimationController:LoadAnimation()
	if self.loadedAnimations then
		return
	end
	self.loadedAnimations = true
	
	local combatFolder = Animations:FindFirstChild("Combat")
	local animator = self.humanoid:FindFirstChild("Animator")

	for _, object in combatFolder:GetChildren() do
		if object:IsA("Animation") then
			self.tracks[object.Name] = self.humanoid:LoadAnimation(object)
		else
			for _, animation in object:GetChildren() do
				if animation:IsA("Animation") then
					self.tracks[animation.Name] = self.humanoid:LoadAnimation(animation)
				end
			end
		end
	end
	
	self:SetupM1()
end

function AnimationController:SetupM1()
	local hitboxParams:hitboxTypes.HitboxParams = {
		SizeOrPart = 5,
		Blacklist = {self.char},
		DebounceTime = 5,
		Debug = false,
		Debris = 0.25,

	}

	
	for x = 1,4 do
		local anim:AnimationTrack = self.tracks[`M{x}`]
		anim.Priority = Enum.AnimationPriority.Action2
		
		anim:GetMarkerReachedSignal("swingreg"):Connect(function()
			local swingSnd = Audio.Swing
			local root = self.char.HumanoidRootPart
			if x == 4 then
				self:SetVFX(0.25)
				soundModule.PlaySound(swingSnd.SwingSnd2,root,true)
			else
				self:SetVFXAnim()
				soundModule.PlaySound(swingSnd.SwingSnd1,root,true)
			end
			
			local newHitbox, connected = hitboxModule.new(hitboxParams)
			newHitbox:WeldTo(self.char.HumanoidRootPart, CFrame.new(0,0,-1))
			
			newHitbox.HitSomeone:Connect(function(hitChars)
				self.lastHit = hitChars
				if x == 4 then
					hitModule.onHit(hitChars,self.char,true)
				else
					hitModule.onHit(hitChars,self.char,false)
				end
			end)
			
			newHitbox:Start()
			self.char:SetAttribute("Attacking",false)
		end)
	end
end

function AnimationController:SetVFXAnim()
	local vfx = Effects.SlashAnim.Main:Clone()
	local root = self.char.HumanoidRootPart
	local combo = self.char:GetAttribute("Combo")
	local angle = CFrame.Angles(0,-math.pi/2,0) * CFrame.Angles(math.rad(65),0,0)
	
	if combo%2 == 0 then
		angle = CFrame.Angles(0,-math.pi/2,0) * CFrame.Angles(math.rad(-65),0,0)
	end
	vfx.CFrame =  angle
	vfx.Parent = root
	for _, effect in vfx:GetChildren() do
		effect:Emit(1)
	end
	
	game:GetService("Debris"):AddItem(vfx,1)
end

function AnimationController:SetVFX(lenght:number)
	local vfx = Effects.Slash:Clone()
	local root = self.char.HumanoidRootPart
	local combo = self.char:GetAttribute("Combo")
	local angle
	if combo%2 ~= 0 then
		if combo == 1 then
			angle = CFrame.Angles(math.rad(15),math.rad(-25),0)
		else
			angle = CFrame.Angles(0,math.rad(-45),0)
		end
	else
		angle = CFrame.Angles(0,math.rad(45),math.rad(180))
	end
	vfx.Parent = root
	vfx.CFrame = root.CFrame * CFrame.new(0,1,-1) * angle
	vfx.Massless = true
	if combo == 1 then
		vfx.Mesh.VertexColor = Vector3.new(0,0,255)
	else
		vfx.Mesh.VertexColor = Vector3.new(255,0,0)
	end
	vfx.Transparency = 1
	local weld = Instance.new("WeldConstraint")
	weld.Parent = vfx
	weld.Part0 = root
	weld.Part1 = vfx
	
	game.Debris:AddItem(vfx,lenght)
	local tween = TweenService:Create(vfx,TweenInfo.new(lenght/2),{Transparency = 0.11})
	
	tween:Play()
	tween.Completed:Wait()
	TweenService:Create(vfx,TweenInfo.new(lenght/2),{Transparency = 1}):Play()
end

function AnimationController:StopAnimations()
	local animator:Animator = self.humanoid:FindFirstChild("Animator")
	for _, track in animator:GetPlayingAnimationTracks() do
		track:Stop()
	end
end

function AnimationController:PlayM1()
	local combo = self.char:GetAttribute("Combo")
	local anim = self.tracks[`M{combo}`]
	self:StopAnimations()
	anim:Play()
end

return AnimationController
