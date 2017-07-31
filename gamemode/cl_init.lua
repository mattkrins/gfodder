include( "shared.lua" )
local root = GM.Name.."/gamemode/core/"
local _, folders = file.Find(root.."*", "LUA")
for _, folder in SortedPairs(folders, true) do
	for _, File in SortedPairs(file.Find(root .. folder .."/cl_*.lua", "LUA"), true) do
		include(root.. folder .. "/" ..File)
	end
	for _, File in SortedPairs(file.Find(root .. folder .."/sh_*.lua", "LUA"), true) do
		include(root.. folder .. "/" ..File)
	end
end
function GM:HUDPaint() return false end
function GM:DrawDeathNotice() end
function GM:AddDeathNotice() end
local hide = {
	CHudHealth = true,
	CHudBattery = true,
	CHudAmmo = true,
	CHudSecondaryAmmo = true,
	CHudCrosshair = true,
	CHudDamageIndicator = true,
	//CHudChat = true,
	CHudWeapon = true
}
hook.Add( "HUDShouldDraw", "HideHUD", function( name )
	if ( hide[ name ] ) then return false end
	if ( name == "CHudWeaponSelection" ) and !DEVELOPER_MODE then return false end
end )


OCF_ = OCF_ or {}
Font = function( size, weight, italic )
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



chat = chat or {}
chat.log = chat.log or {}
hook.Add( "OnPlayerChat", "HelloCommand", function( ply, t )
	if !l then table.insert(chat.log, {ply:Nick(),t,ply:SteamID()}) end
	if IsValid(chat.box) then chat.box:AddLine(ply:Nick(), t, ply:SteamID()) end
	if #chat.log > 20 then table.remove(chat.log, 1) end
end )
//function GM:StartChat() chat.Start() return true end -- This breaks EVERYTHING
chat.Start = function()
	if IsValid(chat.popup) then chat.popup:Remove() end
	chat.popup = vgui.Create("DPanel")
	chat.popup:SetPos( 0, 0 )
	chat.popup:SetSize( ScrW(), ScrH() )
	chat.popup:MakePopup()
	chat.popup.Paint = function ( s, w, h ) end
	local under = vgui.Create("DButton", chat.popup)
	under:SetText( "" )
	under:SetCursor( "arrow" )
	under:SetPos( 0, 0 )
	under:SetSize( chat.popup:GetWide(), chat.popup:GetTall() )
	under.Paint = function ( s, w, h ) end
	under.DoClick = function ( s ) if IsValid(chat.popup) then chat.popup:Remove() end end
	local w = chat.popup:GetWide()/4
	local h = chat.popup:GetTall()/4
	local x = 100
	local y = chat.popup:GetTall()-h-x
	local box = chat.vgui(x, y, w, h, chat.popup)
	box.Color = Color( 0, 0, 0, 150 )
	box.OnEnter = function ( s )
		if IsValid(chat.popup) then chat.popup:Remove() end
	end
	
	input.SetCursorPos( x+w/4, y+h-10 )
	
	timer.Simple(0.1,function()
		//if IsValid(box) then box.TextEntry:RequestFocus() end
	end)
end
local cB
chat.vgui = function( x, y, w, h, parent )
	if IsValid(cB) then cB:Remove() end
	local ChatBox = vgui.Create("DPanel", parent) cB = ChatBox
	ChatBox:SetPos( x or 0, y or 0 )
	ChatBox:SetSize( w or 0, h or 0 )
	ChatBox.Color = Color( 0, 0, 0, 50 )
	ChatBox.Paint = function ( s, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, s.Color )
	end
	ChatBox.Think = function ( s ) if !IsValid(s:GetParent()) then s:Remove() end end
	local ChatScroll = vgui.Create("DScrollPanel", ChatBox)
	ChatScroll:SetPos( 0, 0 )
	ChatScroll:SetSize( ChatBox:GetWide(), ChatBox:GetTall()-20 )
	local b = ChatScroll:GetVBar() function b.btnUp:Paint( w, h ) end function b.btnDown:Paint( w, h ) end
	function b:Paint( w, h ) end
	function b.btnGrip:Paint( w, h ) draw.RoundedBox( 4, w/2-3, 0, 6, h, Color( 50, 50, 50, 100 ) ) end
	local ChatLogList = vgui.Create("DListLayout", ChatScroll)
	ChatLogList:SetPos( 0, 0 )
	ChatLogList:SetSize( ChatScroll:GetWide(), ChatScroll:GetTall() )
	chat.box = ChatLogList
	ChatLogList.Fade = function ( s, a ) for _,v in pairs(s:GetChildren()) do v:AlphaTo( a, 1) end end
	ChatLogList.AddLine = function ( s, p, t, i, l )
		if !t or t=="" then return end
		for k,v in pairs(string.ToTable(t)) do
			if k == 69 then
				t = string.sub( t, 1, k ).."\n"..string.sub( t, k+1, string.len(t) )
			end
		end
		local lineWidth= surface.GetTextSize( t )/s:GetWide()
		local line = vgui.Create("DButton", s)
		line:SetText( "" )
		line:SetPos( 0, 0 )
		line:SetSize( s:GetWide(), 20+(lineWidth*20) )
		line:SetCursor( "arrow" )
		line.OnCursorEntered = function (t)
			s:Fade(255)
			s.Viewing = true t.Color = Color(150,150,150, 200)
		end
		line.OnCursorExited = function (t)
			s:Fade(50)
			s.Viewing = false t.Color = Color(117,117,117, 200)
		end
		line.DoRightClick = function ( s )
			local Menu = DermaMenu()
			Menu:AddOption( "Copy", function() SetClipboardText( s.Message ) end )
			Menu:AddOption( "See Profile", function()
				if !s.SteamID then return end
				local ply = player.GetBySteamID( s.SteamID ) or false
				if !ply or !IsValid(ply) then return end
				ply:ShowProfile()
			end )
			Menu:Open()
		end
		line.Name = p or "ERROR"
		line.SteamID = i or false
		line.Message = t
		line.Color = Color(117,117,117, 200)
		line.Paint = function ( s, w, h )
			draw.DrawText( s.Name..": "..s.Message, "DermaDefault", 5, 3, s.Color, TEXT_ALIGN_LEFT )
		end
		line:SetAlpha(0)
		line:AlphaTo( 255, 0.2)
		s:Add( line )
		if IsValid(ChatScroll) and !s.Viewing then line:AlphaTo( 50, 1, 2) ChatScroll.VBar:AnimateTo( #s:GetChildren()*19, 0.5, 0, 0.5 ) end
	end
	for _,v in pairs(chat.log or {}) do
		ChatLogList:AddLine(v[1],v[2],v[3])
	end
	local Input = vgui.Create("DTextEntry", ChatBox)
	ChatBox.TextEntry = Input
	Input:SetPos( 0, ChatBox:GetTall()-20 )
	Input:SetSize( ChatBox:GetWide(), 20 )
	Input:SetText( "" )
	Input.CanEnter = function( s )
		if string.len(s:GetValue()) >= 200 then return false end
		if string.Trim( s:GetValue() ) == "" or string.Trim( s:GetValue() ) == " " then s:SetText( "" ) return false end
		return true
	end
	Input.OnValueChange = function( s )
		if !s:CanEnter() then s.Color = Color(255,117,117, 100) return end
	end
	Input.OnEnter = function( s )
		if (s.NextChat or 0)>=CurTime() or !s:CanEnter() then s:RequestFocus() return end s.NextChat = CurTime()+1
		if ChatBox.OnEnter then ChatBox:OnEnter(s) end
		RunConsoleCommand( "say", s:GetValue() )
		s.Color = Color(117,117,117, 200)
		s:SetText( "" )
		s:RequestFocus()
	end
	Input.Color = Color(117,117,117, 200)
	Input.Paint = function ( s, w, h )
		local BGcolor = Color( 0, 0, 0, 50 )
		if s:IsHovered() or s:HasFocus() then BGcolor = Color( 50, 50, 50, 50 ) end
		draw.RoundedBox( 0, 0, 0, w, h, BGcolor )
		local prefix = LocalPlayer():Nick()..": "
		local text = ""
		if string.len( s:GetValue() or "" ) >= 1 then text = s:GetValue() end
		draw.SimpleText( prefix..text, "DermaDefault", 5 , h/2, s.Color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	end return ChatBox
end

local PANEL = {}
AccessorFunc( PANEL, "m_masksize", "MaskSize", FORCE_NUMBER )
function PANEL:Init()
	self.Avatar = vgui.Create("AvatarImage", self)
	self.Avatar:SetPaintedManually(true)
	self:SetMaskSize( 24 )
end
function PANEL:PerformLayout()
	self.Avatar:SetSize(self:GetWide(), self:GetTall())
	local x = self:GetWide()
	if self:GetTall() > x then x = self:GetTall() end
	self:SetMaskSize( x / 2 )
end
function PANEL:SetPlayer( id )
	self.Avatar:SetPlayer( id, self:GetWide() )
end
function PANEL:Paint(w, h)
	render.ClearStencil()
	render.SetStencilEnable(true)
	render.SetStencilWriteMask( 1 )
	render.SetStencilTestMask( 1 )
	render.SetStencilFailOperation( STENCILOPERATION_REPLACE )
	render.SetStencilPassOperation( STENCILOPERATION_ZERO )
	render.SetStencilZFailOperation( STENCILOPERATION_ZERO )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_NEVER )
	render.SetStencilReferenceValue( 1 )
	local _m = self.m_masksize
	local circle, t = {}, 0
	for i = 1, 360 do
		t = math.rad(i*720)/720
		circle[i] = { x = w/2 + math.cos(t)*_m, y = h/2 + math.sin(t)*_m }
	end
	draw.NoTexture()
	surface.SetDrawColor(color_white)
	surface.DrawPoly(circle)
	render.SetStencilFailOperation( STENCILOPERATION_ZERO )
	render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
	render.SetStencilZFailOperation( STENCILOPERATION_ZERO )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
	render.SetStencilReferenceValue( 1 )
	self.Avatar:SetPaintedManually(false)
	self.Avatar:PaintManual()
	self.Avatar:SetPaintedManually(true)
	render.SetStencilEnable(false)
	render.ClearStencil()
end
vgui.Register("RoundedAvatar", PANEL)