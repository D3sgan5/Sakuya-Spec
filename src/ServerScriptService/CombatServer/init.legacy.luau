local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Models = ReplicatedStorage:WaitForChild("Models")

local CombatController = require(script.CombatController)
local combatMassive = {}

local M1Event = ReplicatedStorage:WaitForChild("M1Event")

local actionTypes = {
	['M1'] = "M1",
	['Action'] = "Action",
	['Skill1'] = "Skill1",
	['Skill2'] = "Skill2",
	['MouseUpd'] = 'MouseUpd'
}

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		char.Parent = workspace.Alive
		char:SetAttribute('Combo',1)
		combatMassive[char] = CombatController.new(char)
		
		local Watch = Models.Watch:Clone()
		local Dagger = Models.Dagger:Clone()
		local RightArm = char:FindFirstChild("Right Arm")
		local LeftArm = char:FindFirstChild("Left Arm")
		Watch.Parent = LeftArm
		Watch.Motor6D.Part0 = LeftArm
		Watch.Motor6D.Part1 = Watch
		Dagger.Parent = RightArm
		Dagger.Motor6D.Part0 = RightArm
		Dagger.Motor6D.Part1 = Dagger
	end)
end)

M1Event.OnServerEvent:Connect(function(plr,action:string,mouse:Vector3)
	
	local  char = plr.Character
	if not char:GetAttribute("Attacking") then
		local handler = combatMassive[char]
		if action == actionTypes.M1 and not char:GetAttribute("M1Cd") then
			handler:Attack()
		elseif action == actionTypes.Action and not char:GetAttribute("ActionCd") then
			handler:Action()
		elseif action == actionTypes.Skill1 then
			handler:CircleOfKnives(mouse)
		elseif action == actionTypes.Skill2 then
			handler:ReverseCircleOfKnives(mouse)
		elseif action == actionTypes.MouseUpd then
			handler:MouseUpd(mouse)
		end
	end
end)