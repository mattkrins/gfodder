GamemodeSystem = {Clock = {},Music={}}
if CLIENT then
	local function LerpColor(frac,from,to) return Color( Lerp(frac,from.r,to.r), Lerp(frac,from.g,to.g), Lerp(frac,from.b,to.b), Lerp(frac,from.a,to.a) ) end
	local pulse = 0
	local timeLimit = 1
	concommand.Add("PulseScore", function(ply, cmd, args) pulse = 1 end)
	concommand.Add("UpdateTime", function(ply, cmd, args) if !args[1] then return end timeLimit = tonumber(args[1]) end)
	hook.Add( "HUDPaint", "GamemodeSystem.HUDPaint", function()
		if DEVELOPER_MODE then draw.SimpleTextOutlined( "Active GM: "..GamemodeSystem:GetActive(), "CloseCaption_Bold", ScrW()-20, 20, Color( 255, 255, 255, 200 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 2, Color( 0, 0, 0, 50 ) ) end
		local Mode = GamemodeSystem:GetMode() or false
		if Mode then if Mode.HUDPaint then Mode:HUDPaint() end end
		if GetGlobalBool( "GMShowCoins", false ) then
			//local score = LocalPlayer():GetNWFloat( 'score', 0 )
			local score = Teams:score(LocalPlayer().teamID)
			draw.SimpleTextOutlined( "SCORE", Font( 40, 900, false ), 10, ScrH()-60, Color( 255, 255, 255, 100 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 1, Color( 0, 0, 0, 50 ) )
			draw.SimpleTextOutlined( score, Font( 60, 900, false ), 10, ScrH()-5, LerpColor(pulse,Color( 255, 237, 104, 100 ),Color( 0, 237, 104, 220 )), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 1, LerpColor(pulse,Color( 0, 0, 0, 50 ),Color( 0, 50, 0, 200 )) )
			if pulse > 0 then pulse = math.Clamp(pulse - 0.001,0,1) end
			if pulse > 0 then
				surface.SetFont( Font( 60, 900, false ) )
				local width = surface.GetTextSize( score )
				draw.SimpleTextOutlined( "+", Font( 40, 900, false ), 15+width, ScrH()-15, LerpColor(pulse,Color( 255, 237, 104, 0 ),Color( 0, 237, 104, 220 )), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 1, Color( 0, 0, 0, 0 ) )
			end
		end
		if GetGlobalBool( "GMShowTimer", false ) then
			local time = (GamemodeSystem.Clock:Remaining() or 0) if time < 0 or time > timeLimit then time = 0 end
			local niceTime = string.FormattedTime( time, "%02i:%02i" )
			local timeLeft = math.Clamp(time/(timeLimit or 1),0,1)
			draw.SimpleTextOutlined( "TIME", Font( 40, 900, false ), ScrW()-10, ScrH()-60, Color( 255, 255, 255, 100 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, Color( 0, 0, 0, 50 ) )
			draw.SimpleTextOutlined( niceTime, Font( 60, 900, false ), ScrW()-10, ScrH()-5, LerpColor(timeLeft,Color( 234, 70, 68, 200 ),Color( 255, 255, 255, 100 )), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, Color( 0, 0, 0, 50 ) )
		end
		local wide = 200
		local high = 100
		for k,v in pairs(LocalPlayer().Orders or {}) do
			local x = (k*(wide+10))-wide
			if v.Recipe then
				if v.Closing then v.Up = (v.Up or 0) - 0.5 end
				draw.RoundedBox( 18, x+15, 70+(v.Up or 0), wide-20, high, Color(0,0,0,200) )
				surface.SetDrawColor(color_white)
				for r,m in pairs(v.Recipe) do
					local lH = 50+(v.Up or 0)
					local lX = (wide/2)+(#v.Recipe*(lH/2))-(r*lH)
					surface.SetMaterial( m )
					surface.DrawTexturedRect(x+lX+5, high+5, lH, lH)
				end
			end
			local lerp = (v.Decay-CurTime())/v.Time
			local bgCol = Color(255,255,255,255)
			if v.Closing then bgCol = Color(255,150,150,255) end
			if v.Accepted then bgCol = Color(155,255,150,255) end
			draw.RoundedBox( 18, x+5, 0, wide, high, bgCol )
			draw.RoundedBox( 0, x+5, 0, wide, 20, Color( 82, 82, 82, 255 ) )
			draw.RoundedBox( 0, x+5, 0, lerp*wide-2, 20, LerpColor(lerp,Color(255, 79, 79,255),Color( 147, 255, 117, 255 )) )
			if v.Material then
				surface.SetDrawColor(color_white)
				surface.SetMaterial( v.Material )
				surface.DrawTexturedRect(x+5+wide/2-((high-5)/2), 0, high-5, high-5)
			end
		end
	end )
end
GamemodeSystem.Modes = {}
GamemodeSystem.Add = function( self, Mode )
	if !Mode or !Mode.Name then return false end
	self.Modes[Mode.Name] = table.Copy(Mode)
	if CLIENT then
		if Mode.Material then self.Modes[Mode.Name].Material = Material(Mode.Material, "noclamp smooth") end
		if file.Exists( "gamemodes/"..GM.Name.."/content/materials/"..GM.Name.."/gui/gamemodes/"..string.lower(Mode.Name)..".png", "GAME" ) then
			self.Modes[Mode.Name].Material = Material(GM.Name.."/gui/gamemodes/"..string.lower(Mode.Name)..".png", "noclamp smooth")
		end
	end
end
GamemodeSystem.GetActive = function( self ) return GetGlobalString( "ActiveGM", "Lobby" ) or "Lobby" end
GamemodeSystem.Get = function( self, Name ) return self.Modes[Name] or false end
GamemodeSystem.GetMode = function( self ) if self:GetActive()== "Lobby" then return false end return self.Modes[self:GetActive()] or false end
GamemodeSystem.Active = false
GamemodeSystem.ShowCoins = function( self, sCoins ) SetGlobalBool( "GMShowCoins", sCoins ) end
GamemodeSystem.ShowTimer = function( self, sTimer ) SetGlobalBool( "GMShowTimer", sTimer ) end
GamemodeSystem.SetPlaying = function( self, playing ) SetGlobalBool( "GMPlaying", playing ) end
GamemodeSystem.GetPlaying = function( self ) return GetGlobalBool( "GMPlaying", false ) end
GamemodeSystem.Clock.Remaining = function( self ) return math.floor( GetGlobalInt( "Clock", CurTime() ) - CurTime() ) end
if CLIENT then return end
util.AddNetworkString( "GamemodeSystem.Net" )
GamemodeSystem.Orders = {}
GamemodeSystem.SetActive = function( self, mN )
	SetGlobalString( "ActiveGM", mN )
	for _,v in pairs(player.GetAll()) do v:ConCommand( "menu Load" ) end
	local joinDefault = false
	local Mode = self:Get(mN) or false
	if Mode then
		local teams = {"1"}
		if Mode.Teams then teams = Mode.Teams end
		if #teams <= 1 then joinDefault = teams[1] end
	end
	timer.Simple( 1, function() for _,v in pairs(player.GetAll()) do
		MenuSystem:JoinTeam(v, joinDefault)
		v:ConCommand( "menu Play" )
	end end )
end
GamemodeSystem.Score = function( self, TeamID )
	local score = GetGlobalInt( "TeamScore", 0 )
end
GamemodeSystem.GiveScore = function( self, ply )
	ply:SetNWFloat( 'score', ply:GetNWFloat( 'score', 0 ) + 100 )
	Teams:playerScore(ply)
	ply:ConCommand( "PulseScore" )
end
GamemodeSystem.ScoreScreen = function( self )
	self:ShowTimer(false)
	self:ShowCoins(false)
	OrderSystem:Clear()
	Teams:ShowScores()
end
GamemodeSystem.GenerateOrders = function( self )
	self.Orders = {"Sliced Lettuce","Cooked Meat Patty","Bread Slice","Sandwich","Burger","Tomato Soup", "Potato Soup"}
end
GamemodeSystem.Init = function( self )
	local Mode = self:GetMode() or false
	if !Mode then return false end
	for t,p in pairs(MenuSystem:GetTable("GMTeams") or {}) do
		for k,v in pairs(p) do
			Teams:include(t, v)
			if t == "Spectators" then continue end
			self:Spawn(v, t, k)
			v:Lock()
		end
	end
	for _,v in pairs(player.GetAll()) do
		v:ConCommand( "closeMenu" )
	end
	if Mode.Init then Mode:Init() end
	timer.Simple( Mode.DelayPlay or 1, function()
		self:Play()
	end )
end
GamemodeSystem.Play = function( self )
	local Mode = self:GetMode() or false
	if Mode.Play then Mode:Play() end
	self:SetPlaying(true)
	for _,v in pairs(Teams:allPlayers()) do
		v:UnLock()
	end
end
GamemodeSystem.Spawn = function( self, ply, teamID, teamPos )
	local spawnPos = false
	if Map and Map.PlayerSpawns then 
		local teamTable = false
		if Map.PlayerSpawns[tonumber(teamID)] then teamTable = Map.PlayerSpawns[tonumber(teamID)] end
		if Map.PlayerSpawns[teamID] then teamTable = Map.PlayerSpawns[teamID] end
		if teamTable then
			if teamPos and teamTable[teamPos] then spawnPos = teamTable[teamPos] end
			if !spawnPos then spawnPos = table.Random(teamTable) end
		end
	end
	ply:SetTeam( 1 )
	ply:Spawn()
	if spawnPos then ply:SetPos(spawnPos) end
	local judge = false
	for _, v in pairs( ents.FindByClass( "base_judge" ) ) do judge = v break end
	if judge then
		ply:SetEyeAngles( ( judge:GetPos() - ply:GetShootPos() ):Angle() )
	end
	
end
GamemodeSystem.Load = function( self )
	local Mode = self:GetMode() or false
	if !Mode then return false end
	for _,v in pairs(player.GetAll()) do
		v:ConCommand( "menu Load" )
	end
	if Mode.Load then Mode:Load() end
	self.Loaded = true
	self:GenerateOrders()
	timer.Simple( 2, function() self:Init() end )
end
local checkMusic = false
local NextSpeed = 0
GamemodeSystem.Think = function( self )
	local Mode = self:GetMode() or false
	if !Mode then return end
	if #player.GetAll() <= 0 then return self:Reset() end
	if !self:GetPlaying() then return end
	if Mode.ShouldReset and Mode:ShouldReset() then return self:Reset() end
	if Mode.Think then Mode:Think() end
	if checkMusic and self.Clock:Remaining() <= (checkMusic or 30) then
		if (NextSpeed or 0) >= CurTime() then return end
		NextSpeed = CurTime() + 1
		for _,v in pairs(player.GetAll()) do v:ConCommand( 'Music_SpeedUp' ) end
	end
end
hook.Add( "Think", "GamemodeSystem.Think", function() GamemodeSystem:Think() end)
GamemodeSystem.Reset = function( self )
	GamemodeSystem.Music:Stop()
	local Mode = self:GetMode() or false
	self:SetPlaying(false)
	self:ShowTimer(false)
	self:ShowCoins(false)
	self.Loaded = false
	checkMusic = false
	NextSpeed = 0
	Teams:SaveResults()
	if Mode and Mode.Reset then Mode:Reset() end
	if MenuSystem and MenuSystem.Reset then MenuSystem:Reset() end
	self:SetActive("Lobby")
	self.Clock:Reset()
	OrderSystem:Clear()
	Teams:Reset()
	for _,v in pairs(player.GetAll()) do
		v:UnLock()
		v:StripWeapons()
		v:SetTeam( TEAM_SPECTATOR )
		v:Spectate( OBS_MODE_ROAMING )
		//v:SetPData( "money", v:GetNWFloat( 'score', 0 ) )
		//v:SetNWFloat( 'score', 0 )
	end
	if MapSystem and MapSystem.Reset then MapSystem:Reset() end
end
concommand.Add("GMReset", function(ply, cmd, args) if !ply:IsAdmin() then return end GamemodeSystem:Reset() end)
GamemodeSystem.Clock.Add = function( self, Time ) SetGlobalInt( "Clock", CurTime() + Time or 60 ) for _,v in pairs(player.GetAll()) do v:ConCommand( "UpdateTime "..(Time or 60) ) end end
GamemodeSystem.Clock.Reset = function( self ) SetGlobalInt( "Clock", 0 ) end
GamemodeSystem.Music.Add = function( self, path, shouldSpeed )
	for _,v in pairs(Teams:allPlayers({"Spectators"})) do if !PlayerSystem:GetSetting("GAME MUSIC", v) then continue end v:ConCommand( 'Music_Play "'..path..'"' ) end
	checkMusic = shouldSpeed or false
end
GamemodeSystem.Music.Stop = function( self ) for _,v in pairs(player.GetAll()) do v:ConCommand( 'Music_Stop' ) end end
GamemodeSystem.ForfillOrder = function( self, ply, order )
	// delicious!
end

