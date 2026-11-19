-- Souffle de la Flamme — statistiques normales.
-- Troisième mouvement : onde de puissance qui repousse l'adversaire.

local Act = Shinkai.Actions

Shinkai.Styles.Register("flamme", {
	name = "Souffle de la Flamme",
	faction = "slayer",
	color = Color(255, 110, 30),
	description = "Un style direct et puissant. Son onde de feu repousse les adversaires pour créer de la distance.",

	techniques = {
		{
			name = "Première flamme", tier = 1,
			description = "Un coup de taille enflammé droit devant soi.",
			execute = function(ply, tech, ctx) Act.Slash(ply, ctx) end,
		},
		{
			name = "Danse ardente", tier = 2,
			description = "Deux frappes circulaires enchaînées.",
			execute = function(ply, tech, ctx) Act.Combo(ply, ctx, 2, 0.25, { cone = 0.2 }) end,
		},
		{
			name = "Croissant de feu", tier = 3,
			description = "Une onde de puissance qui repousse violemment les ennemis en face.",
			execute = function(ply, tech, ctx)
				Act.Slash(ply, ctx, { range = 230, cone = 0.2, knockback = 700, up = 280 })
			end,
		},
		{
			name = "Fournaise", tier = 4,
			description = "Embrase tout ce qui entoure le Pourfendeur.",
			execute = function(ply, tech, ctx) Act.Burst(ply, ctx, { radius = 240 }) end,
		},
		{
			name = "Dragon flamboyant", tier = 5,
			description = "Une charge enflammée qui traverse les rangs ennemis.",
			execute = function(ply, tech, ctx) Act.DashStrike(ply, ctx, { speed = 1300 }) end,
		},
		{
			name = "Roi des flammes", tier = 6,
			description = "Une explosion de flammes dévastatrice qui balaie la zone.",
			execute = function(ply, tech, ctx)
				Act.Burst(ply, ctx, { radius = 340, knockback = 400 })
			end,
		},
	},
})
