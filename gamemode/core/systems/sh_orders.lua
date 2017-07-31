OrderSystem = {}
OrderSystem.MaxOrders = 5
if SERVER then
	util.AddNetworkString( "Order.Net" )
	OrderSystem.Sync = function( self, ply ) net.Start( "Order.Net" ) net.WriteTable(ply.Orders or {}) net.Send(ply) end
	if DEVELOPER_MODE then concommand.Add("OrderSystem.Add", function(ply, cmd, args) if !ply:IsAdmin() then return end OrderSystem:Add(args[1],ply,20) end) end
	OrderSystem.Add = function( self, Name, ply, Time )
		local foodTable = FoodSystem:Food(Name)
		if !foodTable or !IsValid(ply) then return false end
		ply.Orders = ply.Orders or {}
		local key = table.insert(ply.Orders, {
			Name = Name,
			Time = Time or 5,
		})
		ply.Orders[key].Decay = CurTime() + ply.Orders[key].Time
		self:Sync(ply)
	end
	OrderSystem.Clear = function( self ) for _,ply in pairs(player.GetAll()) do ply.Orders = {} self:Sync(ply) end end
	OrderSystem.Remove = function( self, ply, Key )
		if !IsValid(ply) or !Key then return false end
		table.remove(ply.Orders or {}, Key)
		self:Sync(ply)
	end
	OrderSystem.Finish = function( self, ply, Key )
		ply.Orders[Key].Closing = true
		ply.Orders[Key].Accepted = true
		ply.Orders[Key].Decay = CurTime()+3
		self:Sync(ply)
	end
	OrderSystem.Validate = function( self, Name, ply )
		for k,v in pairs(ply.Orders or {}) do
			if v.Name == Name then
				self:Finish(ply, k)
				GamemodeSystem:GiveScore(ply)
				return true
			end
		end return false
	end
	OrderSystem.Think = function( self )
		for _,ply in pairs(player.GetAll()) do
			for k,v in pairs(ply.Orders or {}) do
				if !v.Closing and (v.Decay or 0) < CurTime() then ply.Orders[k].Closing = true self:Sync(ply) end
				if (v.Decay or 0) < CurTime()-1 then self:Remove(ply, k) end
			end
		end
	end
	hook.Add( "Think", "Order.Think", function() OrderSystem:Think() end)
else
	net.Receive( "Order.Net", function()
		local NewTab = net.ReadTable() or {}
		for k,v in pairs(LocalPlayer().Orders or {}) do
			if k == "Up" then NewTab[k] = v end
		end
		LocalPlayer().Orders = NewTab
		for k,v in pairs(LocalPlayer().Orders or {}) do
			local fT = FoodSystem:Food(v.Name)
			if !v.Material and fT.Material then v.Material = fT.Material end
			if v.Recipe then continue end
			if fT.Recipe then
				local Recipe = {}
				for _,n in pairs(fT.Recipe) do
					local fT = FoodSystem:Food(n)
					if fT.Material then table.insert(Recipe, fT.Material) end
				end
				if #Recipe > 0 then v.Recipe = table.Copy(Recipe) end
			end
		end
	end )
end