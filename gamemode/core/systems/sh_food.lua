FoodSystem = {}
FoodSystem.Foods = {}
FoodSystem.Recipes = {}
FoodSystem.Food = function( self, NameOrModel )
	if self.Foods[NameOrModel] then return self.Foods[NameOrModel] end
	for _,v in pairs(self.Foods) do if v.Model == NameOrModel then return v end end
	return false
end
FoodSystem.GetModel = function( self, Name )
	if self.Foods[Name] then return self.Foods[Name].Model or "models/error.mdl" end
end
FoodSystem.Recipe = function( self, Name )
	if self.Recipes[Name] then return self.Recipes[Name] end
	return false
end
local function Contains( foodTable, recipeTable )
	local foodCount = table.Count(foodTable)
	if (foodCount < #recipeTable) or (foodCount > #recipeTable) then return false end local i=0
	for Ingredient,_ in pairs( foodTable ) do
		if table.HasValue(recipeTable, Ingredient) then i=i+1 end
	end if i == #recipeTable then return true end
	return false
end
FoodSystem.HasRecipe = function( self, foodTable )
	for Recipe,recipeTable in pairs(self.Recipes or {}) do
		if Contains( foodTable, recipeTable ) then return Recipe end
	end return false
end
FoodSystem.FindIngredient = function( self, Ingredient ) -- Remove Kebab
	for k,v in pairs(self.Recipes or {}) do
		if table.HasValue(v, Ingredient) then return k end
	end return false
end
FoodSystem.AddRecipe = function( self, Name, Recipe )
	if !Recipe or !Name then return false end
	self.Recipes[Name] = table.Copy(Recipe)
end
FoodSystem.Add = function( self, fT )
	if !fT or !fT.Name then return false end
	self.Foods[fT.Name] = table.Copy(fT)
	if CLIENT then
		if fT.Material then
			self.Foods[fT.Name].Material = Material(GM.Name.."/foods/"..fT.Material, "noclamp smooth")
		else
			self.Foods[fT.Name].Material = Material(GM.Name.."/foods/"..string.lower(fT.Name)..".png", "noclamp smooth")
		end
	end
	if fT.Recipe then self:AddRecipe(fT.Name, fT.Recipe) end
end

local root = GM.Name.."/gamemode/foods/"
local files = file.Find(root .. "*", "LUA")
for k,v in pairs(files) do if SERVER then AddCSLuaFile(root ..v) end include(root .. v) end
if SERVER then print(GM.Name..": Food Loaded.") end