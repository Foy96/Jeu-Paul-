-- Envoie aux joueurs les images du serveur (dossier gamemodes/shinkairp/content/).
-- Seules les images réellement présentes sont envoyées.

local function addImage(path)
	if not path then return end
	local full = "materials/" .. path
	if file.Exists(full, "GAME") then
		resource.AddFile(full)
	else
		MsgC(Color(230, 180, 60), "[Shinkai] Image absente, fond uni utilisé : ", full, "\n")
	end
end

addImage(Shinkai.Config.FactionScreenImage)
for _, faction in pairs(Shinkai.Config.Factions) do
	addImage(faction.creationImage)
end
