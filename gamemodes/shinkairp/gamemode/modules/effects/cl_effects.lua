-- Suivi côté client des effets actifs du joueur local, et écran d'aveuglement.

local Effects = Shinkai.Effects

-- [id] = heure de fin (CurTime)
Effects.Active = Effects.Active or {}

net.Receive("Shinkai.Effect", function()
	local id = net.ReadString()
	local duration = net.ReadFloat()
	Effects.Active[id] = duration > 0 and (CurTime() + duration) or nil
end)

net.Receive("Shinkai.EffectClear", function()
	Effects.Active = {}
end)

-- Temps restant d'un effet sur le joueur local (0 s'il est inactif).
function Effects.Remaining(id)
	local ends = Effects.Active[id]
	if not ends then return 0 end
	return math.max(0, ends - CurTime())
end

-- Bombe aveuglante : l'écran devient blanc puis s'estompe sur la dernière seconde.
hook.Add("HUDPaintBackground", "Shinkai.Blind", function()
	local remaining = Effects.Remaining("blind")
	if remaining <= 0 then return end

	surface.SetDrawColor(255, 255, 255, 255 * math.min(1, remaining))
	surface.DrawRect(0, 0, ScrW(), ScrH())
end)
