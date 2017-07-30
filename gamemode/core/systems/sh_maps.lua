local function MakeEnt( entClass, entPos, entAngle, entMovable, entHide, entGhost, entModel, entMaterial )
	local ent = ents.Create(entClass or "prop_physics")
	ent:SetPos(entPos)
	ent:SetAngles(entAngle or Angle(0,0,0))
	ent.InitVector = entPos
	ent.InitAngle = entAngle or Angle(0,0,0)
	if entMaterial then ent:SetMaterial( entMaterial, false ) end
	if entHide then
		if DEVELOPER_MODE then
			ent:SetMaterial( "models/wireframe" )
		else
			ent:Fire( "alpha", 0, 0 )
			ent:SetMaterial( "models/effects/vol_light001" )
			ent:SetNoDraw( true )
		end
	end
	if entModel then ent:SetModel(entModel) end
	ent:SetSolid(SOLID_VPHYSICS)
	if !entMovable then
		ent:SetMoveType(MOVETYPE_NONE)
	else
		ent:SetMoveType(MOVETYPE_VPHYSICS)
	end
	if entGhost then
		ent:PhysicsInit(SOLID_NONE)
		ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
		ent.GhostProp = true
	else
		ent:PhysicsInit(SOLID_VPHYSICS)
	end
	ent:Spawn()
	ent:Activate()
	if !entMovable then
		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end
	else
		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then phys:Wake() end
	end
	return ent
end


Map = Map or {}
local root = GM.Name.."/gamemode/maps/"
local files = file.Find(root .. "*", "LUA")
for k,v in pairs(files) do if string.StripExtension(v) != game.GetMap() then continue end include(root .. v) end
if CLIENT then return end
MapSystem = {}
MapSystem.Spawn = function( self, entClass, entPos, entAngle, entMovable, entHide, entGhost, entModel, entMaterial )
	local positions = entPos
	if isvector(positions) then positions = {entPos} end
	for _,v in pairs(positions) do
		MakeEnt( entClass or "prop_physics", v, entAngle or Angle(0,0,0), entMovable or false, entHide or false, entGhost or false, entModel or false, entMaterial or false )
	end
end

local Unmoving = {"base_food_preparation","base_fridge","base_bin"}
concommand.Add("Map_Reset", function(ply) if !ply:IsAdmin() then return end MapSystem:Reset() end)
MapSystem.Reset = function( self )
	local Unmovable = {}
	for _,v in pairs(ents.GetAll()) do
		if v:GetClass() == "base_food" then v:Remove() continue end
		if v.InitAngle then
			v:GetPhysicsObject():SetVelocityInstantaneous( Vector(0,0,0) )
			v:SetAngles(v.InitAngle)
		end
		if v.InitVector then
			v:SetVelocity( Vector(0,0,0) )
			v:SetPos(v.InitVector)
		end
		if table.HasValue(Unmoving, v:GetClass()) then table.insert(Unmovable, v) end
	end
	for _,v in pairs(Unmovable) do
		for _,u in pairs(Unmovable) do
			if v == u then continue end
			constraint.NoCollide( v, u, 0, 0 )
		end
	end
end

local Replaceable = {
	["models/props/cs_office/trash_can.mdl"] = "base_bin",
	["models/props_interiors/pot02a.mdl"] = "item_pot",
	["models/props_c17/metalpot001a.mdl"] = "item_pot_large",
	["models/props_c17/metalpot002a.mdl"] = "item_pan",
	["models/props/cs_office/fire_extinguisher.mdl"] = "base_fire_extinguisher",
	["models/foodnhouseholditems/mcdmealplate.mdl"] = "base_food_preparation",
	["models/props_vents/vent_large_grill001.mdl"] = "base_food_preparation",
	["models/foodnhouseholditems/servingplate.mdl"] = "item_plate",
	["models/ptejack/props/fridge/pj_fridge.mdl"] = "base_fridge",
	["models/props_c17/furniturefridge001a.mdl"] = "base_fridge",
	["models/props_interiors/refrigerator01a.mdl"] = "base_fridge"
}
hook.Add( "InitPostEntity", "InitPostEntityMap", function()
	for _,v in pairs(ents.GetAll()) do
		if Replaceable[v:GetModel()] then
			local c = Replaceable[v:GetModel()]
			local p = v:GetPos()
			local a = v:GetAngles()
			v:Remove()
			local s = MakeEnt( c, p, a, !table.HasValue(Unmoving, c) )
			s.InitVector = p
			s.InitAngle = a
		elseif table.HasValue(Replaceable, v:GetClass()) then
			v.InitVector = v:GetPos()
			v.InitAngle = v:GetAngles()
		end
	end
	if Map.Init then Map:Init() end
	MapSystem:Reset()
end )
