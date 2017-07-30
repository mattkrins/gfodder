--[[
	ply.profile.name
	ply.profile.money
	ply.profile.models
	ply.profile.hats
]]
PlayerSystem = {}
PlayerSystem.Options = {
	["MENU MUSIC"] = "Toggle",
	["GAME MUSIC"] = "Toggle"
}
PlayerSystem.Defaults = {}
for k, v in pairs(PlayerSystem.Options) do
	PlayerSystem.Defaults[k] = v
	if v == "Toggle" then PlayerSystem.Defaults[k] = true end
end
if SERVER then
	util.AddNetworkString( "Player.Net" )
	PlayerSystem.Sync = function( self, ply )
		ply:SetPData( "settings", util.TableToJSON( ply.settings or self.Defaults ) )
		net.Start( "Player.Net" ) net.WriteTable(ply.settings or self.Defaults) net.Send(ply)
	end
	net.Receive( "Player.Net", function(len, ply)
		if ( !IsValid( ply ) or !ply:IsPlayer() ) then return end
		local Name = net.ReadString() if !Name or !PlayerSystem.Options[Name] then return end
		if PlayerSystem.Options[Name] == "Toggle" then
			local Value = net.ReadBool() or false
			ply.settings[Name] = Value
		end
		PlayerSystem:Sync(ply)
	end )
	hook.Add( "PlayerInitialSpawn", "PlayerInitialSpawnPlayer", function ( ply )		
		ply.settings = ply:GetPData( "settings", false ) or false
		if !ply.settings or (table.Count(util.JSONToTable( ply.settings )) <= 0) then
			ply.settings = table.Copy(PlayerSystem.Defaults)
		else
			oldSettings = util.JSONToTable( ply.settings )
			ply.settings = {}
			for k, v in pairs(PlayerSystem.Options) do
				ply.settings[k] = oldSettings[k] or PlayerSystem.Defaults[k]
			end
		end
		PlayerSystem:Sync(ply)
	end )
	PlayerSystem.GetSetting = function( self, Name, ply )
		return ply.settings[Name] or false
	end
else
	LocalPlayer().settings = LocalPlayer().settings or {}
	net.Receive( "Player.Net", function() LocalPlayer().settings = net.ReadTable() or {} end )
	PlayerSystem.GetSetting = function( self, Name ) LocalPlayer().settings = LocalPlayer().settings or {} return LocalPlayer().settings[Name] or false end
	local optionHooks = {
		["GAME MUSIC"] = function(Name)
			if !GamemodeSystem:GetPlaying() then return end
			if !PlayerSystem:GetSetting(Name) then return end
			MusicSystem:Stop()
		end
	}
	PlayerSystem.ChangeSetting = function( self, Name, toSend )
		net.Start( "Player.Net" )
			net.WriteString(Name)
			if toSend then toSend(Name) end
		net.SendToServer()
		if optionHooks[Name] then optionHooks[Name](Name) end
	end
end