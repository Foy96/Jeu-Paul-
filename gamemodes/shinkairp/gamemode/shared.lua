-- Shinkai RP — Demon Slayer Serious RP
-- Fichier partagé : déclare le gamemode puis charge tous les systèmes.

GM.Name = "Shinkai RP"
GM.Author = "Shinkai RP"
GM.Email = ""
GM.Website = ""

DeriveGamemode("base")

Shinkai = Shinkai or {}
Shinkai.Version = "0.1.0"

include("loader.lua")

local Loader = Shinkai.Loader

-- 1. Outils communs, 2. configuration, 3. systèmes, 4. contenu (Souffles).
Loader.IncludeDir("core")
Loader.IncludeDir("config")

-- L'ordre ne compte que pour la création des tables : les systèmes se
-- parlent uniquement à l'exécution (fonctions et hooks), jamais au chargement.
local MODULES = {
	"data",        -- sauvegarde (SQLite)
	"grades",      -- accès aux grades Pourfendeurs / Démons
	"styles",      -- registre des Souffles et arts démoniaques
	"character",   -- personnages, joueur, menus de création
	"stats",       -- PV / Dégâts / END / VIT
	"stamina",     -- endurance
	"effects",     -- effets temporaires (paralysie, invisibilité, rage...)
	"combat",      -- techniques, cooldowns, dégâts, garde
	"progression", -- expérience et évolution des grades
	"chat",        -- chat RP de proximité
	"admin",       -- outils du staff
	"hud",         -- interface
}

for _, name in ipairs(MODULES) do
	Loader.IncludeDir("modules/" .. name)
end

-- Un fichier par Souffle : en déposer un nouveau ici suffit à l'ajouter.
Loader.IncludeDir("styles")

hook.Run("ShinkaiLoaded")
