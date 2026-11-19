-- Souffle de la Fleur — même bonus de vitesse que l'Insecte.
-- Troisième mouvement : soin PROGRESSIF, sur soi ou sur un allié ciblé
-- (au total plus fort que le soin de l'Insecte, mais étalé dans le temps).

local Act = Shinkai.Actions

local HEAL_RANGE = 400
local HEAL_DURATION = 8
local HEAL_PERCENT_PER_SECOND = 0.05 -- 40 % des PV max sur toute la durée

local function bloom(target, duration, percentPerSecond)
	Shinkai.Effects.Apply(target, "regen", duration, { perTick = target:GetMaxHealth() * percentPerSecond })
	Act.FX(Act.FX_AURA, target:WorldSpaceCenter(), vector_up, Color(255, 150, 200))
end

Shinkai.Styles.Register("fleur", {
	name = "Souffle de la Fleur",
	faction = "slayer",
	color = Color(255, 150, 200),
	description = "Un style gracieux tourné vers le soutien. Sa floraison restaure les PV petit à petit.",

	modifiers = { speed = 1.07 },

	techniques = {
		{
			name = "Pétale tranchant", tier = 1,
			description = "Une coupe légère et précise.",
			execute = function(ply, tech, ctx) Act.Slash(ply, ctx) end,
		},
		{
			name = "Prunier d'honneur", tier = 2,
			description = "Deux coupes amples enchaînées.",
			execute = function(ply, tech, ctx) Act.Combo(ply, ctx, 2, 0.2, { cone = 0.1 }) end,
		},
		{
			name = "Floraison apaisante", tier = 3, damage = 0, cost = 40, cooldown = 25,
			description = "Soin progressif de 40 % des PV en 8 secondes. Visez un allié pour le soigner, sinon le soin s'applique à vous-même.",
			execute = function(ply, tech, ctx)
				local target = Act.AimAlly(ply, HEAL_RANGE) or ply
				bloom(target, HEAL_DURATION, HEAL_PERCENT_PER_SECOND)
				if target ~= ply then
					Shinkai.Notify(target, ply:GetRPName() .. " vous soigne.", Shinkai.NOTIFY_SUCCESS)
				end
			end,
		},
		{
			name = "Pivoine écarlate", tier = 4,
			description = "Une floraison de lames autour du Pourfendeur.",
			execute = function(ply, tech, ctx) Act.Burst(ply, ctx, { radius = 240 }) end,
		},
		{
			name = "Tourbillon de pêcher", tier = 5,
			description = "Quatre coupes tournoyantes.",
			execute = function(ply, tech, ctx) Act.Combo(ply, ctx, 4, 0.15, { cone = 0 }) end,
		},
		{
			name = "Jardin éternel", tier = 6,
			description = "Frappe les ennemis de la zone et régénère légèrement le Pourfendeur et ses alliés proches.",
			execute = function(ply, tech, ctx)
				Act.Burst(ply, ctx, { radius = 320, mult = 0.8 })

				bloom(ply, 5, 0.03)
				for _, ally in ipairs(Act.GetAlliesInSphere(ply, ply:WorldSpaceCenter(), 320)) do
					bloom(ally, 5, 0.03)
				end
			end,
		},
	},
})
