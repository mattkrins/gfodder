MusicSystem = {}
if SERVER then
	MusicSystem.PlaySound = function( self, fileName, ply ) 
		net.Start( "MusicSystem.Net" )
		net.WriteString(fileName)
		if !ply then net.Broadcast() else net.Send(ply) end
	end
	util.AddNetworkString( "MusicSystem.Net" )
	return
end
net.Receive( "MusicSystem.Net", function() local fileName = net.ReadString() or false if fileName and fileName!="" then surface.PlaySound( fileName ) end end )
local Music = {}
Audio = Audio or false
Music.File = "sound/overcooked/music/level1.mp3"
Music.Volume = 0.5
Music.Stop = function( self )
	if !Audio or !IsValid( Audio ) then return false end
	self.Playing = false
	Audio:Stop()
	Audio = nil
end
Music.Play = function( self )
	if !Audio or !IsValid( Audio ) then return false end
	self.Playing = true
	Audio:Play()
	Audio:SetVolume( self.Volume )
end
Music.SpeedUp = function( self )
	if !Audio or !IsValid( Audio ) then return false end
	self.Rate = math.Clamp((self.Rate or 1) + 0.01,1,3)
	Audio:SetPlaybackRate( self.Rate )
end
concommand.Add("Music_SpeedUp", function(ply, cmd, args) Music:SpeedUp() end)
Music.Load = function( self, fileName )
	if !fileName or self.Playing then return false end
	self:Stop()
	sound.PlayFile( fileName, "noplay noblock", function( station, errorNum )
		if !IsValid( station ) or errorNum then return end
		Audio = station
		self.Rate = 1
		station:SetVolume( self.Volume )
		station:EnableLooping( true )
		station:SetPlaybackRate( self.Rate )
		self:Play()
	end )
end

MusicSystem.Play = function( self, fileName, volume ) if !fileName then return false end self.Volume = volume or self.Volume return Music:Load(fileName) end
concommand.Add("Music_Play", function(ply, cmd, args) MusicSystem:Play(args[1] or false,args[2] or false) end)
MusicSystem.Stop = function( self ) return Music:Stop() end
concommand.Add("Music_Stop", function(ply, cmd, args) MusicSystem:Stop() end)
MusicSystem.Audio = function( self ) return Audio or false end

