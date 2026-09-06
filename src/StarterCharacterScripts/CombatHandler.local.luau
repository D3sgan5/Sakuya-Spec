local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local char = script.Parent
local root:Part = char:WaitForChild("HumanoidRootPart")
local GUI = player.PlayerGui.ScreenGui
local inputs = {
	['M1'] = Enum.UserInputType.MouseButton1,
	['Action'] = Enum.KeyCode.R,
	["Skill1"] = Enum.KeyCode.Z,
	["Skill2"] = Enum.KeyCode.X,
}

local connections,vels = {},{}
local M1Event = ReplicatedStorage.M1Event
local ReplicaEvent = ReplicatedStorage.ReplicaRemote

UIS.InputBegan:Connect(function(input,gameprocessed)
	if gameprocessed then return end
	if input.UserInputType == inputs.M1 then
		M1Event:FireServer("M1")
	elseif input.KeyCode == inputs.Action then
		M1Event:FireServer("Action")
	elseif input.KeyCode == inputs.Skill1 then
		M1Event:FireServer("Skill1",mouse.Hit.Position)
	elseif input.KeyCode == inputs.Skill2 then
		M1Event:FireServer("Skill2",mouse.Hit.Position)
	end
end)

UIS.InputEnded:Connect(function(input,gameprocessded)
	if gameprocessded then return end
	if input.KeyCode == inputs.Skill1 or input.KeyCode == inputs.Skill2 then
		M1Event:FireServer("MouseUpd",mouse.Hit.Position)
	end
end)

function StopConnections()
	for _, connection in connections do
		task.cancel(connection)
	end

	for _, vel in vels do
		vel:Destroy()
	end
end

function CheckForward()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char}
	params.RespectCanCollide = true
	local result:RaycastResult = workspace:Blockcast(root.CFrame,Vector3.new(4,4,1),root.CFrame.LookVector * 15,params)
	
	if result then
		return result
	end
end

workspace:GetAttributeChangedSignal("Timestop"):Connect(function()
	if workspace:GetAttribute("Timestop") then
		GUI.ImageLabel.Visible = true
	else
		GUI.ImageLabel.Visible = false
	end
end)

M1Event.OnClientEvent:Connect(function(pos)
	StopConnections()
	local bv:BodyPosition = Instance.new("BodyPosition")
	local check = CheckForward()
	bv.MaxForce = Vector3.new(100000,0,100000)
	bv.Parent = script.Parent.HumanoidRootPart
	bv.P = 50000
	
	if check then
		local direction
		if check.Instance.Parent.Parent == workspace.Alive then
			local victimRoot = check.Instance.Parent.HumanoidRootPart
			direction = (root.Position-victimRoot.Position).Unit
			bv.Position = victimRoot.Position +(direction * 3)
		else
			direction = (root.Position - check.Position).Unit
			bv.Position = check.Position + (direction*3)
		end
	else
		bv.Position = (script.Parent.HumanoidRootPart.CFrame * CFrame.new(0,0,-15)).Position
	end
	
	table.insert(vels,bv)
	table.insert(connections,task.delay(0.5,function()
		bv:Destroy()
	end))
end)

ReplicaEvent.OnClientEvent:Connect(function(target:BasePart,position)
	TweenService:Create(target,TweenInfo.new(0.2),{CFrame = position}):Play()
end)