-- Souffle de la Bête — agressif et risqué.
-- Troisième mouvement : Mode Rage (vitesse et dégâts augmentés, PV diminués).
-- Les valeurs de la rage se règlent dans config/sh_config.lua (C.Rage) ;
-- le bonus de vitesse est fixe, identique à tous les grades.

local Act = Shinkai.Actions

Shinkai.Styles.Register("bete", {
	name = "Souffle de la Bête",
	faction = "slayer",
	color = Color(210, 120, 60),
	description = "Un style sauvage. Son Mode Rage décuple vitesse et dégâts, mais réduit les PV de son utilisateur.",

	techniques = {
		{
			name = "Perforation", tier = 1,
			description = "Une estocade brutale.",
			execute = function(ply, tech, ctx) Act.Slash(ply, ctx, { cone = 0.7, range = 150 }) end,
		},
		{
			name = "Entaille croisée", tier = 2,
			description = "Deux lames qui se croisent.",
			execute = function(ply, tech, ctx) Act.Combo(ply, ctx, 2, 0.15) end,
		},
		{
			name = "Mode Rage", tier = 3, damage = 0, cooldown = 60,
			description = "Entre en rage : vitesse et dégâts augmentés, mais PV maximum réduits pendant la durée de l'effet.",
			execute = function(ply, tech, ctx)
				Shinkai.Effects.Apply(ply, "rage", Shinkai.Config.Rage.Duration)
				Act.FX(Act.FX_AURA, ply:WorldSpaceCenter(), vector_up, Color(255, 60, 40), 1.5)
			end,
		},
		{
			name = "Crocs déchiquetants", tier = 4,
			description = "Trois coups sauvages enchaînés.",
			execute = function(ply, tech, ctx) Act.Combo(ply, ctx, 3, 0.15) end,
		},
		{
			name = "Lacération sauvage", tier = 5,
			description = "Bondit sur sa proie en lacérant tout sur son passage.",
			execute = function(ply, tech, ctx) Act.DashStrike(ply, ctx, { speed = 1300, up = 220 }) end,
		},
		{
			name = "Fureur bestiale", tier = 6,
			description = "Un déchaînement de coups dans toutes les directions.",
			execute = function(ply, tech, ctx) Act.Burst(ply, ctx, { radius = 300, knockback = 350 }) end,
		},
	},
})
