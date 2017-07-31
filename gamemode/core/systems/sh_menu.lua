function GM:ShowHelp( ply ) ply:ConCommand("menu") end
local Tables = {GMVotes={},GMTeams={},GMReady={},GMFinished={}}
local function playerInTeam(ply)
	for t, p in pairs(Tables.GMTeams) do
		if table.HasValue(p or {}, ply) then return t end
	end return false
end
local function GMshouldEnd()
	if #Tables.GMFinished >=1 and #Tables.GMFinished >= #player.GetAll()/2 then return true end return false
end
if SERVER then
	util.AddNetworkString( "Menu.Net" )
	
	local function Sync() net.Start( "Menu.Net" ) net.WriteTable(Tables) net.Broadcast() end
	local Counting = false
	local function ConditionalCountDown(time, condition, run, noClock)
		if !condition() or Counting then return end Counting = true
		if !noClock then GamemodeSystem.Clock:Add(time) end
		timer.Create( "CountDowner", time, 1, function() local valid = condition() if valid then run(valid) end Counting = false end )
	end
	local function shouldChangeGM()
		local winner = false
		local count = 0
		for g, p in pairs(Tables.GMVotes) do if #p > count then count = #p winner = g end end
		return winner
	end
	local function shouldStart()
		local teamCount = 0
		for t, p in pairs(Tables.GMTeams) do if t == "Spectators" then continue end teamCount = teamCount + #p end
		if teamCount <= 0 then return false end
		if #Tables.GMReady >= teamCount/2 then return true end return false
	end
	local function purgeFakes(tab) for k, v in pairs(tab) do if !IsValid(v) then table.remove(tab, k) Sync() end end end
	hook.Add( "Think", "Menu.Think", function()
		for t, p in pairs(Tables.GMTeams) do purgeFakes(p) end
		for t, p in pairs(Tables.GMVotes) do purgeFakes(p) end
		purgeFakes(Tables.GMReady)
		purgeFakes(Tables.GMFinished)
		
		if GamemodeSystem:GetMode() then
			if GamemodeSystem.Loaded then
				ConditionalCountDown(5, GMshouldEnd, function()
					GamemodeSystem:Reset()
					Tables.GMFinished = {}
					Tables.GMTeams = {}
					Sync()
				end, true)
			else
				ConditionalCountDown(5, shouldStart, function()
					GamemodeSystem:Load()
					Tables.GMReady = {}
					Sync()
				end)
			end
		else
			ConditionalCountDown(5, shouldChangeGM, function(winner)
				GamemodeSystem:SetActive(winner)
				Tables.GMVotes = {}
				Sync()
			end)
		end
	end)
	MenuSystem = {}
	MenuSystem.Reset = function( self )
		Tables = {GMVotes={},GMTeams={},GMReady={},GMFinished={}}
		Sync()
	end
	MenuSystem.JoinTeam = function( self, ply, teamID )
		if !teamID then return end
		local found = playerInTeam(ply)
		if found then table.RemoveByValue(Tables.GMTeams[found] or {}, ply) end
		for t, p in pairs(Tables.GMTeams) do
			if table.HasValue(p or {}, ply) then table.RemoveByValue(p or {}, ply) found = t end
		end
		if !found or found != teamID then 
			Tables.GMTeams[teamID] = Tables.GMTeams[teamID] or {}
			table.insert(Tables.GMTeams[teamID], ply)
		end
		Sync()
	end
	MenuSystem.GetTable = function( self, tableID ) return Tables[tableID] or {} end
	concommand.Add("GMVote", function(ply, cmd, args)
		if GamemodeSystem:GetMode() then return end
		if !args or !args[1] then return end
		local found = false
		for g, p in pairs(Tables.GMVotes) do
			if table.HasValue(p or {}, ply) then table.RemoveByValue(p or {}, ply) found = g end
		end
		local Mode = GamemodeSystem:Get(args[1])
		if !Mode then return end
		if !found or found != Mode.Name then 
			Tables.GMVotes[Mode.Name] = Tables.GMVotes[Mode.Name] or {}
			table.insert(Tables.GMVotes[Mode.Name], ply)
		end
		Sync()
	end)
	concommand.Add("GMJoinTeam", function(ply, cmd, args)
		if !GamemodeSystem:GetMode() then return end
		if !args or !args[1] then return end
		MenuSystem:JoinTeam(ply, args[1])
	end)
	concommand.Add("GMReadyUp", function(ply, cmd, args)
		if !GamemodeSystem:GetMode() then return end
		if !playerInTeam(ply) then return end
		if table.HasValue(Tables.GMReady, ply) then table.RemoveByValue(Tables.GMReady, ply) else table.insert(Tables.GMReady, ply) end
		Sync()
	end)
	concommand.Add("GMVoteFinish", function(ply, cmd, args)
		//if !GamemodeSystem:GetMode() then return end
		if table.HasValue(Tables.GMFinished, ply) then table.RemoveByValue(Tables.GMFinished, ply) else table.insert(Tables.GMFinished, ply) end
		Sync()
	end)
	concommand.Add("OpenBox", function(ply, cmd, args)
		local dosh = ply:GetNWFloat( 'score', 0 ) or 0
		if dosh < 100 then return end
		ply:SetNWFloat( 'score', dosh-100 )
	end)
	
	hook.Add( "PlayerInitialSpawn", "PlayerInitialSpawnMenu", function ( ply )
		Sync() timer.Simple(0.2, function() if IsValid(ply) then ply:ConCommand( "menu Intro" ) end end)
	end )
	
end
if SERVER then return end
local menu = {Frames={},Rendered={},Themes = {},draw = {}}
local FrameType = "DPanel"
if DEVELOPER_MODE then FrameType = "DFrame" end
local gradientTexture = surface.GetTextureID("gui/gradient")

net.Receive( "Menu.Net", function() local tables = net.ReadTable() or {} for k, v in pairs(tables or {}) do Tables[k] = v end end )

local function LerpColor(frac,from,to) return Color( Lerp(frac,from.r,to.r), Lerp(frac,from.g,to.g), Lerp(frac,from.b,to.b), Lerp(frac,from.a,to.a) ) end
surface.CreateFont( "FrameTitle", {font = "Trebuchet24",size = 100,weight = 700,antialias = true,shadow = false,outline = false,italic = true})
OCF_ = OCF_ or {}
menu.getFont = function( size, weight, italic )
	local w = weight or 500 local s = size or 24 local i = italic or false
	local fontName = "OCF_s"..s.."w"..w.."i"..tostring(i)
	if OCF_[fontName] and OCF_[fontName].weight == w and OCF_[fontName].italic == i then return fontName end
	surface.CreateFont( fontName, {font = "Trebuchet24",size = s or 12,weight = w,antialias = true,shadow = false,additive = false,italic = i})
	print("Building Font: "..fontName)
	OCF_[fontName] = {}
	OCF_[fontName].weight = w
	OCF_[fontName].italic = i
	return fontName
end
menu.Themes.Default = {
	Font = "Trebuchet24",
	Color = color_white,
	Hover = Color(255, 240, 40, 255),
	Disable = Color(100, 100, 100, 255)
}
menu.Width = function(self) if IsValid(self.Frame) then return self.Frame:GetWide() end return (0) end
menu.Height = function(self) if IsValid(self.Frame) then return self.Frame:GetTall() end return (0) end
menu.GetTheme = function(self, theme) if self.Themes[theme] then return self.Themes[theme] end return self.Themes.Default end
menu.Button = function( x, y, w, h, parent, text, theme, action )
	local Button = menu.vgui("DButton", x or 0, y or 0, w or 0, h or 0, parent or nil)
	Button.Theme = menu:GetTheme(theme)
	Button:SetText("")
	Button.Text = text or ""
	Button.OnCursorEntered = function ( s ) s.Hovered = true if s.Theme.Sound and s.Theme.Sound.Roll then surface.PlaySound(s.Theme.Sound.Roll) end end
	Button.OnCursorExited = function ( s ) s.Hovered = false end
	Button.PaintBefore = function()end
	Button.PaintAfter = function()end
	if action then
		Button.DoClick = function ( s )
			if s.Theme.Sound and s.Theme.Sound.Click then surface.PlaySound(s.Theme.Sound.Click) end
			action(s)
		end
	end
	
	
	Button.Paint = function ( s, w, h )
		local color = s.Theme.Color
		if s.Hovered then color = s.Theme.Hover end
		if s:GetDisabled() then color = s.Theme.Disable end
		s:PaintBefore(w, h)
		draw.SimpleTextOutlined( s.Text, s.Theme.Font, 0, h/2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,1, color_black )
		s:PaintAfter(w, h)
	end
	return Button
end
menu.KeyButton = function( keyText, text, x, y, w, h, parent, action, theme )
	local BackPanel = menu.Button(x or 0, y or 0, w or 0, h or 0, parent, text, theme, action)
	surface.SetFont( "Trebuchet18" )
	local keyWide = surface.GetTextSize( keyText or "" )
	BackPanel.Paint = function ( s, w, h )
		draw.RoundedBox( 4, 0, 0, keyWide+10, h, Color( 100, 100, 100, 100 ) )
		draw.RoundedBox( 4, 2, 2, keyWide-4+10, h-4, Color( 0, 0, 0, 200 ) )
		draw.SimpleText( keyText or "", "Trebuchet18", 5 , h/2, Color(255,255,255, 250), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleTextOutlined( text or keyText, "Trebuchet18", w-10 , h/2, Color(255,255,255, 250), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER,1,Color(0,0,0,50) )
	end
	return BackPanel
end
menu.BoxButton = function( x, y, w, h, parent, text, theme, action )
	BoxButton = menu.Button(x or 0, y or 0, w or 0, h or 0, parent, text, theme, action)
	BoxButton.Paint = function ( s, w, h )
		local color = s.Theme.Color
		local BGcolor = s.Theme.BGColor
		if s.Hovered then color = s.Theme.Hover end
		if s:GetDisabled() then color = s.Theme.Disable BGcolor = Color(100,100,100,50) end
		draw.RoundedBox( 2, 0, 0, w, h, BGcolor )
		draw.SimpleText( s.Text, s.Theme.Font, w/2, h/2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		if !s.Hovered or s:GetDisabled() then return end
		draw.SimpleTextOutlined( s.Text, s.Theme.Font, w/2, h/2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black )
	end
	return BoxButton
end
local NextPress = 0
menu.BindKey = function(button, key) local oldPaint = button.Paint button.Paint = function ( s, w, h ) oldPaint(s, w, h) if input.IsKeyDown( key ) and NextPress < CurTime() then s:DoClick() NextPress = CurTime()+1.2 end end end
menu.BackButton = function(x, y, parent)
	local back = menu.KeyButton("BACKSPACE", "BACK", x, y, 130, 30, parent, function()
		if GamemodeSystem:GetPlaying() then
			menu:Close()
		else
			menu:Select("Main")
		end
	end)
	menu.BindKey(back, KEY_BACKSPACE) return back
end
menu.DrawMaterial = function( x, y, w, h, material, color )
	if !material then return end
	surface.SetDrawColor(color or Color(255, 255, 255, 255))
	surface.SetMaterial( material )
	surface.DrawTexturedRect(x or 0, y or 0, w or 0, h or 0)
end
surface.CreateFont( "AvatarFrame", {font = "Trebuchet24",size = 22, weight = 500,antialias = true,shadow = false,outline = false,additive = false})
menu.AvatarFrame = function( x, y, w, h, parent, extend, ply, size )
	local player = ply or LocalPlayer()
	surface.SetFont( "Trebuchet18" )
	local Level = (LocalPlayer():GetNWFloat( 'score', 0 ) or 0)
	local levelW = surface.GetTextSize( Level )
	local AvatarPanel = menu.vgui("DPanel", x or 0, y or 0, w or 0, h or 0, parent)
	if extend then
		surface.SetFont( "AvatarFrame" )
		AvatarPanel:SetSize(AvatarPanel:GetWide() + surface.GetTextSize( player:Nick() )+levelW, AvatarPanel:GetTall())
		AvatarPanel:SetPos(select(1,AvatarPanel:GetPos()) - surface.GetTextSize( player:Nick() )-levelW, select(2,AvatarPanel:GetPos()))
	end
	AvatarPanel.Paint = function ( s, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 127, 167, 255, 25 ) )
		local plyW, plyH = draw.SimpleText( player:Nick(), "AvatarFrame", h+10	, h/2, Color(45,234,247, 250), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.RoundedBox( 4, (h+10)+plyW+5, h/2-(plyH/2)+4, levelW+4, plyH-8, Color( 255,255,114,250 ) )
		draw.SimpleText( Level, "Trebuchet18", (h+10)+plyW+5+(levelW/2)+2 , h/2, Color(0,0,0, 250), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	local Avatar = menu.vgui("AvatarImage", 0, 0, AvatarPanel:GetTall(), AvatarPanel:GetTall(), AvatarPanel)
	Avatar:SetPlayer( player, size or 64 )
	local AvatarOverlay = menu.vgui("DPanel", 0, 0, AvatarPanel:GetWide(), AvatarPanel:GetTall(), Avatar)
	AvatarOverlay.Paint = function ( s, w, h )
		draw.RoundedBox( 0, 0, 0, 5, h, Color( 170, 254, 112, 255 ) )
	end
	return AvatarPanel
end
menu.AddButton = function( text, layout, w, h, action, theme )
	local Button = menu.Button(0, 0, w, h, layout, text, theme, action)
	layout.Buttons = layout.Buttons or {}
	table.insert(layout.Buttons,Button)
	layout:Add( Button )
	return Button
end
menu.Overlay = function( parent ) return menu.vgui("DPanel", 0, 0, parent:GetWide(), parent:GetTall(), parent, true) end

local Hats = {}
Hats.Chef = {Model = "models/chefhat.mdl",Angle=Angle(-90,0,-90),Vector=Vector(0,7,0),Scale=0.8}
local function addHat(model, hat)
	if IsValid(model.HatModel) then return end
	local headBone = model:LookupBone( "ValveBiped.Bip01_Head1" )
	local headPos = model:GetBonePosition( headBone )
	if headPos then
		if hat and Hats[hat] then
			local CSM = ClientsideModel( Hats[hat].Model, RENDERMODE_TRANSALPHA )
			if Hats[hat].Scale then CSM:SetModelScale( Hats[hat].Scale ) end
			CSM:SetPos(headPos)
			local headIndex = model:LookupAttachment( "anim_attachment_head" )
			CSM:SetParent(model, headIndex or -1)
			CSM:SetLocalAngles( Hats[hat].Angle or Angle(0,0,0) )
			CSM:SetLocalPos( Hats[hat].Vector or Vector(0,0,0) )
			CSM:AddEffects( EF_BONEMERGE_FASTCULL )
			//CSM:SetNoDraw( true )
			model.HatModel = CSM
			model:CallOnRemove( tostring(CSM), function( ent ) if IsValid(model.HatModel) then model.HatModel:Remove() end end )
		end
	end
end
hook.Add( "Think", "Hat.Think", function()
	for _, v in pairs(player.GetAll()) do
		if !IsValid(v) or !v:Alive() then continue end
		if v != LocalPlayer() then addHat(v, "Chef") end
	end
end)
menu.Model = function( x, y, w, h, parent, model, sequence, hat, noEyes, layout )
	local BGPanel = menu.vgui("DPanel", x or 0, y or 0, w or 0, h or 0, parent or nil)
	BGPanel.Paint = function () end
	local mdl = vgui.Create( "DModelPanel", BGPanel )
	mdl.Frame = BGPanel
	mdl:Dock( FILL )
	mdl.Angles = Angle(0,0,0)
	mdl:SetModel( model )
	function mdl:Animate( animation ) if !animation or !IsValid(mdl.Entity) then return end mdl.Entity:ResetSequence( mdl.Entity:LookupSequence( animation ) ) end
	if sequence then mdl:Animate( sequence ) end
	if layout == "mouse" then
		function mdl:DragMousePress()
			self.PressX, self.PressY = gui.MousePos() self.Pressed = true
		end
		function mdl:DragMouseRelease() self.Pressed = false end
		function mdl:LayoutEntity( Entity )
			if ( self.bAnimated ) then self:RunAnimation() end
			if ( self.Pressed ) then local mx, my = gui.MousePos() self.Angles = self.Angles - Angle( 0, ( self.PressX or mx ) - mx, 0 ) self.PressX, self.PressY = gui.MousePos() end
			Entity:SetAngles( self.Angles+Angle( 0, RealTime() * 2 % 360, 0 ) )
		end
	elseif layout == "spin" then
		menu.Overlay(BGPanel)
	else
		function mdl:LayoutEntity( ent ) mdl:RunAnimation() end
		menu.Overlay(BGPanel)
	end
	local oldDraw = mdl.DrawModel
	local pos = mdl.Entity:GetPos()
	function mdl:DrawModel()
		oldDraw(self)
		if mdl.pEm and mdl.HasEmitter then mdl.pEm:Draw() end
		if IsValid( self.SubModel ) then self.SubModel:DrawModel() end
	end
	mdl.Explode = function( this, sprite, amount, speed, die)
		local s = speed or 1 local pos = this.Entity:GetPos()
		for i=1, (amount or 10) do
			 local part = this.pEm:Add(sprite,pos)
			 if part then
				  part:SetColor(math.random(255),math.random(100),math.random(100),255)
				  part:SetVelocity(Vector(math.random(-1,1),math.random(-1,1),math.random(-1,1)):GetNormal() * s)
				  part:SetDieTime(die or 1)
				  part:SetLifeTime(0)
				  part:SetStartSize(10)
				  part:SetEndSize(0)
			 end
		end
	end
	mdl.ParticleStart = function( this )
		local pEm = ParticleEmitter(this.Entity:GetPos(), true)
		pEm:SetNoDraw( true )
		this.pEm = pEm
		this.HasEmitter = true
	end
	mdl.ParticleFinish = function( this ) this.HasEmitter = false if this.pEm and this.pEm.Draw then this.pEm:Finish() end end
	
	if noEyes then
		mdl:SetFOV( 90 )
		mdl:SetLookAt( pos )
		mdl:SetCamPos( pos-Vector( -100, 0, -40 ) )
		return mdl
	else
		mdl:SetFOV( 50 )
		local headBone = mdl.Entity:LookupBone( "ValveBiped.Bip01_Head1" )
		local headPos = mdl.Entity:GetBonePosition( headBone )
		if headPos then
			mdl:SetLookAt( headPos )
			mdl:SetCamPos( headPos-Vector( -30, -10, 0 ) )
			if hat and Hats[hat] then
				local CSM = ClientsideModel( Hats[hat].Model, RENDERMODE_TRANSALPHA )
				if Hats[hat].Scale then CSM:SetModelScale( Hats[hat].Scale ) end
				CSM:SetPos(headPos)
				local headIndex = mdl.Entity:LookupAttachment( "anim_attachment_head" )
				CSM:SetParent(mdl.Entity, headIndex or -1)
				CSM:SetLocalAngles( Hats[hat].Angle or Angle(0,0,0) )
				CSM:SetLocalPos( Hats[hat].Vector or Vector(0,0,0) )
				CSM:AddEffects( EF_BONEMERGE_FASTCULL )
				CSM:SetNoDraw( true )
				mdl.SubModel = CSM
			end
		end
	end
	return mdl, BGPanel
end

menu.Themes.BoxButton = {
	Font = "DermaLarge",
	Color = color_white,
	BGColor = Color( 255, 140, 0, 250 ),
	Hover = color_white
}
menu.Themes.BoxButtonAccent = {
	Base = "BoxButton",
	BGColor = Color( 0, 165, 255, 250 )
}

local lootbox_bg = Material( GM.Name.."/gui/backgrounds/lootbox_bg.jpg", "noclamp smooth" )
local lootbox_sub1 = GM.Name.."/entities/lootbox/lootbox"
local lootbox_sub2 = GM.Name.."/entities/lootbox/lootbox_2"
menu.Frames.Loot = function( self )
	local Frame, w, h = menu.vgui(FrameType, 0, 0, menu:Width(), menu:Height(), menu.Frame)
	Frame.Paint = function (s,w,h)
		menu.DrawMaterial(0, 0, w, h, lootbox_bg, Color(255,255,255,250))
	end
	local ModelPanel = menu.Model(10, 20, w-20, h-40, Frame, "models/Items/ammocrate_smg1.mdl", "Idle", false, true, "mouse")

	local Open = menu.BoxButton( (w/2)-180, h-100, 250, 60, Frame, "OPEN LOOT BOX", "BoxButton")
	Open.DoClick = function ( s )
		surface.PlaySound(GAMEMODE.Name.."/gui/open_loot.mp3")
		ModelPanel:Animate( "Open" )
		RunConsoleCommand( "OpenBox" )
		timer.Simple(1,function()
			ModelPanel:Animate( "Close" )
			ModelPanel:Explode("sprites/scanner_dots2", 50, 60, 3.5)
			ModelPanel:Explode("sprites/orangecore1", 10, 50, 5)
			ModelPanel:Explode("sprites/orangeflare1", math.random(50,100), 30, 3.5)
			ModelPanel:Explode("sprites/light_glow02_add", math.random(50,100), 70, 15)
			ModelPanel:Explode("sprites/physg_glow1", 20, 20, 15)
		end)
		s:SetDisabled(true)
	end
	if LocalPlayer():GetNWFloat( 'score', 0 ) < 100 then Open:SetDisabled(true) end
	
	local Buy = menu.BoxButton( (w/2)+80, h-100, 100, 60, Frame, "BUY", "BoxButtonAccent", function() end )
	Buy:SetDisabled(true)

	menu.BackButton(Frame:GetWide()-150, Frame:GetTall()-50, Frame)
	
	Frame.OnSelect = function ( s )
		ModelPanel.Entity:SetSubMaterial( 0, lootbox_sub1 )
		ModelPanel.Entity:SetSubMaterial( 1, lootbox_sub2 )
		ModelPanel:ParticleStart()
	end
	Frame.OnClose = function ( s )
		ModelPanel:Animate( "Idle" )
		ModelPanel:ParticleFinish()
		Open:SetDisabled(false)
	end
	return Frame
end

menu.Themes.ModelCard = {
	Font = "ModelCard",
	Color = Color(177, 196, 228, 255),
	Hover = Color(255, 240, 40, 255),
	Size = 100
}


menu.draw.FrameTitle = function( text,x,y ) return draw.SimpleTextOutlined( text or "Error", "FrameTitle", x or 50 , y or 50, Color(255,255,255, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black ) end
menu.draw.Texture = function( texture,x, y, w, h, color )
	surface.SetTexture( texture or gradientTexture )
	surface.SetDrawColor( color or Color( 255, 255, 255, 255 ) )
	surface.DrawTexturedRect(y or 0, x or 0, w or 0, h or 0)
end

local soup = Material( GM.Name.."/gui/backgrounds/soup.jpg", "noclamp smooth" )

surface.CreateFont( "ModelCard", {font = "Trebuchet24",size = 28,weight = 600,antialias = true,shadow = false,additive = false,italic = true})
menu.Frames.Gallery = function( self )
	local Frame, w, h = menu.vgui(FrameType, 0, 0, menu:Width(), menu:Height(), menu.Frame)
	Frame.Paint = function ( s, w, h )
		//draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 100 ) )
		menu.DrawMaterial(0, 0, w, h, soup, Color(255,255,255,200))
		Derma_DrawBackgroundBlur( s, 1 )
		menu.draw.FrameTitle("Chef Gallery")
	end
	
	local List	= vgui.Create( "DIconLayout", Frame )
	List:SetSize( w-100, h/2 )
	List:SetPos( 50, h/4 )
	List:SetSpaceY( 5 )
	List:SetSpaceX( 5 )

	for i = 1, 1 do
		local ListItem = List:Add( "DPanel" )
		ListItem:SetSize( 100, 180 )
		ListItem.Paint = function ( s, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 176, 173, 190, 255 ) )
			draw.RoundedBox( 0, 0, 0, w, 100, Color( 255, 229, 231, 150 ) )
			menu.draw.Texture(gradientTexture, 0, 0, w, h, Color( 211, 212, 217, 255  ))
			menu.draw.Texture(gradientTexture, 0, 0, w, 100, Color( 131, 143, 181, 255 ))
		end
		
		local SpawnI = vgui.Create( "SpawnIcon" , ListItem )
		SpawnI:SetPos( 0, 0 )
		SpawnI:SetSize( 100, 100 )
		SpawnI:SetModel( "models/player/odessa.mdl" )
				
		local Overlay = menu.Overlay(ListItem)
		Overlay.Paint = function ( s, w, h )
			draw.SimpleText( "ODESSA", "ModelCard", w/2-2 , 105, Color(43,59,95, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
		end
		
	end
	
	menu.BackButton(Frame:GetWide()-150, Frame:GetTall()-50, Frame)
	
	return Frame
end

local couscous = Material( GM.Name.."/gui/backgrounds/couscous.jpg", "noclamp smooth" )
menu.Frames.Options = function( self )
	local Frame, w, h = menu.vgui(FrameType, 0, 0, menu:Width(), menu:Height(), menu.Frame)
	Frame.Paint = function ( s, w, h )
		menu.DrawMaterial(0, 0, w, h, couscous, Color(255,255,255,200))
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 100 ) )
		Derma_DrawBackgroundBlur( s, 1 )
		menu.draw.FrameTitle("Options")
	end
	
	local DScrollPanel = menu.vgui("DScrollPanel", 100, 150, Frame:GetWide()-200, Frame:GetTall()-300, Frame)
	local layout = menu.vgui("DIconLayout", 0, 0, DScrollPanel:GetWide(), DScrollPanel:GetTall(), DScrollPanel)
	layout:SetSpaceY( 5 )
	layout:SetSpaceX( 5 )
	
	local OButtons = {}
	OButtons.Toggle = function(DOption, Name)
		local dToggle = menu.Button( DOption:GetWide()-200, 0, 200, DOption:GetTall(), DOption )
		dToggle.Name = Name
		local hovEn = dToggle.OnCursorEntered dToggle.OnCursorEntered = function ( s ) hovEn(s) DOption:OnCursorEntered() end
		local hovEx = dToggle.OnCursorExited dToggle.OnCursorExited = function ( s ) hovEx(s) DOption:OnCursorExited() end
		dToggle.Paint = function ( s, w, h )
			local BGcolor = Color( 111, 161, 208, 100 )
			if s.Hovered then BGcolor = Color( 90, 130, 168, 150 ) end
			draw.RoundedBox( 0, 0, 0, w, h, BGcolor )
			local text = "OFF"
			if s.On then text = "ON" end
			draw.SimpleText( text, menu.getFont( 24, 600 ), w/2 , h/2, DOption.Tcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
		dToggle.Think = function ( s )
			if PlayerSystem:GetSetting(s.Name) then s.On = true else s.On = false end
		end
		dToggle.DoClick = function ( s )
			PlayerSystem:ChangeSetting(s.Name, function()
				net.WriteBool(!s.On)
			end)
		end
		return dToggle
	end
		
	for k, v in pairs(PlayerSystem.Options) do
		local DOption = menu.Button( 0, 0, layout:GetWide(), 40, layout, k )
		DOption:SetCursor( "arrow" )
		local OptionRow = OButtons[v](DOption, k)
		DOption.Paint = function ( s, w, h )
			s.Tcolor = Color(255,255,255, 240)
			local BGcolor = Color( 0, 0, 0, 200 )
			if s.Hovered then s.Tcolor = Color(0,0,0, 240) BGcolor = Color( 255, 255, 255, 200 ) end
			draw.RoundedBox( 0, 0, 0, w, h, BGcolor )
			draw.SimpleText( s.Text, menu.getFont( 24, 600 ), 20 , h/2, s.Tcolor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
			
		end
		layout:Add( DOption )
	end
	
	//local restore = menu.KeyButton("ENTER", "RESTORE DEFAULTS", Frame:GetWide()-350, Frame:GetTall()-50, 180, 30, Frame, function() menu:Select("Options") end)
	//menu.BindKey(restore, KEY_ENTER)
	
	menu.BackButton(Frame:GetWide()-150, Frame:GetTall()-50, Frame)
	
	return Frame
end

local bench = Material( GM.Name.."/gui/backgrounds/bench.jpg", "noclamp smooth" )
local LobbyModeMaterial = Material( GM.Name.."/gui/gamemodes/lobby.png", "noclamp smooth" )
local InfoMaterial = Material( GM.Name.."/gui/icons/info.png", "noclamp smooth" )

menu.Frames.Play = function( self )
	local Frame, w, h = menu.vgui(FrameType, 0, 0, menu:Width(), menu:Height(), menu.Frame)
	Frame.Paint = function ( s, w, h )
		menu.DrawMaterial(0, 0, w, h, bench, Color(255,255,255,200))
		Derma_DrawBackgroundBlur( s, 1 )
		if GamemodeSystem:GetPlaying() then menu.draw.FrameTitle("Lobby") else menu.draw.FrameTitle("Play") end
	end
	if GamemodeSystem:GetPlaying() then
		Frame.OnSelect = function ( s ) menu.Frame:SetKeyboardInputEnabled( false ) end
		Frame.OnClose = function ( s ) menu.Frame:SetKeyboardInputEnabled( true ) end
	end
	
	local TopBar = menu.vgui("DPanel", 50, 200, Frame:GetWide()-100, 150, Frame)
	local ActiveGM = GamemodeSystem:GetActive()
	local ReadyCol = Color(255,255,255,200)
	TopBar.Paint = function ( s, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 150 ) )
		draw.SimpleTextOutlined( math.Clamp(GamemodeSystem.Clock:Remaining(),0,9999), menu.getFont( 32, 600 ), 420 , 10, Color(255,255,255,200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0,0,0,100) )
	end
	local ActiveMode = GamemodeSystem:GetMode()
	if ActiveGM == "Lobby" then
		
		local playerIcons = {}
		local PlyIconScroll = menu.vgui("DHorizontalScroller", 50, 380, Frame:GetWide()-100, 30, Frame)
		PlyIconScroll:SetOverlap(-20)
		PlyIconScroll.AddPlayer = function (s, ply)
			local icon = menu.vgui( "DPanel", 0, 0, 30, 30, PlyIconScroll, true )
			icon.player = ply
			icon.Toggle = function ( s, toggle )
				if s.Fading then return end s.Fading = true
				s.voteIcon = toggle
				local a = 255
				if toggle then a = 0 end
				s:AlphaTo( a, 0.5, 0, function() if IsValid(s) then s.Fading = false end end)
			end
			icon.Think = function (s)
				if s.voteIcon and !IsValid(s.voteIcon) then s.voteIcon = false s:Toggle(false) end
			end
			local Avatar = vgui.Create( 'RoundedAvatar', icon )
			Avatar:SetSize( 30, 30 )
			Avatar:SetPlayer( ply, 32 )
			playerIcons[ply] = icon
			s:AddPanel(icon)
		end
		PlyIconScroll.RemovePlayer = function ( s, v )
			if v.Removing then return end v.Removing = true
			v:AlphaTo( 0, 0.5, 0, function() if IsValid(v) then playerIcons[v.player] = nil v:Remove() end end)
		end
		PlyIconScroll.Think = function (s)
			for _, p in pairs(player.GetAll()) do
				local found = false
				for _, v in pairs(playerIcons) do
					if v.player == p then found = v end
				end
				if !found then s:AddPlayer(p) end
			end
			for _, v in pairs(playerIcons) do
				if !table.HasValue(player.GetAll(), v.player) then s:RemovePlayer(v) end
			end
		end
		
		local Scroll = menu.vgui("DHorizontalScroller", 50, 0, 50, 300, Frame)
		Scroll:SetOverlap(-10)
		
		for k,v in pairs(GamemodeSystem.Modes) do
			if v.CanPlay and !v:CanPlay() then continue end
			if v.Disabled then continue end
			local GMPanel = menu.vgui( "DPanel", 0, 0, 400, 300, Scroll )
			GMPanel.Paint = function ( s, w, h )
				draw.RoundedBoxEx( 8, 0, 0, w, h, Color( 255, 255, 255, 50 ), false, false, true, true )
				if v.Material then menu.DrawMaterial(0, 0, w, 150, v.Material, Color(255,255,255,255)) end
				local nameCol = color_white
				if Tables.GMVotes[k] then
					local ma = (#Tables.GMVotes[k] / #player.GetAll())
					nameCol = LerpColor(ma,color_white,Color( 114, 252, 132, 255 ))
				end
				
				draw.SimpleTextOutlined( k, menu.getFont( 40, 900, true ), w/2 , h/4, nameCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black )
				if !v.Description then return end
				draw.SimpleTextOutlined( v.Description, menu.getFont( 14 ), w/2 , h/4+40, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,150) )
				
				draw.RoundedBox( 8, 20, h/2+10, w-40, h/2-20, Color( 0, 0, 0, 200 ) )
			end
			
			local votedScroll = menu.vgui("DScrollPanel", 30, GMPanel:GetTall()/2+20, GMPanel:GetWide()-40, GMPanel:GetTall()/4, GMPanel)
			local voted = menu.vgui("DIconLayout", 0, 0, votedScroll:GetWide(), votedScroll:GetTall(), votedScroll)
			voted:SetSpaceY( 5 )
			voted:SetSpaceX( 5 )
			voted.AddVote = function ( s, ply )
				local Avatar = vgui.Create( 'RoundedAvatar', voted )
				Avatar:SetAlpha( 0 ) Avatar:AlphaTo( 255, 0.5)
				Avatar:SetSize( 30, 30 )
				Avatar:SetPlayer( ply, 32 )
				Avatar.player = ply
				voted:Add( Avatar )
				for _, v in pairs(playerIcons) do
					if v.player == ply then v:Toggle(Avatar) end
				end
			end
			voted.RemoveVote = function ( s, v )
				if v.Removing then return end v.Removing = true
				v:AlphaTo( 0, 0.5, 0, function() if IsValid(v) then v:Remove() end end)
			end
			voted.Think = function (s)
				Tables.GMVotes = Tables.GMVotes or {}
				Tables.GMVotes[k] = Tables.GMVotes[k] or {}
				for _, p in pairs(Tables.GMVotes[k]) do
					local found = false
					for _, v in pairs(s:GetChildren()) do
						if v.player == p then found = v end
					end
					if !found then s:AddVote(p) end
				end
				for _, v in pairs(s:GetChildren()) do
					if !IsValid(v.player) or !table.HasValue(Tables.GMVotes[k], v.player) then s:RemoveVote(v) end
				end
			end
			local showDetails = false
			local GMOverlay = menu.Button(0, 0, GMPanel:GetWide(), GMPanel:GetTall()/2, GMPanel)
			GMOverlay.Paint = function (s, w, h)
				if s:IsHovered() then
					surface.SetDrawColor( Color( 114, 252, 132, 200 ) )
					surface.DrawOutlinedRect( 0, 0, w, h )
				end
				if !showDetails then return end
				draw.RoundedBox( 0, 0, 0, w, h, Color( 204, 211, 226, 230 ) )
				if !v.Description then return end
				draw.SimpleTextOutlined( v.Description, menu.getFont( 14 ), w/2 , h/4+40, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,150) )
			end
			GMOverlay.DoClick = function ( s )
				RunConsoleCommand( "GMVote", k )
			end
			local InfoPanel = menu.vgui( "DPanel", 5, 5, 20, 20, GMOverlay )
			InfoPanel.Paint = function ( s, w, h )
				menu.DrawMaterial(0, 0, w, h, InfoMaterial, Color(255,255,255,150))
			end
			InfoPanel.OnCursorEntered = function ( s ) showDetails = true end
			InfoPanel.OnCursorExited = function ( s ) showDetails = false end
			
			Scroll:AddPanel(GMPanel)
			Scroll:SetSize(math.Clamp(select(1, Scroll:GetSize())+400,0,Frame:GetWide()-100), select(2, Scroll:GetSize()))
			Scroll:Center()
			Scroll:SetPos(select(1, Scroll:GetPos()), Frame:GetTall()/2)
		end
	else
		if !GamemodeSystem:GetPlaying() then
			local Searcher = menu.vgui("DPanel", Frame:GetWide()/2-130, 50, 260, 50, Frame)
			Searcher.Start = CurTime()
			local spin = 0
			Searcher.Paint = function ( s, w, h )
				spin = spin + (RealFrameTime()*50) % 360
				draw.RoundedBox( 0, 0, 0, w, h, Color( 76, 86, 106, 255 ) )
				draw.RoundedBox( 0, h, 5, 2, h-10, Color( 39, 170, 225, 255 ) )
				draw.NoTexture()
				surface.SetDrawColor( Color( 255, 255, 255, 25 ) )
				surface.DrawTexturedRectRotated( h/2, h/2, h/2, h/2, spin )
				
				local time = string.FormattedTime( tonumber(os.difftime( CurTime(), s.Start )), "%02i:%02i" )
				draw.SimpleText( "WAITING FOR PLAYERS", menu.getFont( 20, 900 ), h+10 , 5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
				draw.SimpleText( "ELAPSED TIME: "..time, menu.getFont( 16, 600 ), h+10 , h-5, Color(157,197,206,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM )
			end
		end
		
		local ReadyUp = menu.Button(420, 100, 150, 32, TopBar)
		ReadyUp.CanClick = false
		ReadyUp:SetText("")
		ReadyUp.DoClick = function ( s )
			if !s.CanClick then return end
			if GamemodeSystem:GetPlaying() then return end
			RunConsoleCommand( "GMReadyUp" )
		end
		ReadyUp.Paint = function ( s, w, h )
			if GamemodeSystem:GetPlaying() then return end
			local txt = "☐ Ready" local col = Color(255,255,255,200)
			if s.Checked then txt = "☑ Ready" col = Color( 114, 252, 132, 250 ) end
			if !s.CanClick then txt = "☒ Ready" col = Color( 206, 165, 165, 250 ) end
			draw.SimpleTextOutlined( txt, menu.getFont( 32, 600 ), 0 , 0, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0,0,0,100) )
		end
		ReadyUp.Think = function ( s )
			if playerInTeam(LocalPlayer()) then s.CanClick = true else s.CanClick = false end
			if table.HasValue(Tables.GMReady, LocalPlayer()) then s.Checked = true ReadyCol = Color( 114, 252, 132, 250 ) else s.Checked = false ReadyCol = Color(255,255,255,200) end
		end
		
		local flip = false
		local function AddTeam(parent, x, y, w, h, k, minimal)
			local Team_Panel = menu.vgui( "DPanel", x, y, w, h, parent )
			Team_Panel.Name = "Team "..k
			Team_Panel.Paint = function (s, w, h)
				draw.SimpleTextOutlined( s.Name, menu.getFont( 30, 600 ), 0, 10, Color(255,255,255,200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0,0,0,100) )
			end
			local Team_Button = menu.Button(Team_Panel:GetWide()-115, 10, 100, 30, Team_Panel)
			Team_Button.Paint = function (s, w, h)
				if GamemodeSystem:GetPlaying() then return end
				local txt = "Join" local col = Color(128,221,165,200)
				if Tables.GMTeams[k] and table.HasValue(Tables.GMTeams[k], LocalPlayer()) then txt = "Leave" col = Color(219,127,127,200) end
				draw.SimpleTextOutlined( txt, menu.getFont( 30, 600 ), w, h/2, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 1, Color(0,0,0,100) )
			end
			Team_Button.DoClick = function(s)
				if ReadyUp.Checked then return end
				if GamemodeSystem:GetPlaying() then return end
				RunConsoleCommand( "GMJoinTeam", k )
			end
			local Team_Scroll = menu.vgui("DScrollPanel", 0, 50, Team_Panel:GetWide(), Team_Panel:GetTall()-50, Team_Panel)
			Team_Scroll.Paint = function (s, w, h) draw.RoundedBox( 0, 0, 0, w-15, h, Color(0,0,0,50) ) end
			Team_List = menu.vgui("DIconLayout", 0, 0, Team_Scroll:GetWide()-15, Team_Scroll:GetTall(), Team_Scroll)
			Team_List:SetSpaceY( 5 ) Team_List:SetSpaceX( 0 )
			Team_List.RemovePlayer = function ( s, v )
				if v.Removing then return end v.Removing = true
				v:AlphaTo( 0, 0.5, 0, function() if IsValid(v) then v:Remove() end end)
			end
			local height = 30
			local align = TEXT_ALIGN_RIGHT
			if !minimal then
				height = 50
				if flip then align = TEXT_ALIGN_LEFT end flip = !flip
			end
			Team_List.AddPlayer = function ( s, ply )
				if !IsValid(ply) then return end
				local line = menu.vgui( "DPanel", 0, 0, s:GetWide(), height, s )
				line:SetAlpha( 0 ) line:AlphaTo( 255, 0.5)
				line.player = ply
				line.Name = ply:Nick() or "INVALID"
				line.Paint = function (s, w, h)
					if !minimal then
						local Col1 = Color( 108, 75, 75, 100 ) local Col2 = Color( 168, 75, 75, 255 )
						if align == TEXT_ALIGN_RIGHT then Col1 = Color( 76, 86, 106, 100 ) Col2 = Color( 76, 86, 176, 255 ) end
						draw.RoundedBox( 0, 0, 0, w, h, Col1 )
						local x = 0 if align == TEXT_ALIGN_RIGHT then x = w-5 end
						draw.RoundedBox( 0, x, 0, 5, h, Col2 )
						local plyTextCol = Color(255,255,255,200)
						if table.HasValue(Tables.GMReady, ply) then
							plyTextCol = Color(166,255,160,200)
							draw.RoundedBox( 0, x, 0, 5, h, plyTextCol )
						end
						x = 60 if align == TEXT_ALIGN_RIGHT then x = w-60 end
						draw.SimpleTextOutlined( s.Name, menu.getFont( 42, 600 ), x, h/2, plyTextCol, align, TEXT_ALIGN_CENTER, 1, Color(0,0,0,100) )
					else
						draw.RoundedBox( 0, 0, 0, w, h, Color(0,0,0,100) )
						draw.SimpleTextOutlined( s.Name, menu.getFont( 20, 600 ), w/2, h/2, Color(255,255,255,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,50) )
					end
				end
				if !minimal then
					local x = 5 if align == TEXT_ALIGN_RIGHT then x = line:GetWide()-55 end
					local Avatar = menu.vgui("AvatarImage", x, 0, 50, 50, line) //RoundedAvatar AvatarImage
					Avatar:SetPlayer( ply, 64 )
				end
				s:Add( line )
			end
			Team_List.Think = function (s)
				Tables.GMTeams = Tables.GMTeams or {}
				Tables.GMTeams[k] = Tables.GMTeams[k] or {}
				for _, p in pairs(Tables.GMTeams[k]) do
					local found = false
					for _, v in pairs(s:GetChildren() or {}) do
						if v.player == p then found = v end
					end
					if !found then s:AddPlayer(p) end
				end
				for _, v in pairs(s:GetChildren()) do
					if !IsValid(v.player) or (Tables.GMTeams[k] and !table.HasValue(Tables.GMTeams[k], v.player)) then s:RemovePlayer(v) end
				end
			end
			return Team_Panel
		end
		
		local teams = {1}
		if ActiveMode.Teams then teams = ActiveMode.Teams end
		
		local teamWide = Frame:GetWide()/2-55
		local scrollOffset = 100
		
		if #teams <= 1 then
			teamWide = Frame:GetWide()-250
		end
		if ActiveMode.Spectators then
			teamWide = teamWide-150
			scrollOffset = 400
		end
		
		local Scroll = menu.vgui("DHorizontalScroller", 50, 350, Frame:GetWide()-scrollOffset, Frame:GetTall()-460, Frame)
		Scroll:SetOverlap(-10)
		
		for k, v in pairs(teams) do
			local Team_Panel = AddTeam(Scroll, 0, 0, teamWide, Scroll:GetTall(), tostring(v))
			Scroll:AddPanel(Team_Panel)
		end
		if ActiveMode.Spectators then
			local Spectators_Panel = AddTeam(Frame, Frame:GetWide()-340, 350, 300, Frame:GetTall()-460, "Spectators", true)
			Spectators_Panel.Name = "Spectators"
		end
	end
	
	local ModeButton = menu.vgui("DButton", 0, 0, 400, 150, TopBar)
	ModeButton:SetText("")
	ModeButton.Paint = function ( s, w, h )
		local lobbyMat = LobbyModeMaterial
		if ActiveMode then lobbyMat = ActiveMode.Material end
		menu.DrawMaterial(0, 0, w, h, lobbyMat, Color(255,255,255,255))
		draw.SimpleTextOutlined( ActiveGM, menu.getFont( 26, 600 ), 10 , 10, Color(255,255,255,200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0,0,0,100) )
	end
	ModeButton.DoClick = function ( s )
		//ModeButton:SetVisible(true)
	end
	
	menu.AvatarFrame(w-150, 50, 100, 50, Frame, true)
	
	menu.BackButton(Frame:GetWide()-150, Frame:GetTall()-50, Frame)
	
	return Frame
end

menu.Themes.MainMenu = {
	Font = "MainMenu",
	Color = color_white,
	Hover = Color(255, 240, 40, 255),
	Sound = {Click = GM.Name.."/gui/click.mp3",Roll = GM.Name.."/gui/rollover.mp3"},
	Size = 70
}
menu.Themes.SubMainMenu = {
	Font = "SubMainMenu",
	Color = Color(177, 196, 228, 255),
	Hover = Color(255, 240, 40, 255),
	Sound = {Click = GM.Name.."/gui/click.mp3",Roll = GM.Name.."/gui/rollover.mp3"},
	Size = 40
}

surface.CreateFont( "MainMenu", {font = "Trebuchet24",size = 60,weight = 700,antialias = true,shadow = false,outline = false,italic = true})
surface.CreateFont( "SubMainMenu", {font = "Trebuchet24",size = 30,weight = 700,antialias = true,shadow = false,outline = false,italic = false})
menu.Frames.Main = function( self )
	local Frame, w, h = menu.vgui(FrameType, 0, 0, menu:Width(), menu:Height(), menu.Frame)
	Frame.Paint = function ( s, w, h )
		//draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 100 ) )
	end
	
	menu.Model(Frame:GetWide()/2, 0, w/4, h, Frame, "models/player/odessa.mdl", "menu_combine", "Chef")
	menu.AvatarFrame(w-150, 50, 100, 50, Frame, true)
	
	local padX = 100
	local padY = h/4
	local mainMenu = menu.vgui("DListLayout", padX, padY, w/4, h-padY, Frame)
	local theme = "MainMenu"
	local fontH = menu:GetTheme(theme).Size
	menu.AddButton("Play", mainMenu, padX, fontH, function(s)
		menu:Select("Play")
	end, theme)
	menu.AddButton("Chef Gallery", mainMenu, padX, fontH, function(s) menu:Select("Gallery") end, theme)
	menu.AddButton("Loot Box", mainMenu, padX, fontH, function(s) menu:Select("Loot") end, theme)
	if DEVELOPER_MODE then menu.AddButton("Close", mainMenu, padX, fontH, function(s) menu:Close() end, theme) end
	
	local theme = "SubMainMenu"
	local fontHPad = padY+(#mainMenu.Buttons*fontH)
	local fontH = menu:GetTheme(theme).Size
	local subMenu = menu.vgui("DListLayout", padX, fontHPad+10, w/4, h-fontHPad-20, Frame)
	if DEVELOPER_MODE then
		menu.AddButton("Force GM Reset", subMenu, padX, fontH, function(s)
			RunConsoleCommand( "GMReset" )
		end, theme)
	end
	//menu.AddButton("Profile", subMenu, padX, fontH, function(s) end, theme)
	menu.AddButton("Options", subMenu, padX, fontH, function(s) menu:Select("Options") end, theme)
	menu.AddButton("Disconnect", subMenu, padX, fontH, function(s) LocalPlayer():ConCommand( "disconnect" ) end, theme)
	
	return Frame
end
menu.Frames.Load = function( self )
	local Frame = menu.vgui(FrameType, 0, 0, menu:Width(), menu:Height(), menu.Frame)
	local spin = 0
	Frame.Paint = function ( s, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 240 ) )
		draw.SimpleText( "LOADING...", menu.getFont( 50, 900 ), 130 , h-100, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		spin = spin + (RealFrameTime()*50) % 360
		draw.NoTexture()
		surface.SetDrawColor( Color( 200, 200, 255, 25 ) )
		surface.DrawTexturedRectRotated( 100, h-100, 25, 25, spin )
	end
	return Frame
end

local TitleMaterial = Material( GM.Name.."/gui/title.png", "noclamp smooth" )
menu.Frames.InGame = function( self )
	local Frame, w, h = menu.vgui(FrameType, 0, 0, menu:Width(), menu:Height(), menu.Frame, true)
	
	Frame.OnSelect = function ( s ) menu.Frame:SetKeyboardInputEnabled( false ) end
	Frame.OnClose = function ( s ) menu.Frame:SetKeyboardInputEnabled( true ) end
	local Underlay = menu.vgui( "DButton", 0, 0, w, h, Frame, true )
	Underlay:SetText( "" )
	Underlay:SetCursor( "arrow" )
	Underlay.DoClick = function ( s, w, h ) menu:Close() end
	Underlay.Paint = function ( s, w, h )
		menu.DrawMaterial(w/2-200, h/8, 400, 80, TitleMaterial, Color(255,255,255,255))
	end
	local MidPanel = menu.vgui( "DPanel", 0, 0, 300, 0, Underlay, true )
	local Scroll = menu.vgui("DScrollPanel", 0, 5, MidPanel:GetWide(), MidPanel:GetTall(), MidPanel)
	local Buttons = menu.vgui("DIconLayout", 0, 0, Scroll:GetWide(), Scroll:GetTall(), Scroll)
	Buttons:SetSpaceY( 5 )
	Buttons:SetSpaceX( 0 )
	Buttons.AddButton = function ( s, text, action )
		local Button = menu.Button( 0, 0, s:GetWide(), 35, s, "test" )
		Button.DoClick = function ( s, w, h ) if action then action(s) end end
		Button.Paint = function ( s, w, h )
			if s:IsHovered() then draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 150 ) ) end
			draw.RoundedBox( 0, 1, 1, w-2, h-2, Color( 137, 190, 255, 200 ) )
			if s.textOveride then text = s:textOveride(s) or "" end
			draw.SimpleText( text or "", menu.getFont( 22, 100 ), w/2 , h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
		s:Add( Button ) return Button
	end
	Buttons:AddButton("SHOW LOBBY",function(s)
		menu:Select("Play")
	end)
	local voter = Buttons:AddButton("VOTE RESET",function(s)
		RunConsoleCommand( "GMVoteFinish" )
	end)
	if LocalPlayer():IsAdmin() then
		Buttons:AddButton("!FORCE GAME END!",function(s)
			RunConsoleCommand( "GMReset" )
		end)
	end
	voter.textOveride = function ( s )
		if GMshouldEnd() then return "GAME ENDING..." end
		if #Tables.GMFinished <= 0 then return "END GAME" end
		return "END GAME ("..#Tables.GMFinished.."/"..#player.GetAll()..")"
	end
	Buttons:AddButton("OPTIONS",function(s)
		menu:Select("Options")
	end)
	Buttons:AddButton("DISCONNECT",function(s)
		Derma_Query( "Do you want to leave the server?", "Please confirm.", "Leave", function()
			RunConsoleCommand( "disconnect" )
		end, "Cancel")
		
	end)
	Buttons:AddButton("RETURN TO GAME",function(s)
		menu:Close()
	end)
	MidPanel:SetSize(MidPanel:GetWide(), math.Clamp(#Buttons:GetChildren()*40,0,Underlay:GetTall()/2))
	Scroll:SetSize(MidPanel:GetWide(),math.Clamp(MidPanel:GetTall(),0,Underlay:GetTall()/2))
	MidPanel:Center()
	
	menu.BackButton(Frame:GetWide()-150, Frame:GetTall()-50, Frame)

	return Frame
end
menu.Frames.Intro = function( self )
	local Frame, w, h = menu.vgui(FrameType, 0, 0, menu:Width(), menu:Height(), menu.Frame, true)
	local Underlay = menu.vgui( "DPanel", 0, h, w, h, Frame, true )
	Underlay.Paint = function ( s, w, h )
		menu.DrawMaterial(w/2-300, h/2-60, 600, 120, TitleMaterial, Color(255,255,255,255))
	end
	if PlayerSystem:GetSetting("MENU MUSIC") then MusicSystem:Play( "sound/"..GAMEMODE.Name.."/music/intro_long.mp3" ) end
	Frame.OnSelect = function ( s )
		Underlay:MoveTo(0,0,3,0,-1,function()
			surface.PlaySound(GAMEMODE.Name.."/gui/knife_slash.mp3")
			Frame:AlphaTo( 1, 2, 1, function()
				if GamemodeSystem:GetPlaying() then menu:Select("InGame", true) else menu:Select("Main", true) end
			end)
		end)
	end
	
	return Frame
end
menu.Selected = false
menu.GetFrame = function( self, Frame ) if !IsValid(self.Rendered[Frame]) then return false end return self.Rendered[Frame] end
menu.Render = function( self, Frame )
	if !self.Frames[Frame] then return false end
	self.Rendered[Frame] = self.Frames[Frame]()
	if IsValid(self.Rendered[Frame]) then self.Rendered[Frame]:SetVisible(false) end
	return self:GetFrame(Frame)
end
menu.Shuffle = function( self, exception )
	local spots = {
		{self:Width(),0},
		{-self:Width(),0},
		{0,self:Height()},
		{self:Width(),self:Height()},
		{-self:Width(),self:Height()},
	}
	for k,v in pairs(self.Rendered) do
		if exception and k == exception then continue end
		if !IsValid(v) then continue end
		local rand = table.Random(spots)
		v:SetPos( rand[1], rand[2] )
		//v:SetVisible(false)
	end
end
menu.Select = function( self, Frame, NoAnimate )
	local OldFrame = self:GetFrame(Frame)
	local OldPos = OldFrame:GetPos() or false
	OldFrame:Remove()
	local Selected = self:Render(Frame)
	if OldPos then Selected:SetPos(OldPos) end
	if !IsValid(Selected) then return false end
	local Current = self:GetFrame(self.Selected)
	if IsValid(Current) then
		self:Shuffle(self.Selected)
		Current:MoveTo(0,self:Height(),0.3,0,-1,function() Current:SetVisible(false) end)
		if Current.OnClose then Current:OnClose() end
	end
	surface.PlaySound(GAMEMODE.Name.."/gui/whoosh.mp3")
	Selected:SetVisible(true)
	Selected:RequestFocus()
	if Selected.OnSelect then Selected:OnSelect() end
	self.Selected = Frame
	if NoAnimate then
		Selected:SetPos(0,0)
	else
		Selected:MoveTo(0,0,0.3,0,-1)
	end
end
menu.Init = function( self, initialFrame )
	if initialFrame and IsValid(self.Frame) then return self:Select(initialFrame) end
	if IsValid(self.Frame) then self.Frame:Remove() end
	self.Selected = false
	self.Frame = self.vgui(FrameType, 0, 300, ScrW(), ScrH())
	self.Frame:MoveTo( 0, 0, 0.5)
	//self.Frame:SetSizable( true )
	self.Frame:SetAlpha( 0 )
	self.Frame:AlphaTo( 255, 0.5)
	self.Frame:MakePopup()
	self.Frame.startTime = SysTime()
	local UseCamera = true
	if GamemodeSystem:GetPlaying() then UseCamera = false end
	if Map and Map.Camera then self.Frame.Camera = Map.Camera end
	self.Frame.Paint = function ( s, w, h )
		if UseCamera and s.Camera then
			render.RenderView( { origin = s.Camera[1], angles = s.Camera[2],x=0,y=0,w=w,h=h,drawviewmodel=false } )
		end
		Derma_DrawBackgroundBlur( s, s.startTime )
	end
	for _,v in pairs(self.Themes) do
		if v.Base and self.Themes[v.Base] then table.Inherit( v, self.Themes[v.Base] ) end
		table.Inherit( v, self.Themes.Default )
	end
	for k,v in pairs(self.Frames) do self:Render(k) end
	if initialFrame then
		self:Select(initialFrame)
	else
		if GamemodeSystem:GetPlaying() then
			self:Select("InGame", true)
		else
			self:Select("Main", true)
		end
		
	end
end
menu.Close = function( self )
	if self.Closing then return end self.Closing = true
	self.Frame:AlphaTo( 0, 0.5, 0, function() if IsValid(self.Frame) then self.Frame:Remove() end self.Closing = false end)
	timer.Simple(0.6, function() if IsValid(self.Frame) then self.Frame:Remove() end self.Closing = false end)
	if !GamemodeSystem:GetPlaying() then
		MusicSystem:Stop()
	end
end
menu.vgui = function( class, x, y, w, h, parent, noPaint )
	local Element = vgui.Create( class or "DFrame", parent or nil )
	Element:SetPos( x or 0, y or 0 )
	Element:SetSize( w or 0, h or 0 )
	if class == "DScrollPanel" then
		local b = Element:GetVBar() function b.btnUp:Paint( w, h ) end function b.btnDown:Paint( w, h ) end
		function b:Paint( w, h ) draw.RoundedBox( 0, w/2-2, 0, 5, h, Color( 0, 0, 0, 50 ) ) end
		function b.btnGrip:Paint( w, h ) draw.RoundedBox( 4, w/2-3, 0, 6, h, Color( 255, 255, 255, 200 ) ) end
	end	
	if noPaint then Element.Paint = function () end end
	return Element, (w or 0), (h or 0)
end
concommand.Add("menu", function(ply,cmd,args) local allowed = {"Load","Play","Intro"} if args and args[1] and table.HasValue(allowed, args[1]) then menu:Init(args[1]) else menu:Init() end end )
concommand.Add("closeMenu", function() menu:Close() end)
function GM:ScoreboardShow() if GamemodeSystem:GetPlaying() and !IsValid(menu.Frame) then menu:Init("InGame") end end
hook.Add( "OnSpawnMenuOpen", "OnSpawnMenuOpenFrame", function()
	if GamemodeSystem:GetPlaying() and !IsValid(menu.Frame) then menu:Init("InGame") end
end )