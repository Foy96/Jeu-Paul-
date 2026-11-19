-- Configuration générale de Shinkai RP.
-- Toutes les valeurs d'équilibrage sont regroupées dans le dossier config/.

Shinkai.Config = Shinkai.Config or {}
local C = Shinkai.Config

---------------------------------------------------------------------------
-- Personnages
---------------------------------------------------------------------------
C.MaxCharacters = 3          -- personnages par joueur
C.AllowCharDelete = true     -- un joueur peut supprimer ses personnages
C.AllowCharSwitch = true     -- changement de personnage en jeu (F2)
C.CharSwitchCooldown = 60    -- secondes entre deux changements
C.NameMinLength = 3
C.NameMaxLength = 32
C.Currency = "yens"
C.StartMoney = 500
C.AutosaveInterval = 300     -- sauvegarde automatique (secondes)

---------------------------------------------------------------------------
-- Factions
-- Les modèles sont ceux de Half-Life 2 en attendant vos packs de contenu.
---------------------------------------------------------------------------
C.Factions = {
	slayer = {
		name = "Pourfendeur",
		plural = "Pourfendeurs",
		color = Color(90, 170, 255),
		weapon = "shinkai_katana",
		whitelist = false, -- true : création réservée aux joueurs whitelistés
		models = {
			"models/player/group01/male_02.mdl",
			"models/player/group01/male_04.mdl",
			"models/player/group01/male_07.mdl",
			"models/player/group01/female_01.mdl",
			"models/player/group01/female_02.mdl",
			"models/player/group01/female_04.mdl",
		},
	},
	demon = {
		name = "Démon",
		plural = "Démons",
		color = Color(200, 50, 60),
		weapon = "shinkai_griffes",
		whitelist = false,
		models = {
			"models/player/corpse1.mdl",
			"models/player/charple.mdl",
			"models/player/zombie_classic.mdl",
			"models/player/zombie_fast.mdl",
		},
	},
}

-- Ordre d'affichage des factions dans les menus.
C.FactionOrder = { "slayer", "demon" }

---------------------------------------------------------------------------
-- Souffles
---------------------------------------------------------------------------
C.StyleMinGrade = 2        -- grade à partir duquel on possède un Souffle (l'Aspirant n'en a pas)
C.StyleSelfChoice = true   -- true : le joueur choisit son Souffle ; false : attribué par le staff

---------------------------------------------------------------------------
-- Déplacement — la statistique VIT est un pourcentage de ces valeurs (100 = normal).
---------------------------------------------------------------------------
C.BaseWalkSpeed = 110
C.BaseRunSpeed = 220
C.BaseJumpPower = 200
C.FallDamage = false -- les techniques propulsent haut : pas de dégâts de chute par défaut

---------------------------------------------------------------------------
-- Endurance
---------------------------------------------------------------------------
C.Stamina = {
	TickRate = 0.1,        -- fréquence de mise à jour (secondes)
	RegenDelay = 2,        -- délai sans dépense avant de récupérer
	RegenPercent = 0.06,   -- part de l'endurance max récupérée par seconde
	SprintDrain = 4,       -- endurance consommée par seconde de sprint
	ExhaustRecover = 0.2,  -- part de l'endurance à retrouver pour pouvoir re-sprinter
}

---------------------------------------------------------------------------
-- Combat
---------------------------------------------------------------------------
C.Combat = {
	FriendlyFire = false,      -- dégâts entre membres d'une même faction
	GlobalCooldown = 0.6,      -- délai minimal entre deux techniques
	BasicAttackDelay = 0.7,    -- délai entre deux coups de base
	BasicAttackRange = 85,
	BasicAttackCost = 0,       -- endurance par coup de base
	BreakInvisOnAttack = true, -- attaquer met fin à l'invisibilité

	-- Mise à l'échelle des dégâts des techniques :
	--   "scaled" : dégâts du barème x (Dégâts du grade / DamageReference).
	--              Le barème (20, 30, 40...) correspond alors à un Mizunoto
	--              (10 de dégâts) et suit la montée des PV avec les grades.
	--   "flat"   : dégâts du barème tels quels, quel que soit le grade.
	DamageMode = "scaled",
	DamageReference = 10,
}

-- Garde : maintenir le clic droit avec son arme.
C.Guard = {
	Enabled = true,
	Reduction = 0.5,     -- part des dégâts de face absorbée
	StaminaPerHit = 10,  -- endurance consommée par coup paré
}

-- Mode Rage (Souffle de la Bête).
C.Rage = {
	Duration = 20,
	SpeedBonus = 40,   -- points de VIT ajoutés, identiques à tous les grades
	DamageMult = 1.5,
	HPPenalty = 0.25,  -- part des PV max perdue pendant la rage
}

-- Régénération passive des Démons.
C.DemonRegen = {
	Enabled = true,
	PercentPerSecond = 0.01, -- part des PV max par seconde
	DelayAfterDamage = 6,    -- secondes sans subir de dégâts
}

---------------------------------------------------------------------------
-- Mort
---------------------------------------------------------------------------
C.RespawnTime = 10
C.AllowSuicide = false

---------------------------------------------------------------------------
-- Progression
---------------------------------------------------------------------------
C.Progression = {
	AutoPromote = true,        -- montée de grade automatique quand l'XP est atteinte
	KillXP = 25,               -- XP de base pour avoir vaincu un ennemi...
	KillXPPerGrade = 15,       -- ...plus ce montant par grade de la victime
	NPCKillXP = 5,
	PlaytimeXP = 10,           -- XP donnée régulièrement aux joueurs présents
	PlaytimeInterval = 600,    -- toutes les X secondes
}

---------------------------------------------------------------------------
-- Chat RP (distances en unités Source)
---------------------------------------------------------------------------
C.Chat = {
	TalkRange = 450,
	WhisperRange = 120,
	YellRange = 900,
	VoiceRange = 600,
}
