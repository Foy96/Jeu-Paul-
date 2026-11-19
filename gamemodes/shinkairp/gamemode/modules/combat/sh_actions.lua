-- Tables partagées du système de combat.
-- Shinkai.Actions est remplie côté serveur (sv_actions.lua) ; elle est créée
-- ici pour que les fichiers de Souffles puissent écrire
-- `local Act = Shinkai.Actions` dès leur chargement.

Shinkai.Actions = Shinkai.Actions or {}
Shinkai.Techniques = Shinkai.Techniques or {}

local Actions = Shinkai.Actions

-- Types d'effets visuels (voir cl_fx.lua).
Actions.FX_SLASH = 1 -- arc devant le joueur
Actions.FX_BURST = 2 -- onde circulaire
Actions.FX_DASH = 3  -- traînée
Actions.FX_AURA = 4  -- particules montantes (soin, renforcement)
