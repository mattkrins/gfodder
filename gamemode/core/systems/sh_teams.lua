Teams = Teams or {table = {}}
Teams.team = function( self, Name ) return self.table[Name] or false end
Teams.score = function( self, Name)
	local Team = self:team(Name) or false
	if !Team then return 0 end
	return (Team.Score or 0)
end
if SERVER then
	util.AddNetworkString( "Team.Net" )
	Teams.Reset = function( self ) self.table = {} self:Sync() end
	Teams.SaveResults = function( self) for t, p in pairs(self.table) do for _, v in pairs(p.Players or {}) do v:ConCommand("GetResults") end end end
	Teams.Sync = function( self ) net.Start( "Team.Net" ) net.WriteTable(self.table) net.Broadcast() end
	Teams.player = function( self, ply ) for t, p in pairs(self.table) do if table.HasValue(p.Players, ply) then return t end end return false end
	Teams.include = function( self, Name, ply )
		self.table[Name] = self.table[Name] or {Players={},Name=Name,Score=0}
		if !table.HasValue(self.table[Name].Players, ply) then table.insert(self.table[Name].Players, ply) end
		self:Sync()
	end
	Teams.allPlayers = function( self, ignore )
		local players = {}
		for t, p in pairs(self.table) do
			if ignore and table.HasValue(ignore, t) then continue end
			for _, v in pairs(p.Players or {}) do
				table.insert(players, v)
			end
		end return players
	end
	Teams.playerScore = function( self, ply, score)
		local teamName = self:player(ply) or false
		PrintTable(self.table)
		if !teamName then return end
		local give = score or 100
		self:AddScore(teamName, give)
	end
	Teams.AddScore = function( self, Name, score)
		local Team = self:team(Name) or false
		if !Team then return end
		Team.Score = (Team.Score or 0) + score
		self:Sync()
	end
	Teams.GetWinner = function( self, Name, score)
		local scores = 0
		local count = 0
		local winning = false
		for t, p in pairs(self.table) do
			if (p.Score or 0) > scores then count = count+1 scores = (p.Score or 0) winning = t end
		end if !winning then return false end
		if table.Count(self.table) == count then return "DRAW" else return winning end
	end
	Teams.ShowScores = function( self )
		local winner = self:GetWinner() or false
		if !winner then return end
		for t, p in pairs(self.table) do
			for _, v in pairs(p.Players or {}) do
				if !IsValid(v) then continue end
				if winner == "DRAW" then
					v:ConCommand( "WinScreen 1 "..t )
				elseif winner == t then
					v:ConCommand( "WinScreen 2 "..t )
				else
					v:ConCommand( "WinScreen 0 "..t )
				end
			end
		end
	end
	concommand.Add("ShowScores", function(ply, cmd, args) if ply:IsAdmin() then Teams:ShowScores() end end)
else
	net.Receive( "Team.Net", function()
		Teams.table = net.ReadTable() or {}
		for _, v in pairs(player.GetAll()) do v.teamID = false end
		for t, p in pairs(Teams.table) do
			for _, v in pairs(p.Players or {}) do
				v.teamID = t
			end
		end
	end )
	concommand.Add("GetResults", function(ply, cmd, args)
		Teams.results = table.Copy(Teams.table)
	end)
	local WinScreen
	concommand.Add("WinScreen", function(ply, cmd, args)
		if IsValid(WinScreen) then WinScreen:Remove() end
		WinScreen = vgui.Create( "DPanel" )
		WinScreen:SetSize( ScrW(), ScrH() )
		WinScreen.Paint = function ( s, w, h )	if !WinScreen then s:Remove() end end
		local overlay = vgui.Create( "DPanel", WinScreen )
		overlay:SetSize( WinScreen:GetWide(), WinScreen:GetTall() )
		overlay:SetAlpha( 0 )
		overlay:AlphaTo( 150, 1, 0, function(t,s)
			s:AlphaTo( 0, 1, 3)
		end)
		local function MakeLayer(h, y, d, p)
			local lay = vgui.Create( "DPanel", WinScreen )
			lay.Paint = p
			lay:SetSize( WinScreen:GetWide(), h )
			lay:SetPos( 50, WinScreen:GetTall()-lay:GetTall()-y )
			lay:SetAlpha( 0 )
			lay:AlphaTo( 255, 1, d )
			local x, y = lay:GetPos()
			lay:MoveTo( x+100, y, 4, d, -1, function(t,s)
				local x, y = s:GetPos()
				s:MoveTo( x+500, y, 1, 0 )
				s:AlphaTo( 0, 0.5, 0 )
			end) return lay
		end
		
		MakeLayer(80, 200, 0, function(s, w, h)
			draw.SimpleTextOutlined( "YOUR TEAM", Font( h, 1900, true ), 0, h/2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color( 0, 0, 0, 150 ) )
		end)
		
		local teamName = args[2] or ""
		MakeLayer(100, 120, 0.1, function(s, w, h)
			draw.SimpleTextOutlined( "TEAM "..teamName, Font( h, 1900, true ), 0, h/2, Color( 255, 211, 43, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color( 0, 0, 0, 150 ) )
		end)
		
		local WinCol = Color(138,255,43,255)
		local WinText = "WINS"
		if !args or !args[1] or (tonumber(args[1]) or 0) < 1 then
			WinText = "LOST"
			WinCol = Color(255,58,43,255)
			surface.PlaySound(GAMEMODE.Name.."/effects/failtrumpet.mp3")
		elseif (tonumber(args[1]) or 0) <= 1 then
			WinText = "DRAWED"
			WinCol = Color(151,193,255,255)
			surface.PlaySound(GAMEMODE.Name.."/effects/failtrumpet.mp3")
		else
			surface.PlaySound(GAMEMODE.Name.."/effects/bigwin.mp3")
		end
		MakeLayer(50, 80, 0.5, function(s, w, h)
			draw.SimpleTextOutlined( WinText, Font( h, 1900, true ), 0, h/2, WinCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color( 0, 0, 0, 150 ) )
		end)
		overlay.Paint = function ( s, w, h )
			Derma_DrawBackgroundBlur( s, 1 )
			draw.RoundedBox( 0, 0, 0, w, h, Color( WinCol.r, WinCol.g, WinCol.b, 5 ) )
		end
		
		timer.Simple( 5, function() if IsValid(WinScreen) then WinScreen:Remove() end end )
	end)


end