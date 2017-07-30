AddCSLuaFile()
DEFINE_BASECLASS( "item_spawner" )

ENT.Type = "anim"
ENT.PrintName = "Food Spawner 2"
ENT.Author = "StealthPaw"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category	= "overcooked"
ENT.Editable = true
ENT.RenderFoods = false

if SERVER then
	function ENT:Init()
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
		timer.Simple( 0.1, function() self:SetfoodType("Meat") end)
	end
end
if CLIENT then
	local NoMaterial = Material("icon32/hand_property.png", "noclamp smooth")
	function ENT:Draw()
		//self:DrawModel()
		local mat = NoMaterial
		if #self:GetFoodTable() >= 1 then
			local fT = FoodSystem:Food(self:GetFoodTable()[1].Name) or {}
			if fT.Material then mat = fT.Material end
		end
		local Wide = 200
		local Tall = 200
		cam.Start3D2D(self:GetPos(), self:GetAngles(), 0.05)
			surface.SetDrawColor(Color(255,255,255,255))
			surface.SetMaterial( mat )
			surface.DrawTexturedRect(-Wide/2, -Tall/2, Wide, Tall)
		cam.End3D2D()
	end
end