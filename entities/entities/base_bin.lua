AddCSLuaFile()
DEFINE_BASECLASS( "base_food_station2" )

ENT.Type = "anim"
ENT.PrintName = "base_bin"
ENT.Author = "StealthPaw"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = GAMEMODE.Name
ENT.Model = "models/props/cs_office/trash_can.mdl"
ENT.Material = ""
ENT.CanHold	= 1

if CLIENT then function ENT:Draw() self:DrawModel() end end
if SERVER then
	function ENT:DumpSound( ply ) self:EmitSound( "physics/cardboard/cardboard_cup_impact_hard"..math.random(1,3)..".wav" ) end
	function ENT:TouchFood( Name, foodEntity ) foodEntity:Remove() self:DumpSound() end
	function ENT:OnTouch( entity )
		if (self.NextDelete or 0) > CurTime() then return end self.NextDelete = CurTime()+1
		if (entity.Cooker or entity:GetClass() == "item_plate" ) and entity:HasFood() then
			if entity:GetClass() == "item_plate" and entity:GetSoup() then entity:RemoveAllFood() self:DumpSound() return end
			for k,v in pairs(entity:GetFoodTable() or {}) do
				entity:RemoveFood(v.Name)
				self:DumpSound()
				break
			end return
		end
	end
end