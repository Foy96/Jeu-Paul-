-- Outils communs : notifications et petites fonctions utilitaires.

Shinkai.Util = Shinkai.Util or {}
local Util = Shinkai.Util

-- Types de notification (correspondent aux NOTIFY_* du client).
Shinkai.NOTIFY_INFO = 0
Shinkai.NOTIFY_ERROR = 1
Shinkai.NOTIFY_SUCCESS = 3

-- Formate un nombre avec des espaces : 15000 -> "15 000".
function Util.FormatNumber(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local out = string.reverse(string.gsub(string.reverse(s), "(%d%d%d)", "%1 "))
	return string.Trim(out)
end

-- Direction horizontale du regard d'un joueur.
function Util.FlatAim(ply)
	return Angle(0, ply:EyeAngles().y, 0):Forward()
end

if SERVER then
	-- Envoie une notification à un joueur, une liste de joueurs, ou à tous (nil).
	function Shinkai.Notify(target, text, kind)
		net.Start("Shinkai.Notify")
		net.WriteString(text)
		net.WriteUInt(kind or Shinkai.NOTIFY_INFO, 3)
		if target then net.Send(target) else net.Broadcast() end
	end
else
	function Shinkai.Notify(_, text, kind)
		notification.AddLegacy(text, kind or Shinkai.NOTIFY_INFO, 5)
		surface.PlaySound(kind == Shinkai.NOTIFY_ERROR and "buttons/button10.wav" or "buttons/lightswitch2.wav")
	end

	net.Receive("Shinkai.Notify", function()
		local text = net.ReadString()
		Shinkai.Notify(nil, text, net.ReadUInt(3))
	end)
end
