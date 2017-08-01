local GM = {}

GM.Name = "Practice"
GM.Description = "Practice and refine your cooking abilities."
GM.Spectators = true
GM.Teams = {1,2}

if SERVER then
	GM.DelayPlay = 2
	GM.Init = function(s)
		GamemodeSystem.Music:Add("sound/"..GAMEMODE.Name.."/music/cookin.mp3", 30)
		GamemodeSystem:ShowTimer(true)
		GamemodeSystem:ShowCoins(true)
	end
	GM.Play = function(s)
		GamemodeSystem.Clock:Add(300)
		MusicSystem:PlaySound(GAMEMODE.Name.."/gui/knife_slash.mp3")
	end
	GM.Think = function(s)
		if #GamemodeSystem.Orders <= 0 then return end
		for _,v in pairs(player.GetAll()) do
			v.Orders = v.Orders or {}
			if (v.lastOrder or 0) >= CurTime() then continue end
			OrderSystem:Add(table.Random(GamemodeSystem.Orders), v, math.random(50,70))
			v.lastOrder = CurTime()+math.random(40,50)
		end
	end
	GM.ShouldReset = function(s) if GamemodeSystem.Clock:Remaining() < 0 then return true end end
	GM.Reset = function(s)
		MusicSystem:PlaySound(GAMEMODE.Name.."/effects/ding_tripple.mp3")
	end
end

GamemodeSystem:Add( GM )