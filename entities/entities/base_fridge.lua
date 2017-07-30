AddCSLuaFile()
DEFINE_BASECLASS( "item_spawner" )

ENT.Type = "anim"
ENT.PrintName = "base_fridge"
ENT.Author = "StealthPaw"
//ENT.Model	= "models/ptejack/props/fridge/pj_fridge.mdl"
ENT.Model	= "models/props_interiors/refrigerator01a.mdl"
ENT.Material	= ""
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category	= "overcooked"
ENT.Editable = false
ENT.RenderFoods = false
ENT.DropModelDistance = 0
ENT.ShelveDistances = {12,0,-12}

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "foodType", { KeyName = "foodtype", Edit = { type = "Generic", order = 1 } } )
	self:NetworkVar( "Bool", 0, "Open" );
end

if SERVER then
	function ENT:Init()
		self:SetOpen(false)
		self:SetMoveType(MOVETYPE_NONE)
	end
end

function ENT:SpawnFunction( ply, tr, ClassName )
	if (SERVER) then
		if ( !tr.Hit ) then return end
		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 41 )
		ent:Spawn()
		ent:Activate()
		return ent
	end
end

if SERVER then
	util.AddNetworkString( "base_fridge" )
	net.Receive( "base_fridge", function()
		local fridge = net.ReadEntity()
		local food = net.ReadString() or false if !food or food == "" then food = false end
		if IsValid(fridge) then fridge:Open(food or false) end
	end )
	function ENT:Open(foodName)
		if !foodName then return self:Close() end
		if self:GetOpen() then self:Close() timer.Simple( 0.5, function() if IsValid(self) then self:Open(foodName) end end ) return end
		self:EmitSound( "doors/door1_move.wav", 75 )
		self:SetfoodType(foodName)
		self:SetOpen(true)
		self:OnUse()
	end
	function ENT:Close(act, ply)
		if !self:GetOpen() then return end
		self:EmitSound( "ambient/materials/shuffle1.wav", 75 )
		self:SetOpen(false)
		self.LastUser = false
		if IsValid(self.LastDropped) and self:GetPos():Distance(self.LastDropped:GetPos()) < 50 then self.LastDropped:Remove() else self.LastDropped = false end
	end
	function ENT:Use(act, ply)
		if (self.NextUse or 0) >= CurTime() then return end self.NextUse = CurTime() + 1
		self:Close()
		net.Start( "base_fridge" ) net.WriteEntity( self ) net.Send(ply)
		self.LastUser = ply
	end
	function ENT:OnUse()
		self.DropModelDistance = table.Random(self.ShelveDistances)
		//self.DropModelDistance = 11
		local Dropped = self:SpawnFood(self:GetfoodType())
		if !IsValid(Dropped) then return end
		self.LastDropped = Dropped
	end
	function ENT:Think()
		if self.LastDropped then
			if !IsValid(self.LastDropped) then self:Close() return end
			if IsValid(self.LastDropped) and self:GetPos():Distance(self.LastDropped:GetPos()) > 50 then self:Close() end
		end
		if self.LastUser then
			if !IsValid(self.LastUser) then self.LastUser = false self:Close() return end
			if self:GetPos():Distance(self.LastUser:GetPos()) > 100 then self.LastUser:ConCommand( "base_fridge_close" ) self.LastUser = false self:Close() end
		end
	end
end

if CLIENT then
	function ENT:Init()
		self.OnRemoved = function(self)
			if IsValid(self.topDoor) then self.topDoor:Remove() end
			if IsValid(self.bottomDoor) then self.bottomDoor:Remove() end
		end
		local topDoor = ClientsideModel( "models/props_interiors/refrigeratordoor02a.mdl", RENDERMODE_TRANSALPHA )
		topDoor:DrawShadow(false)
		topDoor:SetParent(self)
		topDoor:SetPos(self:GetPos()+(self:GetUp()*29)+(self:GetForward()*15))
		topDoor:SetAngles(self:GetAngles())
		self.topDoor = topDoor
		local bottomDoor = ClientsideModel( "models/props_interiors/refrigeratordoor01a.mdl", RENDERMODE_TRANSALPHA )
		bottomDoor:DrawShadow(false)
		bottomDoor:SetParent(self)
		bottomDoor:SetPos(self:GetPos()+(self:GetUp()*-7)+(self:GetForward()*15))
		bottomDoor:SetAngles(self:GetAngles())
		self.bottomDoor = bottomDoor
		self.isOpen = false
	end
	function ENT:DoThink()
		if self:GetOpen() then
			if self.isOpen then return end
			self.isOpen = true
			if IsValid(self.bottomDoor) then
				self.bottomDoor:SetPos(self:GetPos()+(self:GetUp()*-7)+(self:GetForward()*32)+(self:GetRight()*14))
				local selfAng = self:GetAngles()
				selfAng:RotateAroundAxis(selfAng:Up(), -90)
				self.bottomDoor:SetAngles(selfAng)
			end
		else
			if !self.isOpen then return end
			self.isOpen = false
			if IsValid(self.bottomDoor) then
				self.bottomDoor:SetPos(self:GetPos()+(self:GetUp()*-7)+(self:GetForward()*15))
				self.bottomDoor:SetAngles(self:GetAngles()+Angle( 0, 0, 0 ))
			end
		end
	end
	local FridgeMenu
	function ENT:Close(food)
		if IsValid(FridgeMenu) then FridgeMenu:Remove() end
		net.Start( "base_fridge" )
			net.WriteEntity( self )
			if food then net.WriteString( food ) end
		net.SendToServer()
	end
	function ENT:Open()
		if IsValid(self) then self:Close() else if IsValid(FridgeMenu) then FridgeMenu:Remove() end end
		local Frame = vgui.Create( "DPanel" )
		FridgeMenu = Frame
		Frame:SetSize( ScrW(), ScrH() )
		Frame:MakePopup()
		Frame:SetKeyboardInputEnabled( false )
		Frame.Paint = function ( s, w, h )	if !FridgeMenu or !IsValid(FridgeMenu) then s:Remove() end end
		
		local Overlay = vgui.Create( "DButton", Frame )
		Overlay:SetSize( Frame:GetWide(), Frame:GetTall() )
		Overlay:SetPos( 0, 0 )
		Overlay:SetText( "" )
		Overlay:SetCursor( "arrow" )
		Overlay.Paint = function ( s, w, h ) end
		Overlay.DoClick = function ( s, w, h ) if IsValid(self) then self:Close() else if IsValid(FridgeMenu) then FridgeMenu:Remove() end end end
				
		local FoodsList	= vgui.Create( "DIconLayout", Overlay )
		FoodsList:SetSize( Overlay:GetWide(), Overlay:GetTall()/4 )
		FoodsList:Center()
		FoodsList:SetSpaceY( 0 )
		FoodsList:SetSpaceX( 5 )
		
		local size = FoodsList:GetTall()
		local foods = {"Meat","Tomato","Lettuce","Bread"}
		for k, v in pairs(foods) do
			local fT = FoodSystem:Food(v)
			if !fT.Material then continue end
			local foodButton = FoodsList:Add( "DButton" )
			foodButton.Material = fT.Material
			foodButton:SetText( "" )
			foodButton:SetSize( size, size )
			foodButton.Paint = function ( s, w, h )
				if s:IsHovered() then draw.RoundedBox( 32, 0, 0, w, h, Color( 50, 50, 50, 50 ) ) end
				surface.SetDrawColor(Color(255,255,255,255))
				surface.SetMaterial( s.Material )
				surface.DrawTexturedRect(5, 5, w-10, h-10)
			end
			foodButton.DoClick = function ( s, w, h )
				if IsValid(self) then self:Close(v) else if IsValid(FridgeMenu) then FridgeMenu:Remove() end end
			end
		end
		FoodsList:SetSize( (#FoodsList:GetChildren() or 0)*(size+5), Overlay:GetTall()/4 )
		FoodsList:Center()
		if (#FoodsList:GetChildren() or 0) <= 0 then surface.PlaySound( "buttons/button8.wav" ) self:Close() end
	end
	net.Receive( "base_fridge", function() local fridge = net.ReadEntity() if IsValid(fridge) then fridge:Open() end end )
	concommand.Add("base_fridge_close", function() if IsValid(FridgeMenu) then FridgeMenu:Remove() end end)
end