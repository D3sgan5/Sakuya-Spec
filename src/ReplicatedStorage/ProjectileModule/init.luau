local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local M1Event = ReplicatedStorage:WaitForChild("M1Event")
local Audio = ReplicatedStorage.Audio
local Models = ReplicatedStorage.Models

local FastCast = require(ReplicatedStorage.FastCastRedux)
local HitModule = require(ReplicatedStorage.HitModule)
local table = require(ReplicatedStorage.FastCastRedux.Table)
local PartCacheModule = require(ReplicatedStorage.PartCache)
local SoundModule = require(ReplicatedStorage.SoundModule)
local Constants = require(script.Constants)

local RNG = Random.new()		
local TAU = math.pi * 2							
FastCast.DebugLogging = Constants.DEBUG
FastCast.VisualizeCasts = Constants.DEBUG

local CosmeticBulletsFolder = workspace:FindFirstChild("Projectiles")
local CosmeticBullet = Models:WaitForChild("Knife") 

local function Reflect(surfaceNormal, bulletNormal)
	return bulletNormal - (2 * bulletNormal:Dot(surfaceNormal) * surfaceNormal)
end

function CanRayPierce(cast, rayResult, segmentVelocity)
	return false
end

local ProjectileModule = {}
ProjectileModule.__index = ProjectileModule

function ProjectileModule.new(char:Model)
	local Caster = FastCast.new()
	local CastParams = RaycastParams.new()
	CastParams.IgnoreWater = true
	CastParams.FilterType = Enum.RaycastFilterType.Exclude
	CastParams.FilterDescendantsInstances = {char,CosmeticBulletsFolder}
	
	local CosmeticPartProvider = PartCacheModule.new(CosmeticBullet, 20, CosmeticBulletsFolder)
	local CastBehavior = FastCast.newBehavior()
	CastBehavior.RaycastParams = CastParams
	CastBehavior.MaxDistance = Constants.BULLET_MAXDIST
	CastBehavior.HighFidelityBehavior = FastCast.HighFidelityBehavior.Default

	CastBehavior.CosmeticBulletProvider = CosmeticPartProvider 

	CastBehavior.CosmeticBulletContainer = CosmeticBulletsFolder
	CastBehavior.Acceleration = Constants.BULLET_GRAVITY
	CastBehavior.AutoIgnoreContainer = false
	
	local self = {
		Caster = Caster,
		CastParams = CastParams,
		CastBehavior = CastBehavior,
		pos = nil,
		char = char,
	}
	
	setmetatable(self,ProjectileModule)
	
	self:initiliaze()
	
	return self
end

function ProjectileModule:initiliaze()
	self.Caster.RayHit:Connect(function(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
		self:OnRayHit(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
	end)
	self.Caster.RayPierced:Connect(function(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
		self:OnRayPierced(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
	end)
	self.Caster.LengthChanged:Connect(function(cast, segmentOrigin, segmentDirection, length, segmentVelocity, cosmeticBulletObject)
		self:OnRayUpdated(cast, segmentOrigin, segmentDirection, length, segmentVelocity, cosmeticBulletObject)
	end)
	self.Caster.CastTerminating:Connect(function(cast)
		self:OnRayTerminated(cast)
	end)
end

function ProjectileModule.OnRayPierced(cast, raycastResult, segmentVelocity, cosmeticBulletObject)

	local position = raycastResult.Position
	local normal = raycastResult.Normal

	local newNormal = Reflect(normal, segmentVelocity.Unit)
	cast:SetVelocity(newNormal * segmentVelocity.Magnitude)


	cast:SetPosition(position)
end

function ProjectileModule:OnRayHit(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
	local hitPart = raycastResult.Instance
	local hitPoint = raycastResult.Position
	local normal = raycastResult.Normal
	if hitPart ~= nil and hitPart.Parent ~= nil then
		local humanoid:Humanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if self.pos then
				HitModule.onHit({hitPart.Parent},self.char,true,self.pos)
				local root = hitPart.Parent:FindFirstChild("HumanoidRootPart")
				local att = Instance.new("Attachment")
				local rootAtt = root:FindFirstChild("RootAttachment")
				att.Parent = root
				att.CFrame = CFrame.new(0,0,0.1)
				local trail = ReplicatedStorage.Effects.Trail:Clone()
				trail.Parent = root
				trail.Attachment0 = rootAtt
				trail.Attachment1 = att
				game:GetService("Debris"):AddItem(trail,0.5)
				game:GetService("Debris"):AddItem(att,0.5)
				self.pos = nil
			else
				print("a")
				HitModule.PlayStuff(hitPart.Parent)
				HitModule.HitEffects(hitPart.Parent)
			end
		end
	end
end

function ProjectileModule:OnRayUpdated(cast, segmentOrigin, segmentDirection, length, segmentVelocity, cosmeticBulletObject)
	if cosmeticBulletObject == nil then return end
	local bulletLength = cosmeticBulletObject.Size.Z / 2 
	local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + -segmentDirection)
	cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))
end

function ProjectileModule:OnRayTerminated(cast)
	local cosmeticBullet = cast.RayInfo.CosmeticBulletObject
	if cosmeticBullet ~= nil then
		if self.CastBehavior.CosmeticBulletProvider ~= nil then
			self.CastBehavior.CosmeticBulletProvider:ReturnPart(cosmeticBullet)
		else
			cosmeticBullet:Destroy()
		end
	end
end

function ProjectileModule:Fire(direction,victim,goal)
	if goal then
		self.pos = goal
	end
	local directionalCF = CFrame.new(Vector3.new(), direction)
	local direction = (directionalCF * CFrame.fromOrientation(0, 0, RNG:NextNumber(0, TAU)) * CFrame.fromOrientation(math.rad(RNG:NextNumber(Constants.MIN_BULLET_SPREAD_ANGLE, Constants.MAX_BULLET_SPREAD_ANGLE)), 0, 0)).LookVector

	if typeof(victim) ~= "Vector3" then
		local filter = {self.char,CosmeticBulletsFolder}
		for _,char in workspace.Alive:GetChildren() do
			if char ~= victim then
				table.insert(filter,char)
			end
		end
		self.CastParams.FilterDescendantsInstances = filter
	end
	
	local humanoidRootPart = self.char:WaitForChild("HumanoidRootPart", 1)	
	local myMovementSpeed = humanoidRootPart.Velocity							
	local modifiedBulletSpeed = (direction * Constants.BULLET_SPEED)
	local startPos
	if typeof(victim) == "Vector3" then
		startPos = victim
	else
		local victimRoot = victim:WaitForChild("HumanoidRootPart", 1)
		startPos = (victimRoot.CFrame * Constants.PROJECTILE_OFFSET).Position
	end
	if Constants.PIERCE_DEMO then
		self.CastBehavior.CanPierceFunction = CanRayPierce
	end

	local simBullet = self.Caster:Fire(startPos, direction, modifiedBulletSpeed, self.CastBehavior)

	SoundModule.PlaySound(Audio.FireSnd,humanoidRootPart)
	
	return simBullet
end

return ProjectileModule