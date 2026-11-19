-- Souffle de l'Eau — statistiques normales.
-- Troisième mouvement : propulse le joueur dans les airs.

local Act = Shinkai.Actions

Shinkai.Styles.Register("eau", {
	name = "Souffle de l'Eau",
	faction = "slayer",
	color = Color(60, 150, 255),
	description = "Un style fluide et polyvalent. Sa vague ascendante permet de prendre de la hauteur et d'esquiver.",

	techniques = {
		{
			name = "Roue aquatique", tier = 1,
			description = "Une large frappe circulaire.",
			execute = function(ply, tech, ctx) Act.Slash(ply, ctx, { cone = 0.1 }) end,
		},
		{
			name = "Courant fluide", tier = 2,
			description = "Glisse vers l'avant en tranchant.",
			execute = function(ply, tech, ctx) Act.DashStrike(ply, ctx, { speed = 900, duration = 0.3 }) end,
		},
		{
			name = "Vague ascendante", tier = 3,
			description = "Propulse le Pourfendeur dans les airs en frappant les ennemis proches.",
			execute = function(ply, tech, ctx)
				Act.Burst(ply, ctx, { radius = 150 })
				Act.Launch(ply, 650)
			end,
		},
		{
			name = "Danse des courants", tier = 4,
			description = "Trois frappes enchaînées sans interruption.",
			execute = function(ply, tech, ctx) Act.Combo(ply, ctx, 3, 0.2) end,
		},
		{
			name = "Cascade écumante", tier = 5,
			description = "Une masse d'eau s'abat et ralentit les ennemis touchés.",
			execute = function(ply, tech, ctx)
				Act.Burst(ply, ctx, { radius = 260, effect = { id = "slow", duration = 3, data = { mult = 0.6 } } })
			end,
		},
		{
			name = "Océan déchaîné", tier = 6,
			description = "Un raz-de-marée emporte tout sur son passage.",
			execute = function(ply, tech, ctx)
				Act.Burst(ply, ctx, { radius = 360, knockback = 450 })
			end,
		},
	},
})
