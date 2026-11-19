-- Barème des techniques (propositions initiales du cahier des charges).
-- Une technique reprend les valeurs de son niveau, sauf si elle définit
-- elle-même damage / cost / cooldown / unlockGrade.

local C = Shinkai.Config

-- unlock = numéro du grade (1 = Aspirant ... 12 = Pilier) qui débloque le niveau.
C.TechniqueTiers = {
	[1] = { label = "I",      damage = 20,  cooldown = 3,  unlock = 2 },
	[2] = { label = "II",     damage = 30,  cooldown = 5,  unlock = 3 },
	[3] = { label = "III",    damage = 40,  cooldown = 8,  unlock = 4 },
	[4] = { label = "IV",     damage = 55,  cooldown = 12, unlock = 6 },
	[5] = { label = "V",      damage = 70,  cooldown = 18, unlock = 8 },
	[6] = { label = "Ultime", damage = 100, cooldown = 40, unlock = 10 },
}

-- Endurance consommée par niveau. Un Souffle choisit son profil avec costProfile.
C.CostProfiles = {
	normal = { 15, 25, 35, 45, 60, 90 },
	high   = { 20, 30, 40, 55, 70, 100 }, -- Foudre et Son
}
