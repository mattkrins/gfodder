local GM = {}

GM.Name = "Practice"
GM.Description = "Practice and refine your cooking abilities."
GM.Material = "overcooked/ui/gamemodes/mode_practice.png"
GM.Spectators = true
GM.Teams = {"Apprentices","test1","test2"}

if CLIENT then
	local StopwatchMaterial = Material( "overcooked/ui/stopwatch.png", "noclamp smooth" )
	GM.HUDPaint = function(s)
		
	end
end
if SERVER then
	GM.DelayPlay = 2
	local lastOrder
	GM.Init = function(s)
		GamemodeSystem.Music:Add("sound/"..GAMEMODE.Name.."/music/cookin.mp3", 30)
		lastOrder = CurTime()+s.DelayPlay+4
		GamemodeSystem:ShowTimer(true)
		GamemodeSystem:ShowCoins(true)
		// generate orders
		// search ents find in tab orderitems
		// 
	end
	GM.Play = function(s)
		GamemodeSystem.Clock:Add(40)
		MusicSystem:PlaySound("overcooked/ding_tripple.mp3")
	end
	local maxOrders = 6
	GM.Think = function(s)
		if #GamemodeSystem.Orders <= 0 then return end
		for _,v in pairs(player.GetAll()) do
			v.Orders = v.Orders or {}
			if (#v.Orders or 0) >= maxOrders then continue end
			if (lastOrder or 0) >= CurTime() then continue end
			OrderSystem:Add(table.Random(GamemodeSystem.Orders), v, math.random(30,40))
			lastOrder = CurTime()+math.random(8,5)
		end
	end
	GM.ShouldReset = function(s) if GamemodeSystem.Clock:Remaining() < 0 then return true end end
	GM.Reset = function(s)
		GamemodeSystem.Music:Stop()
		MusicSystem:PlaySound("overcooked/ding_tripple.mp3")
		//MusicSystem:PlaySound("overcooked/victory_large.mp3")
	end
end

GamemodeSystem:Add( GM )