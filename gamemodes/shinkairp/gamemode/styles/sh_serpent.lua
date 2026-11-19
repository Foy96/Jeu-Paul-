-- Souffle du Serpent — attaques enchaînées plus vite, mais moins de PV.
-- Troisième mouvement : téléportation dans le dos d'un adversaire ciblé.
-- Possède en plus une technique d'invisibilité indépendante.

local Act = Shinkai.Actions

Shinkai.Styles.Register("serpent", {
	name = "Souffle du Serpent",
	faction = "slayer",
	color = Color(140, 80, 200),
	description = "Un style sournois basé sur la surprise : coups rapides, téléportation dans le dos et invisibilité, au prix de PV réduits.",

	-- attackDelay 0.7 : les coups de base s'enchaînent 30 % plus vite.
	modifiers = { hp = 0.85, attackDelay = 0.7 },

	techniques = {
		{
			name = "Croc sinueux", tier = 1,
			description = "Une frappe vive et imprévisible.",
			execute = function(ply, tech, ctx) Act.Slash(ply, ctx) end,
		},
		{
			name = "Morsure courbée", tier = 2,
			description = "Une lame courbe qui contourne la garde.",
			execute = function(ply, tech, ctx) Act.Slash(ply, ctx, { cone = 0, range = 140 }) end,
		},
		{
			name = "Serpent ondulant", tier = 3, cooldown = 12,
			description = "Se téléporte directement dans le dos de l'adversaire visé.",
			execute = function(ply, tech, ctx)
				local target = Act.AimEnemy(ply, 700)
				if not target then return false, "Aucun adversaire en vue." end
				if not Act.TeleportNear(ply, target, "behind") then
					return false, "Pas assez de place derrière la cible."
				end
			end,
		},
		{
			name = "Étreinte du serpent", tier = 4,
			description = "Enserre les ennemis touchés et les ralentit.",
			execute = function(ply, tech, ctx)
				Act.Slash(ply, ctx, { range = 150, effect = { id = "slow", duration = 3, data = { mult = 0.5 } } })
			end,
		},
		{
			name = "Reptation fulgurante", tier = 5,
			description = "Une charge rasante et sinueuse.",
			execute = function(ply, tech, ctx) Act.DashStrike(ply, ctx, { speed = 1400, up = 60 }) end,
		},
		{
			name = "Danse du serpent divin", tier = 6,
			description = "Cinq morsures enchaînées en un instant.",
			execute = function(ply, tech, ctx) Act.Combo(ply, ctx, 5, 0.12, { cone = 0.2 }) end,
		},
		{
			name = "Mue furtive", tier = 3, label = "Spécial",
			cost = 40, cooldown = 30, unlockGrade = 5, keepInvisible = true,
			description = "Devient invisible pendant 6 secondes. Attaquer rompt l'invisibilité.",
			execute = function(ply, tech, ctx)
				Shinkai.Effects.Apply(ply, "invisible", 6)
				Act.FX(Act.FX_AURA, ply:WorldSpaceCenter(), vector_up, ctx.style.color)
			end,
		},
	},
})
