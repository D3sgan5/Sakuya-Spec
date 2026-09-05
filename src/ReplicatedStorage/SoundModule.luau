local SoundModule = {}

function SoundModule.PlaySound(sound:Sound,parent,diff:boolean)
	local s = sound:Clone()
	s.Parent = parent
	if diff then
		s.PlaybackSpeed = sound.PlaybackSpeed + math.random(-10,10)/100
	end
	s:Play()
	game.Debris:AddItem(s,s.TimeLength)
end

return SoundModule
