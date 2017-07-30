AddCSLuaFile()
DEFINE_BASECLASS( "base_anim" )

ENT.Type = "anim"
ENT.PrintName = "base_food"
ENT.Author = "StealthPaw"
ENT.Spawnable = false
ENT.AdminSpawnable = true
ENT.Category	= GAMEMODE.Name
ENT.OCItem	= true
ENT.Combustable = true

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "Food" );
	self:NetworkVar( "Bool", 0, "IsFood" );
	self:NetworkVarNotify( "Food", self.OnFoodChanged )
end

function ENT:OnFoodChanged()
	local model = FoodSystem:GetModel(self:GetFood())
	if model then self:SetModel(model) end
end

function ENT:Initialize()
	self:SetRenderMode( RENDERMODE_TRANSALPHA )
	if CLIENT then return end
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetIsFood(true)
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:Wake() end
end

function ENT:SpawnFunction( ply, tr, ClassName )
	if (SERVER) then
		if ( !tr.Hit ) then return end
		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 1 )
		ent:Spawn()
		ent:Activate()
		return ent
	end
end

if SERVER then
	function ENT:Combust()
		if self:IsOnFire() then return end
		self:Ignite( 4 )
		self.FireCount = (self.FireCount or 0) + 2
		if self.FireCount >= 2 then self:Remove() end
		timer.Simple( 3.9, function()
			if IsValid(self) and self:IsOnFire() then
				for _, v in pairs(ents.FindInSphere( self:GetPos(), 30 )) do if v.Combustable then v:Combust() end end
				timer.Simple( 1, function() if IsValid(self) then self:Combust() end end )
			end
		end )
	end
	concommand.Add("spawn_food", function(ply, cmd, args )
		if !DEVELOPER_MODE or !IsValid(ply) or !ply:IsAdmin() then return end
		if !args or !args[1] then return end
		local model = FoodSystem:GetModel(args[1])
		if !model then return end
		local tr = ply:GetEyeTrace( ) if ( !tr.Hit ) then return end
		local ent = ents.Create( "base_food" )
		ent:SetPos( tr.HitPos + tr.HitNormal * 5 )
		ent:SetModel(model)
		ent:Spawn()
		ent:Activate()
		ent.Spawned = true
		ent:SetFood(args[1])
		undo.Create( args[1] )
			undo.AddEntity( ent )
			undo.SetPlayer( ply )
		undo.Finish()
	end)
end