-- Définition des effets temporaires utilisés par les techniques.
-- Ajouter un effet = un Effects.Register de plus ; il devient utilisable
-- partout avec Shinkai.Effects.Apply(ply, "id", durée, données).

local Effects = Shinkai.Effects
local C = Shinkai.Config

-- Paralysie : le joueur ne peut plus bouger ni attaquer (voir combat/sh_combat.lua).
Effects.Register("stun", {
	name = "Paralysie",
	color = Color(255, 230, 80),
	negative = true,
	onStart = function(ply)
		ply:SetNW2Float("ShinkaiStunEnd", CurTime() + 3600)
	end,
	onEnd = function(ply)
		ply:SetNW2Float("ShinkaiStunEnd", 0)
	end,
})

-- Aveuglement : écran blanc, géré côté client (effects/cl_effects.lua).
Effects.Register("blind", {
	name = "Aveuglement",
	color = Color(255, 255, 255),
	negative = true,
})

-- Invisibilité : le joueur, son arme et ses pas disparaissent.
local function setHidden(ply, hidden)
	ply:SetNoDraw(hidden)
	ply:DrawShadow(not hidden)
	ply:SetNoTarget(hidden) -- ignoré par les PNJ
	ply:SetNW2Bool("ShinkaiInvisible", hidden)

	for _, weapon in ipairs(ply:GetWeapons()) do
		weapon:SetNoDraw(hidden)
	end
end

Effects.Register("invisible", {
	name = "Invisibilité",
	color = Color(170, 200, 220),
	onStart = function(ply) setHidden(ply, true) end,
	onEnd = function(ply) setHidden(ply, false) end,
})

-- Mode Rage : vitesse (bonus fixe) et dégâts augmentés, PV max diminués.
Effects.Register("rage", {
	name = "Mode Rage",
	color = Color(255, 60, 40),
	modifyStats = function(_, stats)
		stats.speed = stats.speed + C.Rage.SpeedBonus
		stats.damage = stats.damage * C.Rage.DamageMult
		stats.hp = stats.hp * (1 - C.Rage.HPPenalty)
	end,
})

-- Régénération : soin progressif. data.perTick = PV rendus chaque seconde.
Effects.Register("regen", {
	name = "Régénération",
	color = Color(255, 150, 200),
	tickInterval = 1,
	onTick = function(ply, data)
		Shinkai.Actions.Heal(ply, data.perTick or 0)
	end,
})

-- Poison : dégâts réguliers. data.perTick = dégâts, data.attacker = responsable.
Effects.Register("poison", {
	name = "Poison",
	color = Color(160, 90, 220),
	negative = true,
	tickInterval = 1,
	onTick = function(ply, data)
		local attacker = IsValid(data.attacker) and data.attacker or game.GetWorld()
		Shinkai.Actions.Hurt(attacker, ply, data.perTick or 0, DMG_POISON)
	end,
})

-- Célérité : data.bonus = points de VIT ajoutés.
Effects.Register("haste", {
	name = "Célérité",
	color = Color(120, 220, 255),
	modifyStats = function(_, stats, data)
		stats.speed = stats.speed + (data.bonus or 20)
	end,
})

-- Puissance : data.mult = multiplicateur de dégâts.
Effects.Register("power", {
	name = "Puissance",
	color = Color(255, 170, 60),
	modifyStats = function(_, stats, data)
		stats.damage = stats.damage * (data.mult or 1.25)
	end,
})

-- Ralentissement : data.mult = multiplicateur de VIT (0.5 = moitié).
Effects.Register("slow", {
	name = "Ralentissement",
	color = Color(120, 140, 255),
	negative = true,
	modifyStats = function(_, stats, data)
		stats.speed = stats.speed * (data.mult or 0.6)
	end,
})
