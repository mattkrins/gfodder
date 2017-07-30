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