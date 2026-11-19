-- Souffle du Vent — statistiques normales.
-- Troisième mouvement : dash sur une très longue distance, plus puissant en
-- dégâts que les autres techniques de même niveau.

local Act = Shinkai.Actions

Shinkai.Styles.Register("vent", {
	name = "Souffle du Vent",
	faction = "slayer",
	color = Color(150, 240, 190),
	description = "Un style mobile et tranchant. Son dash couvre une très longue distance et frappe plus fort que la normale.",

	techniques = {
		{
			name = "Rafale tranchante", tier = 1,
			description = "Une lame de vent à longue portée.",
			execute = function(ply, tech, ctx) Act.Slash(ply, ctx, { range = 180 }) end,
		},
		{
			name = "Tornade", tier = 2,
			description = "Un tourbillon qui soulève les ennemis proches.",
			execute = function(ply, tech, ctx)
				Act.Burst(ply, ctx, { radius = 200, knockback = 250, up = 340 })
			end,
		},
		{
			name = "Lames venteuses", tier = 3, cooldown = 10,
			description = "Un dash sur une très longue distance qui lacère tout sur son passage.",
			execute = function(ply, tech, ctx)
				Act.DashStrike(ply, ctx, { speed = 2400, up = 150, duration = 0.7, mult = 1.3 })
			end,
		},
		{
			name = "Cyclone", tier = 4,
			description = "Des vents violents frappent tout autour du Pourfendeur.",
			execute = function(ply, tech, ctx) Act.Burst(ply, ctx, { radius = 260 }) end,
		},
		{
			name = "Tempête sauvage", tier = 5,
			description = "Quatre lames de vent enchaînées.",
			execute = function(ply, tech, ctx) Act.Combo(ply, ctx, 4, 0.15, { range = 160 }) end,
		},
		{
			name = "Ouragan dévastateur", tier = 6,
			description = "Un ouragan qui projette au loin tous les ennemis de la zone.",
			execute = function(ply, tech, ctx)
				Act.Burst(ply, ctx, { radius = 380, knockback = 600, up = 300 })
			end,
		},
	},
})
