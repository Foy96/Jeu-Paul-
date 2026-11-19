-- Grades et statistiques des Pourfendeurs et des Démons.
--
-- Champs d'un grade :
--   id         identifiant technique (sans espace)
--   name       nom affiché
--   title      appellation (Démons)
--   hp         PV
--   damage     dégâts de base
--   endurance  END
--   speed      VIT (100 = vitesse normale)
--   xp         expérience totale nécessaire pour atteindre le grade (proposition)
--   staffOnly  true : ne s'obtient jamais automatiquement, uniquement par le staff

local C = Shinkai.Config

C.Grades = {}

C.Grades.slayer = {
	{ id = "aspirant",   name = "Aspirant",   hp = 50,   damage = 5,   endurance = 100,  speed = 100, xp = 0 },
	{ id = "mizunoto",   name = "Mizunoto",   hp = 150,  damage = 10,  endurance = 150,  speed = 110, xp = 100 },
	{ id = "mizunoe",    name = "Mizunoe",    hp = 200,  damage = 10,  endurance = 180,  speed = 115, xp = 250 },
	{ id = "kanoto",     name = "Kanoto",     hp = 300,  damage = 20,  endurance = 220,  speed = 120, xp = 500 },
	{ id = "kanoe",      name = "Kanoe",      hp = 350,  damage = 20,  endurance = 250,  speed = 125, xp = 900 },
	{ id = "tsuchinoto", name = "Tsuchinoto", hp = 600,  damage = 40,  endurance = 350,  speed = 135, xp = 1500 },
	{ id = "tsuchinoe",  name = "Tsuchinoe",  hp = 650,  damage = 40,  endurance = 380,  speed = 140, xp = 2400 },
	{ id = "hinoto",     name = "Hinoto",     hp = 1200, damage = 80,  endurance = 500,  speed = 155, xp = 3600 },
	{ id = "hinoe",      name = "Hinoe",      hp = 1250, damage = 80,  endurance = 530,  speed = 160, xp = 5200 },
	{ id = "kinoto",     name = "Kinoto",     hp = 2400, damage = 160, endurance = 700,  speed = 175, xp = 7500 },
	{ id = "kinoe",      name = "Kinoe",      hp = 2450, damage = 160, endurance = 750,  speed = 180, xp = 10500 },
	{ id = "pilier",     name = "Pilier",     hp = 4800, damage = 320, endurance = 1000, speed = 200, xp = 15000, staffOnly = true },
}

-- Démons : PV et dégâts proposés par le cahier des charges (à valider).
-- L'END et la VIT n'étant pas définies, elles reprennent celles du grade
-- Pourfendeur équivalent ; ajoutez endurance = / speed = sur une ligne pour
-- lui donner une valeur propre.
local demons = {
	{ id = "profondeur", name = "Profondeur",    title = "Démon débutant",            hp = 50,    damage = 5 },
	{ id = "semi_b",     name = "Semi-Rang B",   title = "Démon intermédiaire",       hp = 150,   damage = 10 },
	{ id = "rang_b",     name = "Rang B",        title = "Démon confirmé",            hp = 200,   damage = 10 },
	{ id = "semi_a",     name = "Semi-Rang A",   title = "Démon avancé",              hp = 300,   damage = 20 },
	{ id = "rang_a",     name = "Rang A",        title = "Démon confirmé supérieur",  hp = 350,   damage = 20 },
	{ id = "semi_s",     name = "Semi-Rang S",   title = "Démon menaçant",            hp = 600,   damage = 40 },
	{ id = "rang_s",     name = "Rang S",        title = "Démon puissant",            hp = 650,   damage = 40 },
	{ id = "semi_ss",    name = "Semi-Rang SS",  title = "Semi-Lune inférieure",      hp = 1200,  damage = 80 },
	{ id = "rang_ss",    name = "Rang SS",       title = "Lune inférieure",           hp = 2450,  damage = 160 },
	{ id = "semi_sss",   name = "Semi-Rang SSS", title = "Semi-Lune supérieure",      hp = 4800,  damage = 320 },
	{ id = "rang_sss",   name = "Rang SSS",      title = "Lune supérieure",           hp = 7350,  damage = 480 },
	{ id = "rang_z",     name = "Rang Z",        title = "Maître des démons",         hp = 15000, damage = 1000, staffOnly = true },
}

for index, grade in ipairs(demons) do
	local equivalent = C.Grades.slayer[index]
	grade.endurance = grade.endurance or equivalent.endurance
	grade.speed = grade.speed or equivalent.speed
	grade.xp = grade.xp or equivalent.xp
end

C.Grades.demon = demons
