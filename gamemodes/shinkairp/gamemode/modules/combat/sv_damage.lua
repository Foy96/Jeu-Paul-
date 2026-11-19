-- Règles de dégâts : tir allié, garde, régénération des Démons.

local GM = GM or GAMEMODE
local C = Shinkai.Config

function GM:PlayerShouldTakeDamage(ply, attacker)
	if not ply:HasCharacter() then return false end

	if IsValid(attacker) and attacker:IsPlayer() and attacker ~= ply then
		if not attacker:HasCharacter() then return false end
		if not C.Combat.FriendlyFire and ply:IsAllyOf(attacker) then return false end
	end
	return true
end

hook.Add("EntityTakeDamage", "Shinkai.Guard", function(target, info)
	if not target:IsPlayer() then return end

	target.ShinkaiLastHurt = CurTime()

	-- Garde : réduit les dégâts venant de face, contre de l'endurance.
	local attacker = info:GetAttacker()
	if not target:IsGuarding() or not IsValid(attacker) or attacker == target then return end
	if info:IsDamageType(DMG_POISON) then return end
	if hook.Run("PlayerShouldTakeDamage", target, attacker) == false then return end

	local toAttacker = attacker:WorldSpaceCenter() - target:WorldSpaceCenter()
	toAttacker.z = 0
	toAttacker:Normalize()
	if Shinkai.Util.FlatAim(target):Dot(toAttacker) < 0.3 then return end

	if not Shinkai.Stamina.CanAfford(target, C.Guard.StaminaPerHit) then return end
	Shinkai.Stamina.Take(target, C.Guard.StaminaPerHit)

	info:ScaleDamage(1 - C.Guard.Reduction)
	target:EmitSound("physics/metal/metal_solid_impact_bullet" .. math.random(1, 4) .. ".wav", 70, 110)
end)

-- Régénération passive des Démons hors combat.
timer.Create("Shinkai.DemonRegen", 1, 0, function()
	local cfg = C.DemonRegen
	if not cfg.Enabled then return end

	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() and ply:HasCharacter() and ply:GetFaction() == "demon"
			and ply:Health() < ply:GetMaxHealth()
			and CurTime() - (ply.ShinkaiLastHurt or 0) >= cfg.DelayAfterDamage then
			Shinkai.Actions.Heal(ply, math.max(1, ply:GetMaxHealth() * cfg.PercentPerSecond))
		end
	end
end)
