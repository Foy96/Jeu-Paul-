-- Utilisation des techniques : vérifications, coût en endurance, recharge.

local Techniques = Shinkai.Techniques
local Styles = Shinkai.Styles
local Stamina = Shinkai.Stamina

function Techniques.ResetCooldowns(ply)
	ply.ShinkaiCooldowns = {}
	net.Start("Shinkai.CooldownReset")
	net.Send(ply)
end

-- Temps de recharge restant d'une technique (0 si disponible).
function Techniques.GetCooldown(ply, index)
	local ends = ply.ShinkaiCooldowns and ply.ShinkaiCooldowns[index] or 0
	return math.max(0, ends - CurTime())
end

function Techniques.SetCooldown(ply, index, duration)
	ply.ShinkaiCooldowns = ply.ShinkaiCooldowns or {}
	ply.ShinkaiCooldowns[index] = CurTime() + duration

	net.Start("Shinkai.Cooldown")
	net.WriteUInt(index, 4)
	net.WriteFloat(duration)
	net.Send(ply)
end

-- Renvoie le style et la technique si le joueur peut l'utiliser maintenant.
function Techniques.CanUse(ply, index)
	if not ply:Alive() or not ply:HasCharacter() or ply:IsStunned() then return end
	if not ply:HoldsShinkaiWeapon() then return end
	if (ply.ShinkaiNextTechnique or 0) > CurTime() then return end

	local style = ply:GetStyle()
	local tech = Styles.GetTechnique(style, index)
	if not tech or not tech.execute then return end

	if not Styles.IsUnlocked(ply, tech) then return end
	if Techniques.GetCooldown(ply, index) > 0 then return end
	if not Stamina.CanAfford(ply, Styles.GetCost(style, tech)) then return end

	if hook.Run("ShinkaiCanUseTechnique", ply, style, tech) == false then return end
	return style, tech
end

function Techniques.Use(ply, index)
	local style, tech = Techniques.CanUse(ply, index)
	if not style then return false end

	local ctx = {
		style = style,
		damage = Shinkai.Stats.ScaleTechniqueDamage(ply, Styles.GetBaseDamage(tech)),
	}

	-- Une technique qui renvoie false (ex. : aucune cible) n'est pas consommée.
	local result, message = tech.execute(ply, tech, ctx)
	if result == false then
		if message then Shinkai.Notify(ply, message, Shinkai.NOTIFY_ERROR) end
		return false
	end

	if not tech.keepInvisible and ply:IsInvisible() and Shinkai.Config.Combat.BreakInvisOnAttack then
		Shinkai.Effects.Remove(ply, "invisible")
	end

	Stamina.Take(ply, Styles.GetCost(style, tech))
	Techniques.SetCooldown(ply, index, Styles.GetCooldown(style, tech))
	ply.ShinkaiNextTechnique = CurTime() + Shinkai.Config.Combat.GlobalCooldown

	hook.Run("ShinkaiTechniqueUsed", ply, style, tech)
	return true
end

net.Receive("Shinkai.UseTechnique", function(_, ply)
	Techniques.Use(ply, net.ReadUInt(4))
end)
