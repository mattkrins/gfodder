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
		ply.settings = ply.settings or {}
		ply:SetPData( "settings", util.TableToJSON( ply.settings ) )
		net.Start( "Player.Net" ) net.WriteTable(ply.settings) net.Send(ply)
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
		local oldSettingPData = ply:GetPData( "settings", false ) or false
		ply.settings = table.Copy(PlayerSystem.Defaults)
		if oldSettingPData then
			oldSettings = util.JSONToTable( oldSettingPData or "" ) or {}
			for k, v in pairs(PlayerSystem.Defaults) do
				if oldSettings[k] != nil then ply.settings[k] = oldSettings[k] end
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
		end,
		["MENU MUSIC"] = function(Name)
			if GamemodeSystem:GetPlaying() then return end
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