OrderSystem = {}
OrderSystem.MaxOrders = 5
if SERVER then
	util.AddNetworkString( "OrderSystemNet" )
	
	OrderSystem.Generate = function( self, ply, tools )
		if !IsValid(ply) or !tools then return false end
	end
	OrderSystem.Receive = function( self, entity, ply )
		if !IsValid(ply) or !IsValid(entity) then return false end
		for k,v in pairs(ply.Orders or {}) do
			if !entity:HasFood( v.Name ) then continue end
			GamemodeSystem:ForfillOrder(ply, v.Name)
			self:Remove(v.UNID, ply, true)
			entity:RemoveFood( false, true )
			break
		end
	end
	OrderSystem.Update = function( self, ply, removing, success )
		net.Start( "OrderSystemNet" )
			net.WriteTable( ply.Orders or {} )
			if removing then
				net.WriteString( removing )
				net.WriteBool( success or false )
			end
		net.Send(ply)
	end
	OrderSystem.Remove = function( self, UNID, ply, success )
		if !IsValid(ply) or !UNID then return false end
		for k,v in pairs(ply.Orders or {}) do
			if !v.UNID or (v.UNID == UNID) then table.remove(ply.Orders or {}, k) end
		end
		self:Update(ply, UNID, success)
	end
	OrderSystem.Clear = function( self )
		for _,ply in pairs(player.GetAll()) do
			for _,v in pairs(ply.Orders or {}) do self:Update(ply, v.UNID) end
			ply.Orders = {}
		end
	end
	OrderSystem.Add = function( self, Name, ply, Time )
		//if #Orders >= self.MaxOrders then return false end
		local foodTable = FoodSystem:Food(Name)
		if !foodTable or !IsValid(ply) then return false end
		ply.Orders = ply.Orders or {}
		local key = table.insert(ply.Orders, {
			Name = Name,
			Time = Time or 5,
		})
		ply.Orders[key].Decay = CurTime() + ply.Orders[key].Time
		ply.Orders[key].UNID = key..Name..math.Rand( 0, 999 )
		self:Update(ply)
	end
	concommand.Add("OrderSystem_Add", function(ply) OrderSystem:Add("Tomato Soup", ply, 5) end)
	
	OrderSystem.Think = function( self )
		if (self.NextThink or 0) >= CurTime() then return end
		self.NextThink = CurTime() + 0
		for _,ply in pairs(player.GetAll()) do
			for k,v in pairs(ply.Orders or {}) do
				if (v.Decay or 0) < CurTime() then self:Remove(v.UNID, ply) end
			end
		end
	end
	hook.Add( "Think", "OCOrderSystemThink", function() OrderSystem:Think() end)
end

if SERVER then return end
local Orders = {}
local width = 200
local function UpdateOrders()
	for k,v in pairs(Orders or {}) do
		if IsValid(v) then
			v:MoveTo( (k*width)-width, 0, 1, 1.2,0.5 )
		else
			table.remove(Orders, k)
		end
	end
end
local function RemoveOrder(UNID, c)
	for k,v in pairs(Orders or {}) do
		if !v.UNID or (v.UNID == UNID) then
			if IsValid(v) then v:Clear(c) end
			table.remove(Orders or {}, k) continue
		end
		if !IsValid(v) then table.remove(Orders or {}, k) end
	end
	UpdateOrders()
end
local function LerpColor(frac,from,to) return Color( Lerp(frac,from.r,to.r), Lerp(frac,from.g,to.g), Lerp(frac,from.b,to.b), Lerp(frac,from.a,to.a) ) end
local function AddOrder(Key, Order)
	local foodTable = FoodSystem:Food(Order.Name) or {}
	local Recipe = {}
	if foodTable.Recipe then
		for _,v in pairs(foodTable.Recipe) do
			local fT = FoodSystem:Food(v)
			if fT.Material then table.insert(Recipe, fT.Material) end
		end
	end
	
	local oFrame, sPanel, iPanel
	oFrame = vgui.Create( "DPanel" )
	oFrame.UNID = Order.UNID
	local unKey = table.insert(Orders, oFrame)
	oFrame:SetSize( width, 200 )
	oFrame:SetPos( ScrW(), 0 )
	oFrame:MoveTo( (Key*width)-width, 0, 1, 0, 0.1 )
	oFrame.Paint = function(s, w, h)
		if ((#Orders <= 0)) and IsValid(s) then s:Clear() end
		if !Orders[unKey] and IsValid(s) then RemoveOrder(s.UNID) s:Clear() end
	end
	oFrame.Clear = function(s, c) sPanel:Clear(c) end
	sPanel = vgui.Create( "DPanel", oFrame )
	sPanel:SetPos( 10, -oFrame:GetTall()/1.1 )
	sPanel:SetSize( oFrame:GetWide()-20, oFrame:GetTall()/1.1 )
	sPanel.Paint = function(s, w, h)
		draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 100 ) )		
		if #Recipe > 0 then
			surface.SetDrawColor(color_white)
			for k,v in pairs(Recipe) do
				local lH = 50
				local lX = (w/2)+(#Recipe*(lH/2))-(k*lH)
				surface.SetMaterial( v )
				surface.DrawTexturedRect(lX, h-lH-15, lH, lH)
			end
		end
	end
	sPanel.Drop = function(s)
		local x, y = s:GetPos()
		local w, h = s:GetSize()
		s:MoveTo( x, y+h, 1, 0, 0.1)
	end
	sPanel.Clear = function(s, c)
		if !IsValid(oFrame) then return end
		if oFrame.Closing then return end
		oFrame.Closing = true
		sPanel.Closing = true
		iPanel.Closing = true
		if c then iPanel.CloseColor = Color(223,255,191,255) iPanel.BarColor = Color(18, 106, 7,255) end
		local x, y = s:GetPos()
		local w, h = s:GetSize()
		s:MoveTo( x, y-(h/2), 1, 0, 0.5, function()
			oFrame:AlphaTo( 0, 0.2, 0, function()
				oFrame:Remove()
			end)
		end)
	end
	if #Recipe > 0 then sPanel:Drop() end
	iPanel = vgui.Create( "DPanel", oFrame )
	iPanel.Name = Order.Name
	iPanel.UNID = Order.UNID
	iPanel.Time = Order.Time or 10
	iPanel.Decay = CurTime()+iPanel.Time
	iPanel.Lerp = 1
	iPanel.CloseColor = Color(255,178,178,255)
	iPanel.BarColor = Color(181, 0, 9,255)
	iPanel:SetPos( 5, 0 )
	iPanel:SetSize( oFrame:GetWide()-10, oFrame:GetTall()/2 )
	local BGLerp = 0
	iPanel.Paint = function(s, w, h)
		if s.Closing then BGLerp = math.Clamp(BGLerp + 0.1,0,1) end
		s.Lerp = math.Clamp(((s.Decay or CurTime()) - CurTime())/(s.Time or 10),0,1)
		draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 100 ) )
		draw.RoundedBox( 8, 1, 1, w-2, h-2, LerpColor(BGLerp,Color( 255, 255, 255, 255 ),s.CloseColor) ) // white bg
		draw.RoundedBox( 0, 1, 0, w-2, 20, Color( 82, 82, 82, 255 ) ) // grey bar
		draw.RoundedBox( 0, 1, 0, s.Lerp*w-2, 20, LerpColor(s.Lerp,s.BarColor,Color( 18, 106, 7, 255 )) ) // time bar
		if foodTable.Material then
			surface.SetDrawColor(color_white)
			surface.SetMaterial( foodTable.Material )
			surface.DrawTexturedRect(w/2-((h-5)/2), 0, h-5, h-5)
		end
		if s.Lerp <= 0 then RemoveOrder(s.UNID) end
	end
end

net.Receive( "OrderSystemNet", function()
	for k,v in pairs(net.ReadTable() or {}) do if !Orders[k] then AddOrder(k, v) end end
	local remove = net.ReadString() or false
	if remove and remove!="" then RemoveOrder(remove, net.ReadBool() or false) end
end )


