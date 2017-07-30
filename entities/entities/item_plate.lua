AddCSLuaFile()
DEFINE_BASECLASS( "base_food_station2" )

ENT.Type = "anim"
ENT.PrintName = "Serving Plate"
ENT.Author = "StealthPaw"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category	= "overcooked"
ENT.Model	= "models/foodnhouseholditems/servingplate.mdl"
ENT.Material	= ""
ENT.OCItem	= true
ENT.DropModelDistance = 0
ENT.CanHold	= 10

ENT.SoupPos	= {Scale = 0.027, Up = 0, Forward = 0, Left = 0}
ENT.SoupPosDepthScale = 1

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Soup" );
	self:NetworkVar( "Int", 1, "Dirty" );
end

function ENT:Init() self:SetSoup(false) self:SetDirty(0) end
if SERVER then
	function ENT:PhysicsCollide( data, phys )
		if ( data.Speed > 250 ) then self:EmitSound( Sound( "ambient/materials/platedrop1.wav" ) ) return end
		if ( data.Speed > 150 ) then self:EmitSound( Sound( "ambient/materials/dinnerplates"..math.random(1,3)..".wav" ) ) end
	end
	function ENT:Clean() self:SetDirty(0) self.Judged = false end
	function ENT:OnAdd( Name )
		self.Judged = false
		if self:GetSoup() then self:EmitSound( "ambient/water/rain_drip3.wav" ) end
		local Recipe = self:HasRecipe() or false
		if Recipe then self:RemoveAllFood() self:AddFood(Recipe, {PreparedBy = {"Recipe"}}) end
	end
	function ENT:Touch( entity )
		if (self.NextTouch or 0) > CurTime() then return end self.NextTouch=CurTime()+0.1
		if #self:GetFoodTable() >= self.CanHold then return end
		if entity.Cooker and entity:HasFood() then
			for k,v in pairs(entity:GetFoodTable() or {}) do
				if table.HasValue(v.PreparedBy or {}, "Boiler") then self:SetSoup(true) end
				self:AddFood(v.Name, v) self:OnAdd(v.Name) entity:RemoveFood(v.Name) break
			end return
		end
		if !self:GetSoup() and entity:GetClass() == self.FoodClass then
			if !entity.GetFood or !entity:GetFood() or entity:GetFood() == "" then return end
			if !table.HasValue(entity.PreparedBy or {}, "Processor") then return end
			self:AddFood(entity:GetFood(), entity) self:OnAdd(entity:GetFood()) entity:Remove()
		end
	end
	function ENT:Eat(diner)
		if !self:HasFood() then return end
		if self:GetSoup() then
			self:SetDirty(2)
			self:EmitSound( "overcooked/drink.mp3" )
		else
			self:SetDirty(1)
			self:EmitSound( "overcooked/eat.mp3" )
		end
		if IsValid(self.HeldBy) then
			OrderSystem:Receive(self, self.HeldBy)
		end
		
		
		self:SetSoup(false)
		self:RemoveAllFood()
	end
	function ENT:HasRecipe()
		for k,recipe in pairs(FoodSystem.Recipes or {}) do
			local f = 0
			local t = {}
			for k,v in pairs(recipe or {}) do
				if !table.HasValue(t, v) and self:HasFood(v) then table.insert(t, v) f = f + 1 end
			end
			if f == #recipe and #t == self:HasFood() then return k end
		end
		return false
	end
	function ENT:Use( ply )
		if !self:HasFood() then return end
	end
	
	function ENT:Think()
		if self.HasJudge and IsValid(self.HasJudge) then

		end
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
	local DirtyMaterials ={
		Material(GAMEMODE.Name.."/entities/dirty_dish_food.png", "noclamp smooth"),
		Material(GAMEMODE.Name.."/entities/dirty_dish_soup.png", "noclamp smooth")
	}
	function ENT:DrawDirt()
		if ( halo.RenderedEntity() == self ) then return end
		local selfAng = self:GetAngles()
		selfAng:RotateAroundAxis(selfAng:Up(), 90)
		selfAng:RotateAroundAxis(selfAng:Forward(), 0)
		local DirtyMaterial = DirtyMaterials[self:GetDirty()] or false
		if !DirtyMaterial then return end
		cam.Start3D2D(self:GetPos() + (selfAng:Up() * -0.2) , selfAng, 0.05)
			surface.SetDrawColor(Color(255,255,255,200))
			surface.SetMaterial( DirtyMaterial )
			surface.DrawTexturedRect(-125, -125, 250, 250)
		cam.End3D2D()
	end
	function ENT:Think()
		if !self:GetSoup() then self:RenderModels() end
	end
	function ENT:Draw()
		self:DrawModel()
		if (self:GetDirty() or 0) > 0 then self:DrawDirt() end
		if !self:HasFood() then return end
		if self:GetSoup() then self:DrawSoup() end
		if !self.Models or table.Count(self.Models) <= 0 then self:DrawIngredients() end
	end
end