-- Règles de combat partagées (prédites par le client).

-- Paralysie : le joueur peut tourner la tête mais plus bouger ni agir.
hook.Add("StartCommand", "Shinkai.Stun", function(ply, cmd)
	if ply:IsStunned() then
		cmd:ClearMovement()
		cmd:ClearButtons()
	end
end)

-- Un joueur invisible ne fait pas de bruit de pas.
hook.Add("PlayerFootstep", "Shinkai.Invisible", function(ply)
	if ply:IsInvisible() then return true end
end)
