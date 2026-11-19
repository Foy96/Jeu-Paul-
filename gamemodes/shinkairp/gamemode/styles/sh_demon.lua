-- Art démoniaque — style de combat de base des Démons.
-- Le cahier des charges ne détaille pas encore les pouvoirs des Démons :
-- ce style leur donne de quoi combattre en attendant. Pour créer de vrais
-- pouvoirs sanguinaires, copiez ce fichier, changez l'id et le contenu :
-- dès qu'une faction possède plusieurs styles, le joueur choisit le sien.

local Act = Shinkai.Actions

Shinkai.Styles.Register("art_demoniaque", {
	name = "Art démoniaque",
	faction = "demon",
	color = Color(200, 30, 50),
	description = "La force brute des Démons : griffes, bonds et régénération.",

	techniques = {
		{
			name = "Griffes lacérantes", tier = 1,
			description = "Un coup de griffes devant soi.",
			execute = function(ply, tech, ctx) Act.Slash(ply, ctx) end,
		},
		{
			name = "Bond prédateur", tier = 2,
			description = "Bondit sur sa proie.",
			execute = function(ply, tech, ctx) Act.DashStrike(ply, ctx, { speed = 1100, up = 260, duration = 0.6 }) end,
		},
		{
			name = "Régénération accélérée", tier = 3, damage = 0, cooldown = 25,
			description = "Régénère 30 % des PV en 6 secondes.",
			execute = function(ply, tech, ctx)
				Shinkai.Effects.Apply(ply, "regen", 6, { perTick = ply:GetMaxHealth() * 0.05 })
				Act.FX(Act.FX_AURA, ply:WorldSpaceCenter(), vector_up, ctx.style.color)
			end,
		},
		{
			name = "Onde sanguine", tier = 4,
			description = "Une onde de choc qui repousse les ennemis proches.",
			execute = function(ply, tech, ctx) Act.Burst(ply, ctx, { radius = 240, knockback = 400 }) end,
		},
		{
			name = "Frénésie", tier = 5, damage = 0, cooldown = 40,
			description = "Augmente les dégâts et la vitesse pendant 10 secondes.",
			execute = function(ply, tech, ctx)
				Shinkai.Effects.Apply(ply, "power", 10, { mult = 1.3 })
				Shinkai.Effects.Apply(ply, "haste", 10, { bonus = 20 })
				Act.FX(Act.FX_AURA, ply:WorldSpaceCenter(), vector_up, ctx.style.color, 1.5)
			end,
		},
		{
			name = "Déchaînement démoniaque", tier = 6,
			description = "Une explosion de puissance démoniaque sur une large zone.",
			execute = function(ply, tech, ctx) Act.Burst(ply, ctx, { radius = 380, knockback = 500 }) end,
		},
	},
})
