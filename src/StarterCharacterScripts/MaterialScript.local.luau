local MaterialSounds = 
	{
		[Enum.Material.Grass] = "rbxassetid://507863105",
		[Enum.Material.Metal] = "rbxassetid://944089664",
		[Enum.Material.DiamondPlate] = "rbxassetid://944089664",
		[Enum.Material.Pebble] = "rbxassetid://944090255",
		[Enum.Material.Wood] = "rbxassetid://944075408",
		[Enum.Material.WoodPlanks] = "rbxassetid://944075408",
		[Enum.Material.Plastic] = "rbxassetid://944075408",
		[Enum.Material.SmoothPlastic] = "rbxassetid://944075408",
		[Enum.Material.Sand] = "rbxassetid://944090255",
		[Enum.Material.Brick] = "rbxassetid://4981969796",
		[Enum.Material.Cobblestone] = "rbxassetid://4981969796",
		[Enum.Material.Concrete] = "rbxassetid://944075408",
		[Enum.Material.CorrodedMetal] = "rbxassetid://4981969796",
		[Enum.Material.Fabric] = "rbxassetid://4981969796",
		[Enum.Material.Foil] = "rbxassetid://4981969796",
		[Enum.Material.ForceField] = "rbxassetid://4981969796",
		[Enum.Material.Glass] = "rbxassetid://944075408",
		[Enum.Material.Granite] = "rbxassetid://944075408",
		[Enum.Material.Ice] = "rbxassetid://4981969796",
		[Enum.Material.Marble] = "rbxassetid://944075408",
		[Enum.Material.Neon] = "rbxassetid://4981969796",
		[Enum.Material.Slate] = "rbxassetid://944075408",
	}

local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local FootStepsSound = HumanoidRootPart:WaitForChild("Running")
FootStepsSound.SoundId = "rbxassetid://944075408"

Humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
	local FloorMaterial = Humanoid.FloorMaterial
	local Sound = MaterialSounds[FloorMaterial]
	FootStepsSound.TimePosition = 0
	if Sound then
		FootStepsSound.SoundId = Sound
	else
		FootStepsSound.SoundId = "rbxassetid://944075408"
	end
end)