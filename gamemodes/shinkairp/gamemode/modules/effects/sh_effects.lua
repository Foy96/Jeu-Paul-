-- Registre des effets temporaires (paralysie, invisibilité, rage, soin...).
--
-- Structure d'un effet :
--   name          nom affiché sur le HUD
--   color         couleur sur le HUD
--   negative      true pour un effet néfaste
--   tickInterval  secondes entre deux appels de onTick (facultatif)
--   onStart       function(ply, data)        — serveur
--   onEnd         function(ply, data)        — serveur
--   onTick        function(ply, data)        — serveur
--   modifyStats   function(ply, stats, data) — serveur, modifie les statistiques

Shinkai.Effects = Shinkai.Effects or {}
local Effects = Shinkai.Effects

Effects.List = Effects.List or {}

function Effects.Register(id, effect)
	effect.id = id
	effect.color = effect.color or color_white
	Effects.List[id] = effect
	return effect
end

function Effects.GetDefinition(id)
	return Effects.List[id]
end
