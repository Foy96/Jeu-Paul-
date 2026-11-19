-- Souffle de la Brume — statistiques normales, temps de recharge réduits.
-- Troisième mouvement : invisibilité temporaire.

local Act = Shinkai.Actions

Shinkai.Styles.Register("brume", {
	name = "Souffle de la Brume",
	faction = "slayer",
	color = Color(190, 215, 230),
	description = "Un style insaisissable. Ses techniques se rechargent plus vite et sa brume rend invisible.",

	-- cooldown 0.7 : toutes les recharges sont réduites de 30 %.
	modifiers = { cooldown = 0.7 },

	techniques = {
		{
			name = "Nuée basse", tier = 1,
			description = "Une frappe rasante voilée de brume.",
			execute = function(ply, tech, ctx) Act.Slash(ply, ctx) end,
		},
		{
			name = "Brume octuple", tier = 2,
			description = "Une série de frappes rapides et diffuses.",
			execute = function(ply, tech, ctx) Act.Combo(ply, ctx, 4, 0.12) end,
		},
		{
			name = "Voile de brume", tier = 3, cooldown = 25, keepInvisible = true,
			description = "Devient invisible pendant 7 secondes. Attaquer rompt l'invisibilité.",
			execute = function(ply, tech, ctx)
				Shinkai.Effects.Apply(ply, "invisible", 7)
				Act.FX(Act.FX_AURA, ply:WorldSpaceCenter(), vector_up, ctx.style.color)
			end,
		},
		{
			name = "Mer de nuages", tier = 4,
			description = "Une nappe de brume qui frappe et ralentit les ennemis proches.",
			execute = function(ply, tech, ctx)
				Act.Burst(ply, ctx, { radius = 240, effect = { id = "slow", duration = 2.5, data = { mult = 0.6 } } })
			end,
		},
		{
			name = "Lune voilée", tier = 5,
			description = "Traverse la brume en un éclair.",
			execute = function(ply, tech, ctx) Act.DashStrike(ply, ctx, { speed = 1400 }) end,
		},
		{
			name = "Brume crépusculaire", tier = 6, keepInvisible = true,
			description = "Une déferlante de brume, dans laquelle le Pourfendeur disparaît 3 secondes.",
			execute = function(ply, tech, ctx)
				Act.Burst(ply, ctx, { radius = 320 })
				Shinkai.Effects.Apply(ply, "invisible", 3)
			end,
		},
	},
})
