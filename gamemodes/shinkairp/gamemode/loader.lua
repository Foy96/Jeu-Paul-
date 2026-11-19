-- Chargeur de fichiers.
-- Le préfixe du nom de fichier décide où il s'exécute :
--   sv_  serveur uniquement
--   cl_  client uniquement (envoyé au client par le serveur)
--   sh_  partagé (ou tout autre nom)

Shinkai.Loader = Shinkai.Loader or {}
local Loader = Shinkai.Loader

local ROOT = (GM or GAMEMODE).FolderName .. "/gamemode/"

function Loader.Include(relPath)
	local prefix = string.sub(string.GetFileFromFilename(relPath), 1, 3)
	local path = ROOT .. relPath

	if prefix == "sv_" then
		if SERVER then include(path) end
	elseif prefix == "cl_" then
		if SERVER then AddCSLuaFile(path) else include(path) end
	else
		if SERVER then AddCSLuaFile(path) end
		include(path)
	end
end

local ORDER = { sh_ = 1, sv_ = 2, cl_ = 3 }

-- Charge tous les .lua d'un dossier : partagés d'abord, puis serveur, puis
-- client, par ordre alphabétique dans chaque groupe.
function Loader.IncludeDir(relDir)
	local files = file.Find(ROOT .. relDir .. "/*.lua", "LUA")
	if not files then return end

	table.sort(files, function(a, b)
		local oa = ORDER[string.sub(a, 1, 3)] or 1
		local ob = ORDER[string.sub(b, 1, 3)] or 1
		if oa ~= ob then return oa < ob end
		return a < b
	end)

	for _, name in ipairs(files) do
		Loader.Include(relDir .. "/" .. name)
	end
end
