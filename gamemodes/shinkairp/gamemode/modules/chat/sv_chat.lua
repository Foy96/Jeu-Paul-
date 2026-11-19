-- Chat RP : la parole porte à une distance limitée et utilise le nom du personnage.
--   (texte)        parler            /c ou /crier   crier
--   /ch (texte)    chuchoter         /me (texte)    action
--   // ou /ooc     hors-RP global    !commande      commande staff (modules/admin)

local CFG = Shinkai.Config.Chat

-- kind : identifiant lu par le client (cl_chat.lua) ; range : portée, nil = tout le serveur.
local MODES = {
	["/ch"] = { kind = "whisper", range = CFG.WhisperRange },
	["/chuchoter"] = { kind = "whisper", range = CFG.WhisperRange },
	["/c"] = { kind = "yell", range = CFG.YellRange },
	["/crier"] = { kind = "yell", range = CFG.YellRange },
	["/me"] = { kind = "me", range = CFG.TalkRange },
	["//"] = { kind = "ooc" },
	["/ooc"] = { kind = "ooc" },
}

local function send(speaker, kind, text, range)
	local recipients = {}
	for _, ply in ipairs(player.GetAll()) do
		if not range or ply:GetPos():DistToSqr(speaker:GetPos()) <= range * range then
			recipients[#recipients + 1] = ply
		end
	end

	net.Start("Shinkai.Chat")
	net.WriteString(kind)
	net.WriteEntity(speaker)
	net.WriteString(text)
	net.Send(recipients)
end

hook.Add("PlayerSay", "Shinkai.Chat", function(ply, text)
	text = string.Trim(text)
	if text == "" then return "" end

	-- Commandes du staff : !commande arguments
	if string.sub(text, 1, 1) == "!" then
		local args = string.Explode(" ", string.sub(text, 2))
		Shinkai.Admin.Run(ply, table.remove(args, 1), args)
		return ""
	end

	local prefix, rest
	if string.sub(text, 1, 2) == "//" then
		prefix, rest = "//", string.Trim(string.sub(text, 3)) -- "//texte" sans espace
	else
		prefix, rest = string.match(text, "^(/%S+)%s*(.*)$")
	end
	local mode = prefix and MODES[string.lower(prefix)]

	if mode then
		text = rest
	elseif prefix then
		Shinkai.Notify(ply, "Commande de chat inconnue : " .. prefix, Shinkai.NOTIFY_ERROR)
		return ""
	else
		mode = { kind = "say", range = CFG.TalkRange }
	end

	if text == "" then return "" end

	-- Le chat RP nécessite un personnage ; le hors-RP reste toujours possible.
	if mode.kind ~= "ooc" and not ply:HasCharacter() then return "" end

	send(ply, mode.kind, text, mode.range)
	Shinkai.Log("Chat", string.format("[%s] %s : %s", mode.kind, Shinkai.LogName(ply), text))
	return ""
end)

-- Voix de proximité.
hook.Add("PlayerCanHearPlayersVoice", "Shinkai.Voice", function(listener, talker)
	local range = CFG.VoiceRange
	return listener:GetPos():DistToSqr(talker:GetPos()) <= range * range, true
end)
