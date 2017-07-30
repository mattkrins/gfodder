AddCSLuaFile()
DEFINE_BASECLASS( "base_anim" )

ENT.Type = "anim"
ENT.PrintName = "base_fire_extinguisher"
ENT.Author = "StealthPaw"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category	= GAMEMODE.Name
ENT.OCItem	= true
ENT.WaterLength	= 50
ENT.WaterStrength	= 1

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props/cs_office/fire_extinguisher.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetNWBool( "Spraying", false )
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

function ENT:NozzlePos() return self:GetPos()+(self:GetUp()*25)+(self:GetForward()*5) end

if SERVER then
	function ENT:Use()
		if (self.NextUse or 0) >= CurTime() then return end self.NextUse = CurTime() + 1
		if self:GetNWBool( "Spraying", false ) then self:StopSound( "base_fire_extinguisher" ) else self:EmitSound( "base_fire_extinguisher" ) end
		self:SetNWBool( "Spraying", !self:GetNWBool( "Spraying", false ) )
	end
	
	sound.Add( {
		name = "base_fire_extinguisher",
		channel = CHAN_BODY,
		volume = 1.0,
		level = 50,
		pitch = { 100, 110 },
		sound = "ambient/gas/steam_loop1.wav"
	} )
	function ENT:Think()
		if !self:GetNWBool( "Spraying", false ) or false then return end
		local tr = util.TraceLine( {start = self:NozzlePos(),endpos = self:NozzlePos() + (self:GetUp() * self.WaterLength),filter = { self }} )
		if !tr.HitPos then return end
		for _, v in pairs(ents.FindInSphere( tr.HitPos, 20 )) do
			if v.Combustable then v:Extinguish() end
		end
		local phy = self:GetPhysicsObject()
		if IsValid( phy ) then
			phy:SetVelocity( -self:GetUp()*30 )
		end
	end
end
if CLIENT then
	function ENT:OnRemove()
		if IsValid(self.Emitter) then self.Emitter:Finish() end
		if IsValid(self.Distortion) then self.Distortion:Finish() end
	end
	function ENT:DrawDistortion()
		local pos = self:NozzlePos()
		if !IsValid(self.Distortion) then self.Distortion = ParticleEmitter( pos, false ) end
		local particle = self.Distortion:Add( "sprites/heatwave", pos )
		particle:SetVelocity( self:GetUp() * self.WaterLength )
		particle:SetDieTime( self.WaterStrength )
		particle:SetStartSize( math.Rand( 1, 8 ) )
		particle:SetEndSize( math.Rand( 10, 30 ) )
		particle:SetStartAlpha( 255 )
		particle:SetColor( color_white )
	end
	function ENT:DrawWater()
		local pos = self:NozzlePos()
		if !IsValid(self.Emitter) then self.Emitter = ParticleEmitter( pos, false ) end
		local particle = self.Emitter:Add( "particle/smokestack", pos )
		particle:SetVelocity( self:GetUp() * self.WaterLength )
		particle:SetDieTime( self.WaterStrength )
		particle:SetStartSize( math.Rand( 1, 8 ) )
		particle:SetEndSize( math.Rand( 10, 20 ) )
		particle:SetStartAlpha( math.Rand( 50, 60 ) )
		local waterColors = table.Random({Color(150, 200, 255, 255),Color(0, 255, 255, 255),Color(0, 128, 237, 255)})
		particle:SetColor( waterColors.r,waterColors.g,waterColors.b )
		
	end
	if DEVELOPER_MODE then
		function ENT:Draw()
			self:DrawModel()
			if !self:GetNWBool( "Spraying", false ) or false then return end
			render.DrawLine( self:NozzlePos(), self:NozzlePos() + (self:GetUp() * self.WaterLength), color_white, true )
		end
	end
	function ENT:Think()
		if !self:GetNWBool( "Spraying", false ) or false then return end
		self:DrawWater()
		self:DrawDistortion()
	end
end