local replicatedStorage = game:GetService("ReplicatedStorage")
local animations = replicatedStorage:WaitForChild("Animations")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
for _,animation in animations:GetDescendants() do
	if animation:IsA("Animation") then
		local animator = char:WaitForChild("Humanoid"):WaitForChild("Animator")
		animator:LoadAnimation(animation)
	end
end