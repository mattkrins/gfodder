local GM = {}

GM.Name = "Versus"
GM.Description = "Competitive cooking."
GM.Material = "overcooked/ui/gamemodes/mode_vs.png"
GM.Spectators = true
GM.Disabled = true
GM.CanPlay = function(s)
	if #player.GetAll() >= 2 then return true end
	return false
end

GamemodeSystem:Add( GM )