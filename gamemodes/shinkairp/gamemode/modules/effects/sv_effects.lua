-- Application et suivi des effets temporaires sur les joueurs.

local Effects = Shinkai.Effects

local function notifyClient(ply, id, duration)
	net.Start("Shinkai.Effect")
	net.WriteString(id)
	net.WriteFloat(duration)
	net.Send(ply)
end

-- Applique un effet pendant `duration` secondes. `data` est une table libre
-- transmise aux fonctions de l'effet. Réappliquer un effet le renouvelle.
function Effects.Apply(ply, id, duration, data)
	local def = Effects.List[id]
	if not def or not IsValid(ply) or not ply:Alive() then return false end

	ply.ShinkaiEffects = ply.ShinkaiEffects or {}
	if ply.ShinkaiEffects[id] then
		Effects.Remove(ply, id, true)
	end

	data = data or {}
	ply.ShinkaiEffects[id] = {
		ends = CurTime() + duration,
		data = data,
		nextTick = CurTime() + (def.tickInterval or 0),
	}

	if def.onStart then def.onStart(ply, data) end
	if def.modifyStats then Shinkai.Stats.Apply(ply) end

	notifyClient(ply, id, duration)
	return true
end

-- `silent` : interne, utilisé lors d'un renouvellement.
function Effects.Remove(ply, id, silent)
	local active = ply.ShinkaiEffects and ply.ShinkaiEffects[id]
	if not active then return end

	local def = Effects.List[id]
	ply.ShinkaiEffects[id] = nil

	if def.onEnd then def.onEnd(ply, active.data) end
	if def.modifyStats and not silent then Shinkai.Stats.Apply(ply) end
	if not silent then notifyClient(ply, id, 0) end
end

function Effects.Has(ply, id)
	return ply.ShinkaiEffects ~= nil and ply.ShinkaiEffects[id] ~= nil
end

-- Retire tous les effets (mort, changement de personnage).
function Effects.Clear(ply)
	if not ply.ShinkaiEffects then return end

	local needsStats = false
	for id, active in pairs(ply.ShinkaiEffects) do
		local def = Effects.List[id]
		ply.ShinkaiEffects[id] = nil
		if def.onEnd then def.onEnd(ply, active.data) end
		if def.modifyStats then needsStats = true end
	end

	if needsStats and ply.ShinkaiChar then Shinkai.Stats.Apply(ply) end

	net.Start("Shinkai.EffectClear")
	net.Send(ply)
end

-- Les effets actifs modifient les statistiques du joueur.
hook.Add("ShinkaiModifyStats", "Shinkai.Effects", function(ply, stats)
	for id, active in pairs(ply.ShinkaiEffects or {}) do
		local def = Effects.List[id]
		if def.modifyStats then def.modifyStats(ply, stats, active.data) end
	end
end)

timer.Create("Shinkai.Effects", 0.1, 0, function()
	local now = CurTime()

	for _, ply in ipairs(player.GetAll()) do
		for id, active in pairs(ply.ShinkaiEffects or {}) do
			local def = Effects.List[id]

			-- Le tick passe avant l'expiration pour que le dernier ne soit pas perdu
			-- (un effet de 8 s à 1 tick/s agit bien 8 fois).
			if def.onTick and def.tickInterval and now >= active.nextTick - 0.01 then
				active.nextTick = active.nextTick + def.tickInterval
				def.onTick(ply, active.data)
			end

			if now >= active.ends and ply.ShinkaiEffects[id] == active then
				Effects.Remove(ply, id)
			end
		end
	end
end)
