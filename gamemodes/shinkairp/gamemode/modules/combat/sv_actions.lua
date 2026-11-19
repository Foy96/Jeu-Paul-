-- Bibliothèque d'actions de combat.
-- Les techniques des Souffles sont construites avec ces briques : frapper
-- devant soi, onde de choc, dash, propulsion, téléportation, soin...
-- Dans les fonctions ci-dessous, `ctx` est le contexte reçu par la technique
-- (ctx.damage = dégâts finaux, ctx.style = style utilisé).

local Actions = Shinkai.Actions
local Util = Shinkai.Util

local SOUNDS = {
	[Actions.FX_SLASH] = "npc/zombie/claw_miss1.wav",
	[Actions.FX_BURST] = "weapons/physcannon/energy_sing_explosion2.wav",
	[Actions.FX_DASH] = "weapons/physcannon/superphys_launch1.wav",
	[Actions.FX_AURA] = "items/medshot4.wav",
}

---------------------------------------------------------------------------
-- Effets visuels et sonores
---------------------------------------------------------------------------
function Actions.FX(kind, pos, dir, color, scale)
	net.Start("Shinkai.FX")
	net.WriteUInt(kind, 3)
	net.WriteVector(pos)
	net.WriteNormal(dir or vector_up)
	net.WriteColor(color or color_white)
	net.WriteFloat(scale or 1)
	net.SendPVS(pos)

	if SOUNDS[kind] then
		sound.Play(SOUNDS[kind], pos, 75, math.random(95, 110))
	end
end

-- Animation d'attaque du joueur et de son arme.
local function swing(ply)
	ply:SetAnimation(PLAYER_ATTACK1)
	local weapon = ply:GetActiveWeapon()
	if IsValid(weapon) and weapon.PlaySwing then weapon:PlaySwing() end
end

---------------------------------------------------------------------------
-- Cibles
---------------------------------------------------------------------------
function Actions.IsCombatant(ent)
	if not IsValid(ent) then return false end
	if ent:IsPlayer() then return ent:Alive() and ent:HasCharacter() end
	return ent:IsNPC() or ent:IsNextBot()
end

function Actions.IsEnemy(ply, ent)
	if ent == ply or not Actions.IsCombatant(ent) then return false end
	if not ent:IsPlayer() then return true end
	return Shinkai.Config.Combat.FriendlyFire or not ply:IsAllyOf(ent)
end

function Actions.IsAlly(ply, ent)
	return IsValid(ent) and ent ~= ply and ent:IsPlayer() and ent:Alive() and ply:IsAllyOf(ent)
end

function Actions.HasLineOfSight(ply, ent)
	local tr = util.TraceLine({
		start = ply:EyePos(),
		endpos = ent:WorldSpaceCenter(),
		filter = { ply, ent },
		mask = MASK_SOLID_BRUSHONLY,
	})
	return not tr.Hit
end

-- Ennemis dans un cône devant le joueur. minDot : 1 = pile en face, 0 = 180°.
function Actions.GetEnemiesInCone(ply, range, minDot)
	local origin = ply:EyePos()
	local aim = ply:GetAimVector()
	local result = {}

	for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), range)) do
		if Actions.IsEnemy(ply, ent) then
			local offset = ent:WorldSpaceCenter() - origin
			local close = offset:LengthSqr() < 60 * 60
			if (close or aim:Dot(offset:GetNormalized()) >= minDot) and Actions.HasLineOfSight(ply, ent) then
				result[#result + 1] = ent
			end
		end
	end
	return result
end

function Actions.GetEnemiesInSphere(ply, pos, radius)
	local result = {}
	for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
		if Actions.IsEnemy(ply, ent) then result[#result + 1] = ent end
	end
	return result
end

-- Alliés autour d'un point (le joueur lui-même n'est pas inclus).
function Actions.GetAlliesInSphere(ply, pos, radius)
	local result = {}
	for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
		if Actions.IsAlly(ply, ent) then result[#result + 1] = ent end
	end
	return result
end

-- Cible visée : l'entité sous le viseur, sinon la plus proche de l'axe du regard.
-- `predicate(ent)` filtre les cibles acceptables.
function Actions.AimTarget(ply, range, predicate)
	local tr = ply:GetEyeTrace()
	if IsValid(tr.Entity) and predicate(tr.Entity) and tr.HitPos:DistToSqr(ply:EyePos()) <= range * range then
		return tr.Entity
	end

	local origin = ply:EyePos()
	local aim = ply:GetAimVector()
	local best, bestDot = nil, 0.9

	for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), range)) do
		if ent ~= ply and predicate(ent) then
			local dot = aim:Dot((ent:WorldSpaceCenter() - origin):GetNormalized())
			if dot > bestDot and Actions.HasLineOfSight(ply, ent) then
				best, bestDot = ent, dot
			end
		end
	end
	return best
end

function Actions.AimEnemy(ply, range)
	return Actions.AimTarget(ply, range, function(ent) return Actions.IsEnemy(ply, ent) end)
end

function Actions.AimAlly(ply, range)
	return Actions.AimTarget(ply, range, function(ent) return Actions.IsAlly(ply, ent) end)
end

---------------------------------------------------------------------------
-- Dégâts, soins, poussées
---------------------------------------------------------------------------
function Actions.Hurt(attacker, target, amount, damageType)
	if amount <= 0 or not IsValid(target) then return end

	if attacker:IsPlayer() and attacker:IsInvisible() and Shinkai.Config.Combat.BreakInvisOnAttack then
		Shinkai.Effects.Remove(attacker, "invisible")
	end

	local weapon = attacker:IsPlayer() and attacker:GetActiveWeapon() or nil
	local info = DamageInfo()
	info:SetDamage(amount)
	info:SetAttacker(attacker)
	info:SetInflictor(IsValid(weapon) and weapon or attacker)
	info:SetDamageType(damageType or DMG_SLASH)
	info:SetDamagePosition(target:WorldSpaceCenter())
	target:TakeDamageInfo(info)
end

-- Rend des PV sans dépasser le maximum. Renvoie les PV réellement rendus.
function Actions.Heal(target, amount)
	if not IsValid(target) or not target:Alive() then return 0 end
	local before = target:Health()
	target:SetHealth(math.min(target:GetMaxHealth(), before + math.Round(amount)))
	return target:Health() - before
end

-- Repousse `target` à l'opposé de `origin`.
function Actions.Knockback(origin, target, force, up)
	local dir = target:GetPos() - origin
	dir.z = 0
	if dir:LengthSqr() < 1 then dir = Vector(1, 0, 0) end
	dir:Normalize()

	if target:IsPlayer() then target:SetGroundEntity(NULL) end
	target:SetVelocity(dir * force + Vector(0, 0, up or 220))
end

-- Applique un coup de technique sur une cible, avec les options communes :
--   mult       multiplicateur des dégâts de la technique (défaut 1)
--   knockback  force de recul        up  poussée verticale du recul
--   effect     { id = "stun", duration = 2, data = {...} } appliqué aux joueurs touchés
--   onHit      function(target) appelée pour chaque cible
local function strike(ply, ctx, target, opts)
	Actions.Hurt(ply, target, ctx.damage * (opts.mult or 1))

	if not IsValid(target) then return end
	if opts.knockback then
		Actions.Knockback(ply:GetPos(), target, opts.knockback, opts.up)
	end
	if opts.effect and target:IsPlayer() and target:Alive() then
		Shinkai.Effects.Apply(target, opts.effect.id, opts.effect.duration, opts.effect.data)
	end
	if opts.onHit then opts.onHit(target) end
end

---------------------------------------------------------------------------
-- Attaques
---------------------------------------------------------------------------

-- Frappe les ennemis dans un cône devant le joueur.
--   range (130), cone (0.45) + options de coup. Renvoie la liste des cibles.
function Actions.Slash(ply, ctx, opts)
	opts = opts or {}
	local range = opts.range or 130
	local targets = Actions.GetEnemiesInCone(ply, range, opts.cone or 0.45)

	for _, target in ipairs(targets) do
		strike(ply, ctx, target, opts)
	end

	swing(ply)
	Actions.FX(Actions.FX_SLASH, ply:GetShootPos() + ply:GetAimVector() * 40, ply:GetAimVector(), ctx.style.color, range / 130)
	return targets
end

-- Enchaîne `hits` frappes espacées de `interval` secondes.
-- Les dégâts de la technique (x opts.mult) sont répartis entre les frappes.
function Actions.Combo(ply, ctx, hits, interval, opts)
	opts = table.Copy(opts or {})
	opts.mult = (opts.mult or 1) / hits

	for i = 0, hits - 1 do
		timer.Simple(i * interval, function()
			if IsValid(ply) and ply:Alive() and not ply:IsStunned() then
				Actions.Slash(ply, ctx, opts)
			end
		end)
	end
end

-- Onde de choc autour d'un point (par défaut le joueur).
--   radius (220), pos + options de coup. Renvoie la liste des cibles.
function Actions.Burst(ply, ctx, opts)
	opts = opts or {}
	local radius = opts.radius or 220
	local pos = opts.pos or ply:WorldSpaceCenter()
	local targets = Actions.GetEnemiesInSphere(ply, pos, radius)

	for _, target in ipairs(targets) do
		strike(ply, ctx, target, opts)
	end

	swing(ply)
	Actions.FX(Actions.FX_BURST, pos, vector_up, ctx.style.color, radius / 220)
	return targets
end

---------------------------------------------------------------------------
-- Déplacements
---------------------------------------------------------------------------

-- Projette le joueur dans la direction horizontale de son regard.
function Actions.Dash(ply, speed, up)
	local velocity = Util.FlatAim(ply) * speed + Vector(0, 0, up or 100)
	ply:SetGroundEntity(NULL)
	ply:SetVelocity(velocity - ply:GetVelocity())
end

-- Dash qui frappe une fois chaque ennemi croisé.
--   speed (1200), up (100), duration (0.4), radius (90) + options de coup.
function Actions.DashStrike(ply, ctx, opts)
	opts = opts or {}
	Actions.Dash(ply, opts.speed or 1200, opts.up)
	swing(ply)
	Actions.FX(Actions.FX_DASH, ply:WorldSpaceCenter(), Util.FlatAim(ply), ctx.style.color, (opts.speed or 1200) / 1200)

	local alreadyHit = {}
	local name = "Shinkai.Dash." .. ply:EntIndex()

	timer.Create(name, 0.05, math.ceil((opts.duration or 0.4) / 0.05), function()
		if not IsValid(ply) or not ply:Alive() then
			timer.Remove(name)
			return
		end
		for _, target in ipairs(Actions.GetEnemiesInSphere(ply, ply:WorldSpaceCenter(), opts.radius or 90)) do
			if not alreadyHit[target] then
				alreadyHit[target] = true
				strike(ply, ctx, target, opts)
			end
		end
	end)
end

-- Propulse le joueur vers le haut (et éventuellement vers l'avant).
function Actions.Launch(ply, up, forward)
	local velocity = Util.FlatAim(ply) * (forward or 0) + Vector(0, 0, up)
	ply:SetGroundEntity(NULL)
	ply:SetVelocity(velocity - ply:GetVelocity())
end

-- Téléporte le joueur près d'une cible, face à elle.
--   side : "behind" (dans son dos) ou "front" (devant elle).
-- Renvoie false si aucune place libre n'est trouvée.
function Actions.TeleportNear(ply, target, side, distance)
	local yaw = target:IsPlayer() and target:EyeAngles().y or target:GetAngles().y
	local dir = Angle(0, yaw, 0):Forward()
	if side == "behind" then dir = -dir end

	local mins, maxs = ply:GetHull()

	for _, dist in ipairs({ distance or 60, 45, 90 }) do
		local pos = target:GetPos() + dir * dist + Vector(0, 0, 4)
		local hull = util.TraceHull({
			start = pos, endpos = pos, mins = mins, maxs = maxs,
			filter = { ply, target }, mask = MASK_PLAYERSOLID,
		})
		local wall = util.TraceLine({
			start = target:WorldSpaceCenter(),
			endpos = pos + Vector(0, 0, 32),
			filter = { ply, target },
			mask = MASK_SOLID_BRUSHONLY,
		})

		if not hull.Hit and not wall.Hit then
			local from = ply:WorldSpaceCenter()
			ply:SetPos(pos)
			ply:SetLocalVelocity(vector_origin)
			ply:SetEyeAngles((target:WorldSpaceCenter() - ply:EyePos()):Angle())

			local color = ply:GetStyle() and ply:GetStyle().color or color_white
			Actions.FX(Actions.FX_AURA, from, vector_up, color, 1)
			Actions.FX(Actions.FX_AURA, ply:WorldSpaceCenter(), vector_up, color, 1)
			return true
		end
	end
	return false
end
