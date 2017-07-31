AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
resource.AddWorkshop( 1095898654 ) // Custom Content
resource.AddWorkshop( 108024198 ) // CHILI's Workshop Food Models

local fol = GM.Name.."/gamemode/core/"
local files, folders = file.Find(fol .. "*", "LUA")
for k,v in pairs(files) do
	include(fol .. v)
end
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

hook.Add( "PhysgunPickup", "OCDisallowPickups", function( ply, ent )
	if ent.GhostProp then return false end
end )

hook.Add( "PlayerInitialSpawn", "OCPlayerInitialSpawn", function ( ply )
	if !ply:Team() or ply:Team() != 2 then ply:SetTeam( 1 ) end
end )

function GM:PlayerShouldTakeDamage(ply, attacker) if IsValid(attacker) and attacker:IsPlayer() and attacker:IsAdmin	() then return true end return false end
function GM:PlayerDeathSound( ) return false end
function GM:CanPlayerSuicide( ply ) return (DEVELOPER_MODE or ply:IsAdmin()) end
local function addHat(model, hat)
	if IsValid(model.HatModel) then return end
	local headBone = model:LookupBone( "ValveBiped.Bip01_Head1" )
	local headPos = model:GetBonePosition( headBone )
	if headPos then
		if hat and Hats[hat] then
			local CSM = ents.Create("prop_static")
			CSM:SetModel(Hats[hat].Model)
			//local CSM = ClientsideModel( Hats[hat].Model, RENDERMODE_TRANSALPHA )
			if Hats[hat].Scale then CSM:SetModelScale( Hats[hat].Scale ) end
			CSM:SetPos(headPos)
			local headIndex = model:LookupAttachment( "anim_attachment_head" )
			CSM:SetParent(model, headIndex or -1)
			CSM:SetLocalAngles( Hats[hat].Angle or Angle(0,0,0) )
			CSM:SetLocalPos( Hats[hat].Vector or Vector(0,0,0) )
			CSM:AddEffects( EF_BONEMERGE_FASTCULL )
			//CSM:SetNoDraw( true )
			model.HatModel = CSM
			print(CSM)
		end
	end
end
local function Spawn( ply )
	ply:SetTeam( 2 )
	ply:StripWeapons()
end
hook.Add( "PlayerSpawn", "PlayerSpawns", Spawn )

function GM:PlayerSetModel( ply )
	ply:SetModel( "models/player/odessa.mdl" )
end

local function died( ply )
	ply.NextSpawn = CurTime() + 2
end
hook.Add( "PostPlayerDeath", "PlayerDeaths", died )

function GM:PlayerLoadout( ply )
	ply:Give("hands")
	if (DEVELOPER_MODE or ply:IsAdmin()) then for _,v in pairs({"gmod_tool","weapon_physgun"}) do ply:Give(v) end end
	ply:SelectWeapon( "hands" )
	ply:SetWalkSpeed( 150 )
	ply:SetRunSpeed( 250 )
	return true
end
