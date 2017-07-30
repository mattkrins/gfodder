AddCSLuaFile()
DEFINE_BASECLASS( "base_anim" )

ENT.Type = "anim"
ENT.PrintName = "base_food_station2"
ENT.Author = "StealthPaw"
ENT.Spawnable = false
ENT.AdminSpawnable = true
ENT.Category	= "overcooked"
ENT.Model	= "models/props_c17/clock01.mdl"
ENT.Material	= "phoenix_storms/cube"
ENT.Station	= true
ENT.FoodClass	= "base_food"
ENT.CanHold	= 1
ENT.DropModelDistance	= 10
ENT.DropModelOffsetX	= 0
ENT.DropModelOffsetY	= 0
ENT.RenderFoods	= true
ENT.ShowFoodIcons = false
ENT.Combustable = true

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
function ENT:Init() end
function ENT:Initialize()
	self.table = {}
	if (SERVER) then
		self:SetModel(self.Model)
		self:SetMaterial(self.Material)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:DrawShadow(false)
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then phys:Wake() end
	end
	return self:Init()
end

function ENT:GetFoodTable() return self.table or {} end
function ENT:HasFood( Name )
	if !Name then if #self:GetFoodTable() <= 0 then return false else return #self:GetFoodTable() end end
	for k, v in pairs(self:GetFoodTable()) do
		if v.Name == Name then return v end
	end return false
end

if SERVER then
	util.AddNetworkString( "base_food_station2" )
	function ENT:Update() net.Start( "base_food_station2" ) net.WriteEntity( self ) net.WriteTable( self.table ) net.Broadcast() end
	function ENT:ReplaceFood( Old, New )
		if !self:HasFood(Old) then return false end
		self:RemoveFood( Old ) return self:AddFood( New )
	end
	function ENT:AddFood( Name, add )
		local food = { Name = Name }
		local transfer = {"PreparedBy","Prepared"}
		if add then for _, v in pairs(transfer) do if add[v] then food[v] = add[v] end end end
		local key = table.insert(self.table, food)
		self:Update()
		return key
	end
	function ENT:RemoveAllFood() self.table = {} self:Update() end
	function ENT:RemoveFood( Name )
		local food = self:HasFood(Name) or false
		if !food then return false end
		for k, v in pairs(self.table) do if v.Name == Name then table.remove(self.table, k) break end end
		self:Update()
	end
	function ENT:SpawnFood( Name )
		if !Name then return false end
		local foodEntity = ents.Create(self.FoodClass)
		foodEntity:SetPos(self:GetFoodPos())
		foodEntity:SetAngles(Angle(0,0,0))
		local model = FoodSystem:GetModel(Name)
		if model then foodEntity:SetModel(model) end
		foodEntity:SetRenderMode( RENDERMODE_TRANSALPHA )
		local food = self:HasFood(Name) or false
		self:OverCook( foodEntity, food )
		if food then
			local transfer = {"PreparedBy"}
			for _, v in pairs(transfer) do if food[v] then foodEntity[v] = food[v] end end
			self:RemoveFood(Name)
		end
		foodEntity:Spawn()
		foodEntity:Activate()
		foodEntity.Spawned = true
		foodEntity:SetFood(Name)
		return foodEntity
	end
	function ENT:OnUse(ply) end
	function ENT:Use( activator, caller )
		if !self:HasFood() then return end
		local ply = activator or caller if !ply:IsPlayer() then return end
		self:OnUse(ply)
	end
	function ENT:TouchFood( food, foodEntity ) end
	function ENT:CanTouchFood( food, foodEntity ) return true end
	function ENT:Touch( entity )
		if (self.NextTouch or 0) > CurTime() then return end self.NextTouch=CurTime()+0.1
		if !IsValid(entity) or entity:GetClass() != self.FoodClass then return end
		if !entity.GetFood or !entity:GetFood() or entity:GetFood() == "" then return end
		if #self:GetFoodTable() >= self.CanHold then return end
		if !self:CanTouchFood(entity:GetFood(), entity) then return end
		return self:TouchFood( entity:GetFood(), entity )
	end
	function ENT:MakeSound(path, modulate, volume)
		local p = 100
		if modulate or self.ModulateSound then p = math.Rand(90,110) end
		if isnumber(modulate) then p = modulate end
		self:EmitSound( path or self.Sound, volume or 75, p )
	end
	
	function ENT:Combust()
		if self:IsOnFire() then return end
		self:Ignite( 4 )
		timer.Simple( 3.9, function()
			if IsValid(self) and self:IsOnFire() then
				for _, v in pairs(ents.FindInSphere( self:GetPos(), 30 )) do if v.Combustable then v:Combust() end end
				timer.Simple( 1, function() if IsValid(self) then self:Combust() end end )
			end
		end )
	end
end

function ENT:PlayerWatching( ply )
	if !IsValid(ply) then return false end local tr = ply:GetEyeTrace()
	if tr and IsValid(tr.Entity) and tr.Entity == self then return true end
	return false
end

function ENT:OverCook( model, food )
	if !food or !food.Prepared or !IsValid(model) then return end
	if !model.OverCooked and food.Prepared > 120 then model.OverCooked = true model:SetColor(Color(200,200,200)) end
	if !model.Charcoaled and food.Prepared > 150 then model.Charcoaled = true model:SetColor(Color(25,25,25)) end
	if !model.Decimated and food.Prepared > 160 then model.Decimated = true  model:SetModel("models/props_junk/watermelon01_chunk02b.mdl") model:SetColor(Color(0,0,0)) end
	if !model.Cremated and food.Prepared > 170 then model.Cremated = true model:SetModel("models/props_junk/watermelon01_chunk02c.mdl") model:SetColor(Color(0,0,0)) end
end

function ENT:GetFoodPos()
	return self:GetPos()+(self:GetUp()*self.DropModelDistance)+(self:GetForward()*self.DropModelOffsetX)+(self:GetRight()*self.DropModelOffsetY)
end

if CLIENT then
	hook.Add( "PreDrawHalos", "OCBaseFoodPreDrawHalos", function()
		local tr = LocalPlayer():GetEyeTrace( )
		if !IsValid(tr.Entity) or !tr.Entity.OCItem then return end
		//if tr.Entity.Prepared then print(tr.Entity.Prepared) end
		if tr.HitPos:Distance(LocalPlayer():GetPos()) > 100 then return else halo.Add( {tr.Entity}, Color( 0, 255, 255 ), 2, 2, 2 ) end
	end )
	net.Receive( "base_food_station2", function() local station = net.ReadEntity() if IsValid(station) then station.table = net.ReadTable() or {} station:UpdateModels() end end )
	local NoMaterial = Material("icon16/cog_error.png", "noclamp smooth")
	function ENT:DrawIngredients()
		if ( halo.RenderedEntity() == self ) then return end
		local dist = self:GetPos():Distance(LocalPlayer():GetPos())
		if dist > 120 then return end
		local pos = self:GetFoodPos()
		pos.z = pos.z + 0
		pos = pos:ToScreen()
		local foods = self:GetFoodTable()
		cam.Start2D()
			for k,v in pairs(foods) do
				local fT = FoodSystem:Food(v.Name)
				local mat = NoMaterial
				if fT.Material then mat = fT.Material end
				surface.SetDrawColor(Color(255,255,255,255))
				surface.SetMaterial( mat )
				local width = 110
				local calcWidth = width-dist
				local size = math.Clamp(calcWidth,5,width)
				surface.DrawTexturedRect((pos.x-size)+(k*size)-((#foods*size)/2), pos.y, size, size)
			end
		cam.End2D()
	end
	function ENT:OnRemoved() end
	function ENT:OnRemove() self:CleanUp() self:OnRemoved() end
	function ENT:CleanUp() for k, v in pairs(self.Models or {}) do if IsValid(v) then v:Remove() end end end
	function ENT:OrganiseModels()
		local i = 0
		for k, v in pairs(self.Models or {}) do
			if IsValid(v) then v:SetPos(self:GetFoodPos()+Vector(0,0,i*2)) i=i+1 end
		end
	end
	function ENT:UpdateModels()
		self.Models = self.Models or {}
		for k, v in pairs(self:GetFoodTable() or {}) do if IsValid(self.Models[v.Name]) then self:OverCook( self.Models[v.Name], v ) end end
	end
	function ENT:RenderModels()
		self.Models = self.Models or {}
		for k, v in pairs(self.Models) do
			local f = self:HasFood(k) or false
			if !f then if IsValid(v) then v:Remove() end self.Models[k] = nil self:OrganiseModels() break end
			if !IsValid(v) then self.Models[k] = nil break end
		end
		for k, v in pairs(self:GetFoodTable()) do
			if IsValid(self.Models[v.Name]) then continue end
			local model = FoodSystem:GetModel(v.Name)
			if !model then continue end
			local CSM = ClientsideModel( model, RENDERMODE_TRANSALPHA )
			CSM:SetPos(self:GetFoodPos())
			CSM:SetParent(self)
			self:OverCook( CSM, v )
			CSM:DrawShadow(false)
			self.Models[v.Name] = CSM
			self:OrganiseModels()
			break
		end
	end
	function ENT:DoThink() end
	function ENT:Think()
		if self.RenderFoods then self:RenderModels() end
		self:DoThink()
	end
	function ENT:Draw()
		self:DrawModel()
		if !self:HasFood() then return end
		if self.ShowFoodIcons then self:DrawIngredients() end
	end
end
