-- Souffle de l'Insecte — léger bonus de vitesse (inférieur à la Foudre).
-- Troisième mouvement : soin IMMÉDIAT, sur soi ou sur un allié ciblé.

local Act = Shinkai.Actions

local HEAL_RANGE = 400
local HEAL_PERCENT = 0.25 -- part des PV max de la cible rendue instantanément

Shinkai.Styles.Register("insecte", {
	name = "Souffle de l'Insecte",
	faction = "slayer",
	color = Color(180, 130, 255),
	description = "Un style vif et précis. Son remède soigne instantanément, et son ultime empoisonne.",

	modifiers = { speed = 1.07 },

	techniques = {
		{
			name = "Caprice du papillon", tier = 1,
			description = "Une piqûre rapide.",
			execute = function(ply, tech, ctx) Act.Slash(ply, ctx, { cone = 0.6 }) end,
		},
		{
			name = "Dard de l'abeille", tier = 2,
			description = "Fond sur sa cible en un éclair.",
			execute = function(ply, tech, ctx) Act.DashStrike(ply, ctx, { speed = 1300, duration = 0.3 }) end,
		},
		{
			name = "Remède du papillon", tier = 3, damage = 0, cost = 40, cooldown = 20,
			description = "Soin immédiat de 25 % des PV. Visez un allié pour le soigner, sinon le soin s'applique à vous-même.",
			execute = function(ply, tech, ctx)
				local target = Act.AimAlly(ply, HEAL_RANGE) or ply
				if target:Health() >= target:GetMaxHealth() then
					return false, "La cible n'a pas besoin de soins."
				end

				Act.Heal(target, target:GetMaxHealth() * HEAL_PERCENT)
				Act.FX(Act.FX_AURA, target:WorldSpaceCenter(), vector_up, Color(120, 255, 140))
				if target ~= ply then
					Shinkai.Notify(target, ply:GetRPName() .. " vous a soigné.", Shinkai.NOTIFY_SUCCESS)
				end
			end,
		},
		{
			name = "Vol de la libellule", tier = 4,
			description = "Un bond aérien qui frappe en piqué.",
			execute = function(ply, tech, ctx) Act.DashStrike(ply, ctx, { speed = 1000, up = 320, duration = 0.6 }) end,
		},
		{
			name = "Danse du mille-pattes", tier = 5,
			description = "Quatre piqûres en zigzag.",
			execute = function(ply, tech, ctx) Act.Combo(ply, ctx, 4, 0.12) end,
		},
		{
			name = "Essaim venimeux", tier = 6,
			description = "Frappe la zone et empoisonne les ennemis touchés pendant 5 secondes.",
			execute = function(ply, tech, ctx)
				Act.Burst(ply, ctx, {
					radius = 280,
					mult = 0.7,
					effect = { id = "poison", duration = 5, data = { perTick = ctx.damage * 0.08, attacker = ply } },
				})
			end,
		},
	},
})
