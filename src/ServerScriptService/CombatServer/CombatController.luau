local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local M1Event = ReplicatedStorage:WaitForChild("M1Event")
local Audio = ReplicatedStorage.Audio
local Models = ReplicatedStorage.Models

local HitModule = require(ReplicatedStorage.HitModule)
local ProjectileModule = require(ReplicatedStorage.ProjectileModule)
local AnimationController = require(ReplicatedStorage.AnimationController)
local SoundModule = require(ReplicatedStorage.SoundModule)

local CombatController = {}
CombatController.__index = CombatController

function CombatController.new(char:Model)
	local animationController = AnimationController.new(char)
	local projectileModule = ProjectileModule.new(char)
	local self = {
		char = char,
		animationController = animationController,
		projectileModule = projectileModule,
		lastAttack = nil,
		resetTime = 1.5,
		lastMouse = nil,
	}
	
	setmetatable(self, CombatController)

	return self
end

function CombatController:ForceForward()
	M1Event:FireClient(Players:GetPlayerFromCharacter(self.char))
end

function CombatController:TimeStop()
	workspace:SetAttribute("Timestop",true)
	local timestop = {}
	SoundModule.PlaySound(Audio.Timestop,self.char)
	local saturation = Lighting.ColorCorrection.Saturation
	Lighting.ColorCorrection.Saturation = -1
	for _,character in workspace.Alive:GetChildren() do
		if character ~= self.char then
			local root = character:WaitForChild("HumanoidRootPart")
			local bv = Instance.new("BodyPosition")
			bv.Position = root.Position
			bv.P = 5000
			bv.MaxForce = Vector3.new(100000,0,100000)
			bv.Parent = root
			bv.Name = "Timestop"
			table.insert(timestop,bv)
		end
	end
	
	task.delay(2,function()
		for _,character in workspace.Alive:GetChildren() do
			if character ~= self.char then
				character.HumanoidRootPart.Anchored = false
			end
		end
		for _,v in timestop do
			v:Destroy()
		end
		workspace:SetAttribute("Timestop",nil)
		Lighting.ColorCorrection.Saturation = saturation
		task.delay(2,function()
			self.char:SetAttribute("ActionCd",false)
		end)
	end)
end

function CombatController:ComboCancel()
	local combo = self.char:GetAttribute("Combo")
	if self.lastAttack then
		if tick() - self.lastAttack > self.resetTime then
			self.char:SetAttribute("Combo", 1)
			self.lastAttack = tick()
			return
		end
	end
end

function CombatController:ChangeCombo()
	local combo = self.char:GetAttribute("Combo")

	if combo == 4 then
		
		self.char:SetAttribute("M1Cd",true)
		self.char:SetAttribute("Combo", 1)
		task.delay(1,function()
			self.char:SetAttribute("M1Cd",false)
		end)
	else
		self.char:SetAttribute("Combo", combo + 1)
	end	
	
	self.lastAttack = tick()

	
end

function CombatController:Attack()
	self:ComboCancel()
	self.char:SetAttribute("Attacking",true)
	self.animationController:PlayM1()
	self:ForceForward()
	self:ChangeCombo()
end

function CombatController:Action()
	if self.animationController.lastHit == nil then return end
	local canTS = false
	for _,victim in self.animationController.lastHit do
		if not victim:GetAttribute("Freefall") then return end
		
		canTS = true
		local rootPos = self.char:WaitForChild("HumanoidRootPart",1)
		local victimRoot:BasePart = victim:WaitForChild("HumanoidRootPart",1)
		local goal = victimRoot.Position + (rootPos.CFrame.LookVector * (victimRoot.Position-rootPos.Position).Magnitude*1.25) + Vector3.new(0,-(victimRoot.Position.Y-rootPos.Position.Y)-1,0)
		local direction = (goal-victimRoot.Position).Unit
		
		task.delay(0.5,function()
			local caster = self.projectileModule:Fire(direction,victim,goal)
			caster:Pause()
			workspace:GetAttributeChangedSignal("Timestop"):Once(function()
				if not workspace:GetAttribute("Timestop") then
					caster:Resume()
				end
			end)
		end)
	end
	print(canTS)
	if canTS then
		self:TimeStop()
		self.char:SetAttribute("ActionCd",true)
	end
end

function CombatController:CircleOfKnives(mouse:Vector3)
	local r = 5
	local angle = 0
	local root = self.char:WaitForChild("HumanoidRootPart",1)
	local base = root.Position
	local isReady = false
	
	for i = 1,12 do
		local x = base.X + r*math.cos(math.rad(angle))
		local z = base.Z + r*math.sin(math.rad(angle))
		local startPos = Vector3.new(x,base.Y, z)
		local direction = (mouse - startPos).Unit
		
		local caster = self.projectileModule:Fire(direction,startPos)
		local projectile = caster.RayInfo.CosmeticBulletObject
		caster:Pause()
		
		angle += 30
		task.spawn(function()
			while not isReady do
				projectile.CFrame = projectile.CFrame * CFrame.Angles(0,math.rad(10),0)
				task.wait()
			end
			caster:Resume()
		end)
		if i == 12 then
			task.wait(0.25)
		else
			task.wait(0.025)
		end
	end
	isReady = true
end

function CombatController:ReverseCircleOfKnives(mouse:Vector3)
	local r = 5
	local angle = 0
	local root = self.char:WaitForChild("HumanoidRootPart",1)
	local base = root.CFrame 	
	local isReady = false
	

	for i = 1,12 do
		local z = r*math.cos(math.rad(angle))
		local y = r*math.sin(math.rad(angle))
		local startPos = base:PointToWorldSpace(Vector3.new(0,y,z))
		
		local direction = (mouse - startPos).Unit

		local caster = self.projectileModule:Fire(direction,startPos)
		local projectile = caster.RayInfo.CosmeticBulletObject
		caster:Pause()

		angle += 30
		projectile.CFrame = projectile.CFrame * CFrame.Angles(0,0,math.rad(90))
		task.spawn(function()
			while not isReady do
				projectile.CFrame = projectile.CFrame * CFrame.Angles(0,math.rad(10),0)
				task.wait()
			end
			caster:Resume()
		end)
		if i == 12 then
			task.wait(0.25)
		else
			task.wait(0.025)
		end
	end
	isReady = true
end

function CombatController:MouseUpd(mouse:Vector3)
	self.mouse = mouse
end

return CombatController
