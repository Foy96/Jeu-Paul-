-- Statistiques : PV, Dégâts, END, VIT.
-- Valeur finale = grade x modificateurs du Souffle, puis effets temporaires.
--
-- Pour qu'un autre système modifie les statistiques, il suffit d'un hook :
--   hook.Add("ShinkaiModifyStats", "MonSysteme", function(ply, stats)
--       stats.damage = stats.damage * 1.1
--   end)
-- (ne rien renvoyer), puis d'appeler Shinkai.Stats.Apply(ply) quand la
-- situation du joueur change.

Shinkai.Stats = Shinkai.Stats or {}
local Stats = Shinkai.Stats
local C = Shinkai.Config

function Stats.Compute(ply)
	local grade = ply:GetGradeData()
	if not grade then return nil end

	local stats = {
		hp = grade.hp,
		damage = grade.damage,
		endurance = grade.endurance,
		speed = grade.speed,
	}

	local style = ply:GetStyle()
	if style then
		local mods = style.modifiers
		stats.hp = stats.hp * (mods.hp or 1)
		stats.endurance = stats.endurance * (mods.endurance or 1)
		stats.speed = stats.speed * (mods.speed or 1)
	end

	hook.Run("ShinkaiModifyStats", ply, stats)

	stats.hp = math.max(1, math.Round(stats.hp))
	stats.endurance = math.max(1, math.Round(stats.endurance))
	stats.speed = math.max(10, stats.speed)
	return stats
end

-- Recalcule et applique les statistiques. fullHeal remet les PV au maximum.
function Stats.Apply(ply, fullHeal)
	local stats = Stats.Compute(ply)
	if not stats then return end
	ply.ShinkaiStats = stats

	ply:SetMaxHealth(stats.hp)
	if ply:Alive() then
		ply:SetHealth(fullHeal and stats.hp or math.min(ply:Health(), stats.hp))
	end

	local factor = stats.speed / 100
	local walk = C.BaseWalkSpeed * factor
	ply:SetWalkSpeed(walk)
	ply:SetRunSpeed(ply.ShinkaiExhausted and walk or C.BaseRunSpeed * factor)
	ply:SetJumpPower(C.BaseJumpPower * (1 + (factor - 1) * 0.5))

	ply:SetNW2Int("ShinkaiMaxStamina", stats.endurance)
	Shinkai.Stamina.Set(ply, Shinkai.Stamina.Get(ply))
end

function Stats.Get(ply)
	return ply.ShinkaiStats
end

-- Dégâts d'un coup de base.
function Stats.GetDamage(ply)
	return ply.ShinkaiStats and ply.ShinkaiStats.damage or 0
end

-- Dégâts finaux d'une technique à partir de sa valeur du barème.
function Stats.ScaleTechniqueDamage(ply, baseDamage)
	if C.Combat.DamageMode == "flat" then return baseDamage end
	return baseDamage * Stats.GetDamage(ply) / C.Combat.DamageReference
end
