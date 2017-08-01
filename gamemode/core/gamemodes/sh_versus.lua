local GM = {}

GM.Name = "Versus"
GM.Description = "Competitive cooking."
GM.Material = "overcooked/ui/gamemodes/mode_vs.png"
GM.Spectators = true
GM.Teams = {1,2}
GM.CanPlay = function(s)
	if #player.GetAll() >= 2 then return true end
	return false
end

if SERVER then
	GM.DelayPlay = 2
	local ScoreTimer = false
	GM.Init = function(s)
		GamemodeSystem.Music:Add("sound/"..GAMEMODE.Name.."/music/cookin.mp3", 30)
		GamemodeSystem:ShowTimer(true)
		GamemodeSystem:ShowCoins(true)
	end
	GM.Play = function(s)
		GamemodeSystem.Clock:Add(300)
		MusicSystem:PlaySound(GAMEMODE.Name.."/gui/knife_slash.mp3")
	end
	local lastOrder
	GM.Think = function(s)
		if (lastOrder or 0) >= CurTime() then return end
		lastOrder = CurTime()+math.random(40,50)
		local order = table.Random(GamemodeSystem.Orders)
		local time = math.random(50,70)
		for t,p in pairs(Teams.table) do
			for _, v in pairs(p.Players or {}) do
				OrderSystem:Add(order, v, time)
			end
		end
	end
	GM.ShouldReset = function(s)
		if GamemodeSystem.Clock:Remaining() < 0 then
			if ScoreTimer and ScoreTimer < CurTime() then return true end
			if !ScoreTimer then
				ScoreTimer = CurTime() + 6
				GamemodeSystem.Music:Stop()
				GamemodeSystem:ScoreScreen()
			end
		end return false
	end
	GM.Reset = function(s)
		ScoreTimer = false
		lastOrder = 0
	end
end

GamemodeSystem:Add( GM )