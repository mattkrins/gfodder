local Include = {}
Include.Mounted = {Folders={},Files={}}
Include.Files = function(self, directory, sF)
	if table.HasValue(self.Mounted.Files, directory) then return end
	table.insert(self.Mounted.Files, directory)
	local files, folders = file.Find(directory .. "*", "GAME")
	for k,v in pairs(files) do
		resource.AddFile( directory ..v )
	end
	if !sF then return end
	for k,v in pairs(folders) do
		self:Folders(directory..v.."/", true)
	end
end

Include.Folders = function(self, directory)
	if table.HasValue(self.Mounted.Folders, directory) then return end
	table.insert(self.Mounted.Folders, directory)
	self:Files(directory)
	local _, folders = file.Find(directory .. "*", "GAME")
	if !folders or #folders <= 0 then return end
	for k,v in pairs(folders) do
		self:Files(directory.."/"..v.."/", true)
	end
	return folders
end
print(GM.Name..": Content Mounted.")
Include:Folders("gamemodes/"..GM.Name.."/content/")