-- Souffle du Son — réserve d'endurance supérieure, endurance coûteuse.
-- Troisième mouvement : Bombe aveuglante (aucun dégât, alliés épargnés).
-- Possède en plus une téléportation indépendante devant un adversaire ciblé.

local Act = Shinkai.Actions

local BLIND_RADIUS = 350
local BLIND_MIN, BLIND_MAX = 5, 7 -- durée de l'aveuglement en secondes

Shinkai.Styles.Register("son", {
	name = "Souffle du Son",
	faction = "slayer",
	color = Color(255, 120, 190),
	description = "Un style explosif doté d'une grande endurance. Sa bombe aveugle les adversaires et il peut surgir devant sa cible.",

	costProfile = "high",
	modifiers = { endurance = 1.25 },

	techniques = {
		{
			name = "Rugissement", tier = 1,
			description = "Une frappe détonante droit devant.",
			execute = function(ply, tech, ctx) Act.Slash(ply, ctx) end,
		},
		{
			name = "Percussion explosive", tier = 2,
			description = "Une explosion sonore autour du Pourfendeur.",
			execute = function(ply, tech, ctx) Act.Burst(ply, ctx, { radius = 180 }) end,
		},
		{
			name = "Bombe aveuglante", tier = 3, damage = 0, cooldown = 20,
			description = "Aveugle les adversaires proches pendant 5 à 7 secondes. N'inflige aucun dégât et n'affecte pas les alliés.",
			execute = function(ply, tech, ctx)
				local pos = ply:WorldSpaceCenter()

				for _, target in ipairs(ents.FindInSphere(pos, BLIND_RADIUS)) do
					-- Les alliés ne sont jamais aveuglés, même si le tir allié est activé.
					if target:IsPlayer() and target ~= ply and target:Alive() and target:HasCharacter()
						and not ply:IsAllyOf(target) and Act.HasLineOfSight(ply, target) then
						Shinkai.Effects.Apply(target, "blind", math.Rand(BLIND_MIN, BLIND_MAX))
					end
				end

				Act.FX(Act.FX_BURST, pos, vector_up, color_white, BLIND_RADIUS / 220)
			end,
		},
		{
			name = "Résonance", tier = 4,
			description = "Une onde sonore qui frappe et repousse.",
			execute = function(ply, tech, ctx) Act.Burst(ply, ctx, { radius = 240, knockback = 350 }) end,
		},
		{
			name = "Fracas en chaîne", tier = 5,
			description = "Trois détonations enchaînées.",
			execute = function(ply, tech, ctx) Act.Combo(ply, ctx, 3, 0.2, { range = 150, cone = 0.2 }) end,
		},
		{
			name = "Concert funeste", tier = 6,
			description = "Une série d'explosions assourdissantes sur une large zone.",
			execute = function(ply, tech, ctx) Act.Burst(ply, ctx, { radius = 360, knockback = 300 }) end,
		},
		{
			name = "Tempo éclair", tier = 3, label = "Spécial",
			cost = 40, cooldown = 15, unlockGrade = 5,
			description = "Se téléporte juste devant l'adversaire visé.",
			execute = function(ply, tech, ctx)
				local target = Act.AimEnemy(ply, 700)
				if not target then return false, "Aucun adversaire en vue." end
				if not Act.TeleportNear(ply, target, "front") then
					return false, "Pas assez de place devant la cible."
				end
			end,
		},
	},
})
