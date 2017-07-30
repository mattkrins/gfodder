AddCSLuaFile()
DEFINE_BASECLASS( "base_ai" )

ENT.Type = "ai"
ENT.PrintName = "base_judge"
ENT.Author = "StealthPaw"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category	= GAMEMODE.Name
ENT.Model	= "models/Eli.mdl"

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

function ENT:SetAutomaticFrameAdvance( bUsingAnim )
	self.AutomaticFrameAdvance = bUsingAnim
end

if (SERVER) then
	local function addAnimation(Sequence) local Schedule = ai_schedule.New(Sequence) Schedule:AddTask( "PlaySequence", { Name = Sequence, Speed = 1 } ) return Schedule end
	local Sequence_Winner = addAnimation("cheer1")
	local Sequence_Looser = {addAnimation("Fear_Reaction"),addAnimation("photo_react_blind")}
	function ENT:Initialize()
		self:SetModel(self.Model)
		self:SetHullType( HULL_HUMAN )
		self:SetHullSizeNormal()
		self:SetSolid(SOLID_BBOX)
		self:SetMoveType(MOVETYPE_STEP)
		self:CapabilitiesAdd( CAP_TURN_HEAD )
		self:CapabilitiesAdd( CAP_ANIMATEDFACE )
		self:CapabilitiesAdd( CAP_MOVE_GROUND )
		self:SetMaxYawSpeed( 5000 )
		self:SetUseType(SIMPLE_USE)
		self:DrawShadow(false)
		self:SetSequence( 3 )
		self:SetHealth(100)
		self.Judging = false
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then phys:Wake() end
		self:DropToFloor()
	end
	local Sequence_Idle = addAnimation("idle01")
	function ENT:SelectSchedule() self:StartSchedule( Sequence_Idle ) end
	function ENT:AcceptInput( Name, Activator, Caller ) if Name == "Use" and Caller:IsPlayer() then self:OnUse(Caller) end end
	function ENT:OnTakeDamage() return false end
	local badVoices = {
		Sound(GAMEMODE.Name.."/judge/bad/piss.mp3"),
		Sound(GAMEMODE.Name.."/judge/bad/pileofshit.mp3"),
		Sound(GAMEMODE.Name.."/judge/bad/minging.mp3"),
		Sound(GAMEMODE.Name.."/judge/bad/howcanyoueat.mp3"),
		Sound(GAMEMODE.Name.."/judge/bad/grim.mp3")
	}
	local goodVoices = {
		Sound(GAMEMODE.Name.."/judge/good/delicious.mp3"),
		Sound(GAMEMODE.Name.."/judge/good/deliciouswelldone.mp3"),
		Sound(GAMEMODE.Name.."/judge/good/fknyum.mp3"),
		Sound(GAMEMODE.Name.."/judge/good/goodfknfood.mp3"),
		Sound(GAMEMODE.Name.."/judge/good/lightnice.mp3"),
		Sound(GAMEMODE.Name.."/judge/good/quitenice.mp3"),
		Sound(GAMEMODE.Name.."/judge/good/thnxbloddelic.mp3"),
		Sound(GAMEMODE.Name.."/judge/good/wowdelicious.mp3")
	}
	
	function ENT:TakePlate(plate)
		plate.HasJudge = self
		plate:SetPos(self:GetAttachment( 8 ).Pos)
		plate:SetParent(self, 8)
	end
	function ENT:PlacePlate(plate)
		plate.HasJudge = false
		plate.Judged = true
		plate:SetParent(nil)
		plate:SetPos(self:EyePos()+(self:GetForward()*30))
	end
	function ENT:Reset()
		self.Judging = false
		self.NextJudge = 0
	end
	
	local Sequence_Eat = addAnimation("luggageshrug")
	function ENT:Judge(plate)
		self:StartSchedule( Sequence_Eat )
		if (plate:GetDirty() or 0) > 0 then
			self:EmitSound( badVoices[math.random(#badVoices)] )
			timer.Simple( 2, function() if IsValid(self) then self:StartSchedule( table.Random(Sequence_Looser) ) self:EmitSound( "ambient/voices/cough"..math.random(1,4)..".wav" ) end end)
		else
			self:EmitSound( goodVoices[math.random(#goodVoices)] )
			timer.Simple( 2, function() if IsValid(self) then self:StartSchedule( Sequence_Winner ) end end)
		end
		plate:Eat(self)
		
	end
	local Sequence_Accept = addAnimation("takepackage")
	local Sequence_Place = addAnimation("Heal")
	function ENT:Take(plate)
		self.NextJudge = CurTime()+10
		self.Judging = plate
		self:StartSchedule( Sequence_Accept )
		timer.Simple( 2, function()
			if !IsValid(self) then return end
			if !self:NearPlate() then self:Reset() return end
			if IsValid(plate) then self:TakePlate(plate) end
			timer.Simple( 1, function() if IsValid(plate) then self:Judge(plate) end end)
			timer.Simple( 3, function() if IsValid(self) then self:StartSchedule( Sequence_Place ) end end)
			timer.Simple( 4, function()
				if IsValid(self) then
					if IsValid(plate) then self:PlacePlate(plate) end
					self.Judging = false
				end
			end )
		end)
	end
	function ENT:Think()
		if (self.NextJudge or 0) >= CurTime() then return end
		for _, v in pairs( player.GetAll() ) do
			if ( v:EyePos():Distance( self:EyePos() ) <= 100 ) then
				self:SetEyeTarget( v:EyePos() )
				break
			end
		end
		if self.Judging then if !IsValid(self.Judging) then self.Judging = false end return end
		for _,v in pairs(ents.FindInSphere( self:EyePos()+(self:GetForward()*20), 30 )) do
			if v:GetClass() == "item_plate" and v:HasFood() and !v.Judged then
				local phy = v:GetPhysicsObject()
				if IsValid( phy ) then
					if IsValid(v.HeldBy) and v.HeldBy.Holding then v.HeldBy:DropHeld() end
					phy:SetVelocity( ( ( self:GetPos() + self:OBBCenter() ) - v:GetPos() ):Angle():Forward() * 55 )
				end
			end
		end
		local plate = self:NearPlate()
		if plate then self:Take(plate) end
	end
	function ENT:NearPlate()
		for _,v in pairs(ents.FindInSphere( self:EyePos(), 30 )) do
			if v:GetClass() == "item_plate" and v:HasFood() and !v.Judged then return v end
		end
	end
		
	local idleVoices = {
		Sound(GAMEMODE.Name.."/judge/hello.mp3"),
		Sound(GAMEMODE.Name.."/judge/isdatfunny.mp3"),
		Sound(GAMEMODE.Name.."/judge/no.mp3"),
		Sound(GAMEMODE.Name.."/judge/waturudoin.mp3"),
		Sound(GAMEMODE.Name.."/judge/wipeass.mp3")
	}
	local Sequence_Wave = addAnimation("Wave_close")
	function ENT:OnUse( ply )
		if self.Judging then return end
		if (self.NextTalk or 0) >= CurTime() then return end
		self.NextTalk = CurTime()+10
		self:EmitSound( idleVoices[math.random(#idleVoices)] )
		self:StartSchedule( Sequence_Wave )
	end
end
