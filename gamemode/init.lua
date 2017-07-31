AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
resource.AddWorkshop( 1095898654 ) // Custom Content
resource.AddWorkshop( 108024198 ) // CHILI's Workshop Food Models

local fol = GM.Name.."/gamemode/core/"
local files, folders = file.Find(fol .. "*", "LUA")
for k,v in pairs(files) do include(fol .. v) end
for _, folder in SortedPairs(folders, true) do
	if folder ~= "." and folder ~= ".." then
		for _, File in SortedPairs(file.Find(fol .. folder .."/sh_*.lua", "LUA"), true) do
			AddCSLuaFile(fol..folder .. "/" ..File)
			include(fol.. folder .. "/" ..File)
		end

		for _, File in SortedPairs(file.Find(fol .. folder .."/sv_*.lua", "LUA"), true) do
			include(fol.. folder .. "/" ..File)
		end

		for _, File in SortedPairs(file.Find(fol .. folder .."/cl_*.lua", "LUA"), true) do
			AddCSLuaFile(fol.. folder .. "/" ..File)
		end
	end
end

PLAYER = FindMetaTable( "Player" );
function PLAYER:Unassigned()
	if ( self:Team() == TEAM_UNASSIGNED || self:Team() == TEAM_SPECTATOR ) then return true end
	return false
end
function PLAYER:CanRespawn()
	if ( self:Unassigned() ) then return false end
	return true
end
function GM:PlayerInitialSpawn( ply )
	ply:SetTeam( TEAM_SPECTATOR )
	ply:SetModel( "models/player/odessa.mdl" )
end
function GM:PlayerSpawn( ply )
	if ( ply:Unassigned() ) then
		ply:StripAmmo()
		ply:StripWeapons()
		ply:Spectate( OBS_MODE_ROAMING )
		return false
	else
		ply:UnSpectate()
		ply:StripWeapons()
		ply:Give("hands")
		if (DEVELOPER_MODE or ply:IsAdmin()) then for _,v in pairs({"gmod_tool","weapon_physgun"}) do ply:Give(v) end end
		ply:SelectWeapon( "hands" )
		ply:SetWalkSpeed( 150 )
		ply:SetRunSpeed( 250 )
	end
end
function GM:PlayerDeath( victim ) if ( victim:Unassigned() ) then return end end
function GM:PlayerDeathThink( ply ) if ( !ply:CanRespawn() ) then return false else ply:Spawn() end end
function GM:PlayerSelectSpawn( ply ) if ( ply:Unassigned() ) then return end end
function GM:PlayerShouldTakeDamage() return false end
function GM:PlayerDeathSound() return false end
function GM:CanPlayerSuicide() return false end

