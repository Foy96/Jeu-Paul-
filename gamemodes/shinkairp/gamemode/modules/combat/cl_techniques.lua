-- Côté client : touches des techniques et suivi des temps de recharge.
--
-- Les techniques se lancent avec les touches de sélection d'arme (1 à 9 par
-- défaut) quand l'arme de combat est en main. Pour d'autres touches :
--   bind <touche> "shinkai_technique 3"

local Techniques = Shinkai.Techniques

-- [index] = { ends = heure de fin, duration = durée totale }
Techniques.Cooldowns = Techniques.Cooldowns or {}

-- Dernière technique lancée, affichée brièvement par le HUD.
Techniques.LastCast = Techniques.LastCast or { name = "", time = 0 }

function Techniques.Request(index)
	if not index or index < 1 or index > 15 then return end
	net.Start("Shinkai.UseTechnique")
	net.WriteUInt(index, 4)
	net.SendToServer()
end

-- Temps de recharge restant et durée totale.
function Techniques.GetCooldown(index)
	local cooldown = Techniques.Cooldowns[index]
	if not cooldown then return 0, 1 end
	return math.max(0, cooldown.ends - CurTime()), cooldown.duration
end

net.Receive("Shinkai.Cooldown", function()
	local index = net.ReadUInt(4)
	local duration = net.ReadFloat()
	Techniques.Cooldowns[index] = { ends = CurTime() + duration, duration = duration }

	local style = LocalPlayer():GetStyle()
	local tech = Shinkai.Styles.GetTechnique(style, index)
	if tech then
		Techniques.LastCast = { name = tech.name, time = CurTime(), color = style.color }
	end
end)

net.Receive("Shinkai.CooldownReset", function()
	Techniques.Cooldowns = {}
end)

concommand.Add("shinkai_technique", function(_, _, args)
	Techniques.Request(tonumber(args[1]))
end)

-- Les touches "slot1", "slot2"... lancent les techniques au lieu de changer d'arme.
hook.Add("PlayerBindPress", "Shinkai.Techniques", function(ply, bind, pressed)
	if not pressed or not ply:HoldsShinkaiWeapon() then return end

	local slot = tonumber(string.match(string.lower(bind), "^slot(%d+)$"))
	if not slot then return end

	local style = ply:GetStyle()
	if style and style.techniques[slot] then
		Techniques.Request(slot)
	end
	return true
end)
