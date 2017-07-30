AddCSLuaFile()
DEFINE_BASECLASS( "base_food_preparation" )

ENT.Type = "anim"
ENT.PrintName = "Cooking Pot"
ENT.Author = "StealthPaw"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category	= GAMEMODE.Name
ENT.Model	= "models/props_interiors/pot02a.mdl"
ENT.Material	= ""
ENT.Sound	= GAMEMODE.Name.."/entities/boiling.mp3"
ENT.ModulateSound = true
ENT.OCItem	= true
ENT.Cooker	= true
ENT.AutoPrepare	= true
ENT.DropFood = false
ENT.RenderFoods	= false
ENT.DropModelDistance	= 2
ENT.DropModelOffsetX	= 0
ENT.DropModelOffsetY	= -5
ENT.ShowFoodIcons	= true
ENT.PreparationRate = 1
ENT.PreparationType	= "Boiler"
ENT.CanHold	= 3
ENT.GUISpin	= -90
ENT.SmokeLength	= 20

ENT.SoupPos	= {Scale = 0.017, Up = 0, Forward = 0, Left = 5.5}
ENT.SoupPosDepthScale = 1

function ENT:Init() end
if SERVER then
	function ENT:CanTouchFood( Name, foodEntity )
		local fT = FoodSystem:Food(Name) or {}
		if !table.HasValue(foodEntity.PreparedBy or {}, "Processor") then return end
		if !fT.CanSoup or !fT.CanSoup then return false end
		return true
	end
end

if CLIENT then
	local SoupMaterial = Material( GAMEMODE.Name.."/entities/soup.png", "noclamp smooth" )
	local function LerpColor(frac,from,to) return Color( Lerp(frac,from.r,to.r), Lerp(frac,from.g,to.g), Lerp(frac,from.b,to.b), Lerp(frac,from.a,to.a) ) end
	function ENT:DrawSoup()
		if ( halo.RenderedEntity() == self ) then return end
		local newCol = Color(255,255,255,255)
		local foods = self:GetFoodTable()
		for _, v in pairs(foods) do
			local fT = FoodSystem:Food(v.Name)
			if !fT.Color then continue end
			newCol = LerpColor(0.5,newCol,fT.Color)
			if (v.Prepared or 0) > 150 then newCol = LerpColor(0.8,newCol,Color(0,0,0,255)) end
		end
		
		local selfAng = self:GetAngles()
		selfAng:RotateAroundAxis(selfAng:Up(), 90)
		selfAng:RotateAroundAxis(selfAng:Forward(), 0)
		local SoupPos = self.SoupPos or {}
		local Depth = (SoupPos.Forward or 0)*(self.SoupPosDepthScale or 0) * #foods
		cam.Start3D2D(self:GetPos() + (selfAng:Up() * Depth) + (selfAng:Right() * (SoupPos.Up or 0)) + (selfAng:Forward() * (SoupPos.Left or 0)), selfAng, (SoupPos.Scale or 0))
			surface.SetDrawColor(newCol)
			surface.SetMaterial( SoupMaterial )
			surface.DrawTexturedRect(-250, -250, 500, 500)
		cam.End3D2D()
	end
	function ENT:OnDraw() self:DrawSoup() end
end