AddCSLuaFile()
DEFINE_BASECLASS( "base_food_station2" )

ENT.Type = "anim"
ENT.PrintName = "Food Spawner"
ENT.Author = "StealthPaw"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category	= "overcooked"
ENT.Editable = true
ENT.RenderFoods = true

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "foodType", { KeyName = "foodtype", Edit = { type = "Generic", order = 1 } } )
	self:NetworkVarNotify( "foodType", self.ChangeFood )
end

if SERVER then
	function ENT:Init() timer.Simple( 0.1, function() self:SetfoodType("Meat") end) end

	function ENT:ChangeFood( varname, oldvalue, newvalue )
		if oldvalue == newvalue or newvalue == "" then return end
		if !FoodSystem:Food(newvalue) then return end
		self:RemoveAllFood()
		self:AddFood(newvalue)
	end
	
	function ENT:OnUse( ply )
		self:EmitSound( "items/ammo_pickup.wav" )
		local Dropped = self:SpawnFood(self:GetfoodType())
		if !IsValid(Dropped) then return end
		self.LastDropped = Dropped
	end
	function ENT:DoThink() end
	function ENT:Think()
		self:DoThink()
		if self:HasFood() then return end
		if IsValid(self.LastDropped) and self:GetPos():Distance(self.LastDropped:GetPos()) < 20 then return end
		self:AddFood(self:GetfoodType())
	end
end