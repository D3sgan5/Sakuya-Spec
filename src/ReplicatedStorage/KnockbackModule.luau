local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local replica = ReplicatedStorage.ReplicaRemote
replica.Sandboxed = true

local vels = {}
local BASE_GRAVITY = 9.8
local WORKSPACE_GRAVITY = 196.2

local KnockbackModule = {}
KnockbackModule.__index = KnockbackModule

function KnockbackModule.new(Gravity,Wind,WhiteList,DespawnTime,MaxBounces,Decay,Threshold,Visualize,char)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = WhiteList
	
	local self = {
		Gravity = Gravity,
		Wind = Wind,
		Params = params,
		DespawnTime = DespawnTime,
		MaxBounces = MaxBounces,
		Decay = Decay,
		Threshold = Threshold,
		Visualize = Visualize,
		char = char,
		bv = nil,
		alignOr = nil,
		connections = {},
	}

	setmetatable(self,KnockbackModule)

	return self
end

function KnockbackModule:ClearCon()
	for _,con in self.connections do
		con:Disconnect()
		con = nil
	end
end

function KnockbackModule:ClearStuff()
	if self.bv then
		self.bv:Destroy()
		self.bv = nil
	end

	if self.alignOr then
		self.alignOr:Destroy()
		self.alignOr = nil
	end
end

function KnockbackModule:ChangeGravity(value:number)
	self.Gravity = value
end

function KnockbackModule:Fire(start,goal,force,target:BasePart,orientation)
	local convertation = WORKSPACE_GRAVITY/BASE_GRAVITY
	
	if #self.connections > 0 then
		self:ClearCon()
		self:ClearStuff()
	end
	
	local velocity = (goal - start).Unit * force * convertation
	local a = Vector3.new(self.Wind.X,self.Wind.Y - self.Gravity * BASE_GRAVITY,self.Wind.Z) * convertation

	
	local t = 0
	local totalTime = 0
	local replicateT = 0
	local bounces = 0
	local currentVelocity = velocity
	local currentPos = start
	local rayResult = nil
	local found  = false

	local connection:RBXScriptConnection
	local humanoid:Humanoid = target.Parent:FindFirstChildOfClass("Humanoid")
	local rootAtt = target.RootAttachment
	
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
	bv.Velocity = currentVelocity
	bv.P = math.huge
	bv.Parent = target
	local wasTS = false
	self.bv = bv
	
	local x,y,z
	local alignOr = Instance.new("AlignOrientation")
	alignOr.Parent = target
	alignOr.Attachment0 = rootAtt
	alignOr.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOr.MaxTorque = math.huge
	alignOr.Responsiveness = 2000000
	alignOr.RigidityEnabled = true
	self.alignOr = alignOr
	
	table.insert(self.connections,RunService.Heartbeat:Connect(function(dt)
		if not found then
			if workspace:GetAttribute("Timestop") then replica:FireAllClients(target,target.CFrame) wasTS = true bv.Velocity = Vector3.zero return end
			
			t += dt
			totalTime += dt
			replicateT += dt

			currentVelocity = velocity + a*t

			local projPos = Vector3.new(
				start.X + velocity.X * t + 0.5*a.X*t*t,
				start.Y + velocity.Y * t + 0.5*a.Y*t*t,
				start.Z + velocity.Z * t + 0.5*a.Z*t*t
			)
			
			if totalTime > 0.3 and not target.Parent:GetAttribute("Freefall") then
				target.Parent:SetAttribute("Freefall",true)
			end
			if replicateT > 0.1 then
				replicateT %= 0.1
				replica:FireAllClients(target,target.CFrame)
			end
			rayResult = workspace:Raycast(currentPos,projPos - currentPos, self.Params)
			bv.Velocity = currentVelocity
			alignOr.CFrame = CFrame.new(currentPos,projPos) * CFrame.Angles(math.rad(90), 0, math.rad(-180))
			currentPos = projPos


			if self.Visualize then
				local part = Instance.new("Part")
				part.Position = target.CFrame.Position
				part.Anchored = true
				part.CanCollide = false
				part.Material = Enum.Material.Neon
				part.Shape = Enum.PartType.Ball
				part.CanQuery = false
				part.Size = Vector3.new(0.5,0.5,0.5)
				part.Transparency = 0.5
				if wasTS then
					part.Color = Color3.fromRGB(255, 0, 4)
				else
					part.Color = Color3.fromRGB(12, 255, 61)
				end
				part.Parent = workspace.Trash

				game:GetService("Debris"):AddItem(part,0.5)
			end	

			if rayResult then
				bounces += 1
				t = 0

				if bounces < self.MaxBounces then

					velocity = self.Decay * (currentVelocity - 2*currentVelocity:Dot(rayResult.Normal) * rayResult.Normal)
					if velocity.Magnitude < self.Threshold then
						found = true
					end
					start = rayResult.Position
					currentPos = rayResult.Position
				else
					found = true
				end
			end

			if totalTime > self.DespawnTime then
				found = true
			end
		end
	end))

	while not found do
		task.wait()
	end
	
	if not self.bv then
		return
	end
	
	target.Parent:SetAttribute("Freefall",nil)
	
	self:ClearCon()
	bv:Destroy()
	print(bv)
	self.bv = nil
	alignOr.CFrame = orientation
	self:Freefall(target.Parent,currentVelocity,rayResult,alignOr)
	

	if rayResult then
		target.CFrame = CFrame.new(rayResult.Position + Vector3.new(0,1,0)) * alignOr.CFrame.Rotation
		if self.Visualize then
			local part = Instance.new("Part")
			part.Position = rayResult.Position
			part.Anchored = true
			part.CanCollide = false
			part.Material = Enum.Material.Neon
			part.Shape = Enum.PartType.Ball
			part.CanQuery = false
			part.Size = Vector3.new(3,3,3)
			part.Transparency = 0.5
			part.Color = Color3.fromRGB(12, 255, 61)
			part.Parent = workspace.Trash

			game:GetService("Debris"):AddItem(part,0.5)
		end
	end
end

function KnockbackModule:Freefall(character, direction,raycast,alignOr)
	local humanoid:Humanoid = character:FindFirstChild("Humanoid")
	local root:BasePart = character:FindFirstChild("HumanoidRootPart")
	local rootJoint:Motor6D = root.RootJoint
	local replicateT = 0
	
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(100000,100000,100000)
	bv.Velocity = (direction.Unit * 100) 
	bv.Parent = root
	local con
	con = RunService.Heartbeat:Connect(function(dt)
		replicateT += dt
		bv.Velocity = bv.Velocity * (0.95+dt)
		
		if replicateT > 0.1 then
			replicateT %= 0.1
			replica:FireAllClients(root,root.CFrame)
		end
		if bv.Velocity.Magnitude < 2 then
			con:Disconnect()
			bv:Destroy()
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			alignOr:Destroy()
			self.alignOr = nil
		end
	end)
end

return KnockbackModule