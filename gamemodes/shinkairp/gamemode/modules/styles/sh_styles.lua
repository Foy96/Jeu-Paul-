-- Registre des styles de combat : les Souffles des Pourfendeurs et les arts
-- des Démons. Chaque style est déclaré dans son propre fichier du dossier
-- gamemode/styles/ avec Shinkai.Styles.Register.
--
-- Structure d'un style :
--   name, description, color
--   faction      "slayer" ou "demon"
--   costProfile  "normal" ou "high" (voir config/sh_techniques.lua)
--   modifiers    { hp, speed, endurance, attackDelay, cooldown } — multiplicateurs, 1 par défaut
--   techniques   liste ordonnée ; la position donne la touche (1, 2, 3...)
--
-- Structure d'une technique :
--   name, description
--   tier          niveau 1 à 6 (6 = ultime) : fixe dégâts, coût, recharge et grade requis
--   damage, cost, cooldown, unlockGrade   (facultatifs : remplacent le barème)
--   label         texte du niveau affiché à la place de "I", "II"... (facultatif)
--   keepInvisible true pour ne pas rompre l'invisibilité
--   execute       function(ply, tech, ctx) — exécutée côté serveur.
--                 ctx.damage = dégâts finaux, ctx.style = le style.
--                 Renvoyer false annule la technique (ni coût, ni recharge).

Shinkai.Styles = Shinkai.Styles or {}
local Styles = Shinkai.Styles

Styles.List = Styles.List or {}

function Styles.Register(id, style)
	style.id = id
	style.modifiers = style.modifiers or {}
	style.techniques = style.techniques or {}
	style.color = style.color or color_white
	style.costProfile = style.costProfile or "normal"

	for index, tech in ipairs(style.techniques) do
		tech.index = index
		tech.tier = tech.tier or 1
	end

	Styles.List[id] = style
	return style
end

function Styles.Get(id)
	return Styles.List[id]
end

-- Styles d'une faction, triés par nom.
function Styles.GetForFaction(faction)
	local result = {}
	for _, style in pairs(Styles.List) do
		if style.faction == faction then result[#result + 1] = style end
	end
	table.sort(result, function(a, b) return a.name < b.name end)
	return result
end

function Styles.GetTechnique(style, index)
	return style and style.techniques[index]
end

local function tier(tech)
	return Shinkai.Config.TechniqueTiers[tech.tier] or Shinkai.Config.TechniqueTiers[1]
end

function Styles.GetTierLabel(tech)
	return tech.label or tier(tech).label
end

-- Dégâts du barème, avant mise à l'échelle par le grade.
function Styles.GetBaseDamage(tech)
	return tech.damage or tier(tech).damage
end

function Styles.GetCost(style, tech)
	if tech.cost then return tech.cost end
	local profile = Shinkai.Config.CostProfiles[style.costProfile] or Shinkai.Config.CostProfiles.normal
	return profile[tech.tier] or 0
end

function Styles.GetCooldown(style, tech)
	return (tech.cooldown or tier(tech).cooldown) * (style.modifiers.cooldown or 1)
end

function Styles.GetUnlockGrade(tech)
	return tech.unlockGrade or tier(tech).unlock
end

function Styles.IsUnlocked(ply, tech)
	return ply:GetGradeIndex() >= Styles.GetUnlockGrade(tech)
end

-- Particularités d'un style sous forme de phrases, pour les menus.
function Styles.DescribeModifiers(style)
	local mods = style.modifiers
	local lines = {}

	local function percent(value)
		return math.Round(math.abs(value - 1) * 100) .. " %"
	end

	if mods.speed and mods.speed ~= 1 then
		lines[#lines + 1] = (mods.speed > 1 and "+" or "-") .. percent(mods.speed) .. " de vitesse"
	end
	if mods.hp and mods.hp ~= 1 then
		lines[#lines + 1] = (mods.hp > 1 and "+" or "-") .. percent(mods.hp) .. " de PV"
	end
	if mods.endurance and mods.endurance ~= 1 then
		lines[#lines + 1] = (mods.endurance > 1 and "+" or "-") .. percent(mods.endurance) .. " d'endurance"
	end
	if mods.attackDelay and mods.attackDelay ~= 1 then
		lines[#lines + 1] = "Coups de base " .. percent(mods.attackDelay) .. (mods.attackDelay < 1 and " plus rapides" or " plus lents")
	end
	if mods.cooldown and mods.cooldown ~= 1 then
		lines[#lines + 1] = "Recharges " .. (mods.cooldown < 1 and "réduites" or "allongées") .. " de " .. percent(mods.cooldown)
	end
	if style.costProfile == "high" then
		lines[#lines + 1] = "Techniques plus coûteuses en endurance"
	end
	if #lines == 0 then
		lines[1] = "Statistiques normales"
	end
	return lines
end
