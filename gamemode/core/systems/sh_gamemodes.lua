GamemodeSystem = {Clock = {},Music={}}
if CLIENT then
	local function LerpColor(frac,from,to) return Color( Lerp(frac,from.r,to.r), Lerp(frac,from.g,to.g), Lerp(frac,from.b,to.b), Lerp(frac,from.a,to.a) ) end
	local pulse = 0
	local timeLimit = 1
	concommand.Add("PulseScore", function(ply, cmd, args) pulse = 1 end)
	concommand.Add("UpdateTime", function(ply, cmd, args) if !args[1] then return end timeLimit = tonumber(args[1]) end)
	hook.Add( "HUDPaint", "GamemodeSystem.HUDPaint", function()
		if DEVELOPER_MODE then draw.SimpleTextOutlined( "Active GM: "..GamemodeSystem:GetActive(), "CloseCaption_Bold", ScrW()-20, 20, Color( 255, 255, 255, 200 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 2, Color( 0, 0, 0, 50 ) ) end
		if GetGlobalBool( "GMShowCoins", false ) then
			local score = GetGlobalInt( "TeamScore", 0 )
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
		local Mode = GamemodeSystem:GetMode() or false
		if Mode then if Mode.HUDPaint then Mode:HUDPaint() end end
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
GamemodeSystem.Orders = {"Sandwich"}
GamemodeSystem.SetActive = function( self, mN )
	SetGlobalString( "ActiveGM", mN )
	for _,v in pairs(player.GetAll()) do v:ConCommand( "menu Load" ) end
	local joinDefault = false
	local Mode = self:Get(mN) or false
	if Mode then
		local teams = {1}
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
GamemodeSystem.Init = function( self )
	local Mode = self:GetMode() or false
	if !Mode then return false end
	for _,v in pairs(player.GetAll()) do
		v:UnSpectate()
		v:Spawn()
		v:Lock()
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
	for _,v in pairs(player.GetAll()) do
		v:UnLock()
	end
end
GamemodeSystem.Spawn = function( self, ply )
	local teamID = 0
	local spawnPos = false
	for k,v in pairs(MenuSystem:GetTable("GMTeams") or {}) do
		teamID = teamID + 1
		if Map.PlayerSpawns and Map.PlayerSpawns[teamID] then
			spawnPos = Map.PlayerSpawns[teamID][table.KeyFromValue( v, ply )] or table.Random(Map.PlayerSpawns[teamID])
			break
		end
	end
	if !spawnPos then
		for _,v in pairs(Map.PlayerSpawns or {}) do
			spawnPos = table.Random(v)
		end
	end
	if spawnPos then ply:SetPos(spawnPos) end

end
GamemodeSystem.Load = function( self )
	local Mode = self:GetMode() or false
	if !Mode then return false end
	for _,v in pairs(player.GetAll()) do
		v:ConCommand( "menu Load" )
		self:Spawn(v)
	end
	if Mode.Load then Mode:Load() end
	self.Loaded = true
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
	local Mode = self:GetMode() or false
	self:SetPlaying(false)
	self:ShowTimer(false)
	self:ShowCoins(false)
	self.Loaded = false
	checkMusic = false
	NextSpeed = 0
	if Mode and Mode.Reset then Mode:Reset() end
	if MenuSystem and MenuSystem.Reset then MenuSystem:Reset() end
	self:SetActive("Lobby")
	self.Clock:Reset()
	OrderSystem:Clear()
	for _,v in pairs(player.GetAll()) do
		v:UnLock()
		v:StripWeapons()
		v:Spectate( OBS_MODE_ROAMING )
		v:SetObserverMode( OBS_MODE_ROAMING )
	end
	if MapSystem and MapSystem.Reset then MapSystem:Reset() end
end
concommand.Add("GMReset", function(ply, cmd, args) if !ply:IsAdmin() then return end GamemodeSystem:Reset() end)
GamemodeSystem.Clock.Add = function( self, Time ) SetGlobalInt( "Clock", CurTime() + Time or 60 ) for _,v in pairs(player.GetAll()) do v:ConCommand( "UpdateTime "..(Time or 60) ) end end
GamemodeSystem.Clock.Reset = function( self ) SetGlobalInt( "Clock", 0 ) end
GamemodeSystem.Music.Add = function( self, path, shouldSpeed )
	for _,v in pairs(player.GetAll()) do if !PlayerSystem:GetSetting("GAME MUSIC", v) then continue end v:ConCommand( 'Music_Play "'..path..'"' ) end
	checkMusic = shouldSpeed or false
end
GamemodeSystem.Music.Stop = function( self ) for _,v in pairs(player.GetAll()) do v:ConCommand( 'Music_Stop' ) end end
GamemodeSystem.ForfillOrder = function( self, ply, order )
	// delicious!
end

