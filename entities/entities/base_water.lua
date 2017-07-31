AddCSLuaFile()
DEFINE_BASECLASS( "base_anim" )

ENT.Type = "anim"
ENT.PrintName = "base_water"
ENT.Author = "StealthPaw"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category	= GAMEMODE.Name
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()
	self:SetRenderMode( RENDERMODE_TRANSALPHA )
	self:SetColor(Color(0,178,255,150))
	self:SetMaterial("models/debug/debugwhite")
	self:SetModel("models/hunter/blocks/cube05x075x025.mdl")
	if CLIENT then return end
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_NONE)
	self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:Wake() end
	local mins, maxs = self:GetHitBoxBounds( 0, 0 )
	self.minS = mins self.maxS = maxs
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
	
	function ENT:Splash(platePos)
		if (self.LastSplash or 0) >= CurTime() then return end self.LastSplash = CurTime()+1
		self:EmitSound( "ambient/materials/dinnerplates2.wav", 75 )
		local efD = EffectData()
		efD:SetOrigin( platePos )
		efD:SetScale( 4 )
		util.Effect( "watersplash", efD )
	end
	
	function ENT:Inside() local pos = self:GetPos() return ents.FindInBox( pos+self.minS, pos+self.maxS ) end
	
	function ENT:Contains()
		for k,v in pairs(self.Contained) do
			if !IsValid(v) then table.remove(self.Contained, k) continue end
			if !table.HasValue(self:Inside(), v) then self:RemoveDish( v )  continue end
			local phy = v:GetPhysicsObject()
			if IsValid( phy ) then
				phy:SetVelocity( ( ( self:GetPos() + (self:GetUp()*5) ) - v:GetPos() ):Angle():Forward() * 1 )
			end
			
		end
		if #self.Contained <= 0 then return false end return true
	end
	
	function ENT:RemoveDish( dish )
		self:EmitSound( "ambient/materials/dinnerplates1.wav", 75 )
		table.RemoveByValue(self.Contained, dish)
		local phy = dish:GetPhysicsObject()
		phy:EnableGravity( true )
	end
	
	function ENT:AddDish( dish )
		if dish.Clean then dish:Clean() end
		self.Contained = self.Contained or {}
		local phy = dish:GetPhysicsObject()
		phy:EnableGravity( false )
		
		self:Splash(dish:GetPos())
		
		return table.insert(self.Contained, dish)
	end
	
	local CanFloat = {"item_plate"}
	function ENT:Think( ply, tr, ClassName )
		if self.Contained and !self:Contains() then self.Contained = false end
		for k,v in pairs(self:Inside()) do
			if v:IsOnFire() then v:Extinguish() end
			if table.HasValue(CanFloat, v:GetClass()) and !table.HasValue(self.Contained or {}, v) then self:AddDish( v ) break end
		end
	end
end