AddCSLuaFile()
DEFINE_BASECLASS( "base_food_preparation" )

ENT.Type = "anim"
ENT.PrintName = "Frying Pan"
ENT.Author = "StealthPaw"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category	= "overcooked"
ENT.Model	= "models/props_c17/metalpot002a.mdl"
ENT.Material	= ""
ENT.Sound	= "overcooked/frying.mp3"
ENT.OCItem = true
ENT.ModulateSound = false
ENT.DropModelDistance = 1
ENT.DropModelOffsetX = 4
ENT.Cooker	= true
ENT.AutoPrepare	= true
ENT.DropFood = false
ENT.PreparationRate = 1
ENT.PreparationType	= "Fryer"
ENT.CanHold	= 1
ENT.GUISpin	= 180


function ENT:Init() end
if SERVER then
	function ENT:CanTouchFood( Name )
		local fT = FoodSystem:Food(Name) or {}
		if !fT.CanFry then return false end
		return true
	end
end