-- Souffle de la Foudre — bonus de vitesse (le plus élevé), endurance coûteuse.
-- Troisième mouvement : paralysie électrique temporaire.

local Act = Shinkai.Actions

Shinkai.Styles.Register("foudre", {
	name = "Souffle de la Foudre",
	faction = "slayer",
	color = Color(255, 230, 60),
	description = "Le style le plus rapide. Sa foudre paralyse l'adversaire, mais ses techniques coûtent plus d'endurance.",

	costProfile = "high",
	modifiers = { speed = 1.15 },

	techniques = {
		{
			name = "Éclair fulgurant", tier = 1,
			description = "Une charge éclair en ligne droite.",
			execute = function(ply, tech, ctx) Act.DashStrike(ply, ctx, { speed = 1500, duration = 0.3 }) end,
		},
		{
			name = "Double éclair", tier = 2,
			description = "Deux frappes quasi instantanées.",
			execute = function(ply, tech, ctx) Act.Combo(ply, ctx, 2, 0.15) end,
		},
		{
			name = "Tonnerre céleste", tier = 3, cooldown = 14,
			description = "Une décharge qui paralyse les ennemis en face : ils ne peuvent plus se déplacer.",
			execute = function(ply, tech, ctx)
				Act.Slash(ply, ctx, { range = 200, effect = { id = "stun", duration = 2.5 } })
			end,
		},
		{
			name = "Flash électrique", tier = 4,
			description = "Une décharge circulaire autour du Pourfendeur.",
			execute = function(ply, tech, ctx) Act.Burst(ply, ctx, { radius = 230 }) end,
		},
		{
			name = "Foudre divine", tier = 5,
			description = "Une charge foudroyante sur une longue distance.",
			execute = function(ply, tech, ctx) Act.DashStrike(ply, ctx, { speed = 1700, radius = 110 }) end,
		},
		{
			name = "Éclair absolu", tier = 6,
			description = "Une charge à la vitesse de la foudre qui étourdit brièvement ses victimes.",
			execute = function(ply, tech, ctx)
				Act.DashStrike(ply, ctx, { speed = 2200, duration = 0.5, radius = 120, effect = { id = "stun", duration = 1 } })
			end,
		},
	},
})
