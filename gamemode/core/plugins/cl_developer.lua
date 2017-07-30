if !DEVELOPER_MODE then return end

local function GetTarget(ply)
	if !ply:IsAdmin() or !DEVELOPER_MODE then return end
	local tr = ply:GetEyeTrace( )
	local ent = tr.Entity
	if !IsValid(ent) then print("Invalid Target") return end
	print("-----------------------------");
	print("Entity: "..tostring(ent))
	print("Model: "..tostring(ent:GetModel()))
	if ent:GetMaterial() != "" then print("Material: "..tostring(ent:GetMaterial())) end
	print("Vector("..ent:GetPos().x..","..ent:GetPos().y..","..ent:GetPos().z..")")
	print("Angle: "..tostring(ent:GetAngles()))
	//print("SequenceList : Copied to Clipboard.")
	print("-----------------------------");
	//SetClipboardText( util.TableToJSON( ent:GetSequenceList(), true ) )
end
concommand.Add("gettarget", GetTarget)

local ItemPanel
hook.Add( "PopulateItems", "AddItemContent", function( pnlContent, tree, node )
	if ( ItemPanel ) then return end
	ItemPanel = vgui.Create( "DPanel", pnlContent )
	ItemPanel:Dock(FILL)
	local Scroll = vgui.Create( "DScrollPanel", ItemPanel )
	Scroll:Dock(FILL)
	local List	= vgui.Create( "DIconLayout", Scroll )
	List:Dock(FILL)
	List:SetSpaceY( 5 )
	List:SetSpaceX( 10 )
	for k,v in pairs(FoodSystem.Foods or {}) do
		if !v.Material or !v.Model then continue end
		local DButton = vgui.Create( "DButton", List )
		DButton:SetSize(100,100)
		DButton:SetText( v.Name )
		DButton.Paint = function ( s, w, h )
			draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 50 ) )
			surface.SetDrawColor(Color(255,255,255,255))
			surface.SetMaterial( v.Material )
			surface.DrawTexturedRect(5, 5, w-10, h-10)
		end
		DButton.DoClick = function()
			RunConsoleCommand("spawn_food", v.Name)
		end
		List:Add(DButton)
	end
	pnlContent:SwitchPanel( ItemPanel )
end)

spawnmenu.AddCreationTab( "Overcooked", function(test,test2)
	local SpawnmenuContentPanel = vgui.Create( "SpawnmenuContentPanel" )
	SpawnmenuContentPanel:CallPopulateHook( "PopulateItems" )
	return SpawnmenuContentPanel

end, "icon16/world.png", 200 )