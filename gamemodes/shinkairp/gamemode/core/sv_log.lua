-- Journal du serveur : data/shinkai/logs/AAAA-MM-JJ.txt

file.CreateDir("shinkai")
file.CreateDir("shinkai/logs")

function Shinkai.Log(category, text)
	local line = string.format("[%s] [%s] %s", os.date("%H:%M:%S"), category, text)
	file.Append("shinkai/logs/" .. os.date("%Y-%m-%d") .. ".txt", line .. "\n")
	MsgC(Color(230, 80, 80), "[Shinkai] ", color_white, line, "\n")
end

-- Nom lisible d'un joueur pour les journaux.
function Shinkai.LogName(ply)
	if not IsValid(ply) then return "Console" end
	return string.format("%s (%s, %s)", ply:GetRPName(), ply:Nick(), ply:SteamID())
end
