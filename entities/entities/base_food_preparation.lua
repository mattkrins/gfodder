AddCSLuaFile()
DEFINE_BASECLASS( "base_food_station2" )

ENT.Type = "anim"
ENT.PrintName = "base_food_preparation"
ENT.Author = "StealthPaw"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = GAMEMODE.Name
ENT.Model = "models/props_vents/vent_large_grill001.mdl"
ENT.Material = "models/effects/vol_light001"
ENT.Sound = GAMEMODE.Name.."/entities/chop.mp3"
ENT.ModulateSound = true
ENT.DropModelDistance = 3
ENT.Cooker	= false
ENT.AutoPrepare	= false
ENT.DropFood = true
ENT.PreparationRate = 7
ENT.PreparationType	= "Processor"
ENT.CanHold	= 1
ENT.GUISpin	= 0
ENT.SmokeLength	= 2

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Preparing" );
	self:NetworkVar( "Int", 0, "Progress" );
end

if SERVER then
	function ENT:TouchFood( Name, foodEntity )
		if table.HasValue(foodEntity.PreparedBy or {}, self.PreparationType) then return end
		foodEntity:Remove()
		self:AddFood(Name, foodEntity)
		self:MakeSound(GAMEMODE.Name.."/player/pop_normal.mp3",true)
	end
	function ENT:Finish(food)
		local fT = FoodSystem:Food(food.Name) or {}
		if fT.WhenPrepared then
			self:AddFood(fT.WhenPrepared, food) self:RemoveFood(food.Name)
			self:HasFood(fT.WhenPrepared).Prepared = 100
		end
		if self.DropFood then self:DropFinished(fT.WhenPrepared or food.Name) end	
		if #self:GetFoodTable() <= 0 then self.Preparing = false self:SetProgress(0) end
	end
	function ENT:DropFinished(Name)
		if (self.NextDrop or 0) > CurTime() then return true end self.NextDrop=CurTime()+1
		self:SpawnFood(Name)
		self:MakeSound(GAMEMODE.Name.."/player/pop_normal.mp3",true)
		return true
	end
	function ENT:Prepare()
		local Mean = 0
		for k, v in pairs(self.table) do
			v.Prepared = v.Prepared or 0 
			v.Prepared = v.Prepared + self.PreparationRate or 1
			Mean = Mean + v.Prepared
			if v.Prepared >= 25 then
				v.PreparedBy = v.PreparedBy or {}
				if !table.HasValue(v.PreparedBy, self.PreparationType) then table.insert(v.PreparedBy, self.PreparationType) end
			end
			if v.Prepared >= 100 then self:Finish(v) end
		end
		local Progress = Mean/#self.table
		if self.Cooker and Progress > 100 then
			if (self.NextAlert or 0) < CurTime() then self:MakeSound("buttons/blip1.wav", math.Clamp(Progress,100,200) ) self.NextAlert = CurTime()+0.1 end
			if Progress > 160 and !self:IsOnFire() then self:MakeSound("ambient/fire/ignite.wav") self:Combust() end
		end
		self:SetProgress(Progress)
		self:MakeSound()
		self:Update()
	end
	function ENT:OnUse( ply )
		if self.AutoPrepare or self.Preparing then return end
		self.Preparing = ply
	end
	function ENT:Think()
		if !self:HasFood() then return end
		if self.AutoPrepare then
			if !self.Preparing and self:OnStove() then
				self.Preparing = true
				self:SetPreparing(true)
			elseif self.Preparing and !self:OnStove() then
				self.Preparing = false
				self:SetPreparing(false)
			end
		else
			if !IsValid(self.Preparing) or !self:PlayerWatching( self.Preparing ) then self.Preparing = false return end
		end
		if !self.Preparing then return end
		self:Prepare()
	end
end

local StoveModels = {
	"models/props_c17/furniturestove001a.mdl",
	"models/props_wasteland/kitchen_stove001a.mdl",
	"models/props_c17/FurnitureFireplace001a.mdl",
	"models/props_forest/stove01.mdl"
}
function ENT:OnStove()
	local tr = util.TraceLine( {start = self:GetPos(),endpos = self:GetPos() + (-self:GetUp() * 20),filter = { self }} )
	if !tr or !IsValid(tr.Entity) then return false end
	if tr.Entity.StoveTop then return tr.Entity end
	if table.HasValue(StoveModels,tr.Entity:GetModel()) then return tr.Entity end
	return false
end

function ENT:Init() self:SetPreparing(false) self:SetProgress(0) end
if CLIENT then
	local CuttingboardMaterial = Material( GAMEMODE.Name.."/entities/cuttingboard.png", "noclamp smooth" )
	hook.Add( "PostDrawOpaqueRenderables", "example", function()
		for _,v in pairs(ents.FindByClass( "base_food_preparation" )) do
			local selfAng = v:GetAngles()
			selfAng:RotateAroundAxis(selfAng:Up(), 90)
			selfAng:RotateAroundAxis(selfAng:Forward(), 0)
			local Wide = 500
			local Tall = 348
			cam.Start3D2D(v:GetPos() + (selfAng:Up() * 0.1), selfAng, 0.07)
				surface.SetDrawColor(Color(255,255,255,255))
				surface.SetMaterial( CuttingboardMaterial )
				surface.DrawTexturedRect(-Wide/2, -Tall/2, Wide, Tall)
			cam.End3D2D()
		end
	end )
	function ENT:Init()
		self.IsBoard = true
	end
	function ENT:DrawProgress()
		if ( halo.RenderedEntity() == self ) then return end
		local Progress = self:GetProgress() or 0
		local selfAng = self:GetAngles()
		selfAng:RotateAroundAxis(selfAng:Up(), 90+(self.GUISpin or 0))
		selfAng:RotateAroundAxis(selfAng:Forward(), 90)
		local Wide = 300
		local Tall = 40
		local burnt = false
		cam.Start3D2D(self:GetPos() + (selfAng:Up() * -3) + (selfAng:Right() * -15) + (selfAng:Forward() * 0), selfAng, 0.07)
			draw.RoundedBox( 0, -Wide/2-2, -2, Wide+4, Tall+4, Color( 0, 0, 0, 100 ) )
			draw.RoundedBox( 0, -Wide/2, 0, Wide, Tall, Color( 224, 229, 255, 255 ) )
			draw.RoundedBox( 0, -Wide/2, 0, math.Clamp((Progress*Wide)/100,0,Wide), Tall, Color( 124, 255, 109, 255 ) )
			if DEVELOPER_MODE then
				local Mean = 0
				for k, v in pairs(self:GetFoodTable()) do
					Mean = Mean + (v.Prepared or 0)
					draw.SimpleTextOutlined( v.Name..": "..(v.Prepared or 0).."%", "Trebuchet18", 0, -(k*12)-20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black )
					if (v.Prepared or 0) > 110 then burnt = Color( 255, 255, 109, 255 ) end
					if (v.Prepared or 0) > 150 then burnt = Color( 255, 109, 109, 255 ) end
				end
				draw.SimpleTextOutlined( "Mean: "..Mean/#self:GetFoodTable().."%", "Trebuchet18", 0, -15, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black )
			end
			if burnt then draw.RoundedBox( 0, -Wide/2, 0, math.Clamp((Progress*Wide)/100,0,Wide), Tall, burnt ) end
		cam.End3D2D()
	end
	function ENT:DrawSmoke()
		local pos = self:GetFoodPos()
		if !IsValid(self.Emitter) then self.Emitter = ParticleEmitter( pos ) end
		local particle = self.Emitter:Add( "particles/smokey", pos )
		particle:SetVelocity( Vector( 0, 0, 1 ) * self.SmokeLength )
		particle:SetDieTime( 1 )
		particle:SetStartSize( math.Rand( 1, 8 ) )
		particle:SetEndSize( math.Rand( 20, 40 ) )
		if self.OverCooked then
			particle:SetStartAlpha( math.Rand( 10, 40 ) )
			particle:SetColor( 0, 0, 0 )
		else
			particle:SetStartAlpha( math.Rand( 1, 4 ) )
			particle:SetColor( 255, 255, 255 )
		end
	end
	function ENT:DoThink()
		if self.Cooker and self:GetPreparing() then self:DrawSmoke() end
	end
	function ENT:OnDraw() end
	function ENT:Draw()
		if !self.IsBoard then self:DrawModel() end
		if !self:HasFood() then return end
		self:DrawProgress()
		self:OnDraw()
		if self.ShowFoodIcons then self:DrawIngredients() end
	end
end
