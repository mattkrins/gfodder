AddCSLuaFile()
DEFINE_BASECLASS( "base_food_station2" )

ENT.Type = "anim"
ENT.PrintName = "base_bin"
ENT.Author = "StealthPaw"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "overcooked"
ENT.Model = "models/props/cs_office/trash_can.mdl"
ENT.Material = ""
ENT.CanHold	= 1

if SERVER then
	function ENT:TouchFood( Name, foodEntity )
		foodEntity:Remove()
		self:EmitSound( "physics/cardboard/cardboard_cup_impact_hard"..math.random(1,3)..".wav" )
	end
	function ENT:OnUse( ply )
		
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
end
