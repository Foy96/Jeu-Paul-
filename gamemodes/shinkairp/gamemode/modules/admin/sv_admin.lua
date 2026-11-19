-- Commandes du staff.
-- Utilisables depuis le chat (!commande ...), la console (shinkai commande ...)
-- et le menu staff (F4). Tapez "!aide" pour la liste.
--
-- Ajouter une commande :
--   Admin.Register("nom", {
--       permission = "nom_de_permission",   -- voir config/sh_staff.lua
--       args = { "player", "number" },      -- player, number, string, text (reste de la ligne)
--       usage = "<joueur> <montant>",
--       help = "Description.",
--       run = function(caller, target, amount) ... end,
--   })

local Admin = Shinkai.Admin
local Char = Shinkai.Char
local Grades = Shinkai.Grades

Admin.Commands = Admin.Commands or {}

function Admin.Register(name, command)
	command.name = name
	command.args = command.args or {}
	Admin.Commands[name] = command
end

-- Répond à l'auteur d'une commande (joueur ou console).
function Admin.Reply(caller, text, kind)
	if IsValid(caller) then
		Shinkai.Notify(caller, text, kind)
	else
		print("[Shinkai] " .. text)
	end
end

-- Trouve un joueur par #userid, SteamID, SteamID64, nom RP ou nom Steam (partiel accepté).
function Admin.FindPlayer(query)
	query = string.lower(tostring(query or ""))
	if query == "" then return nil end

	local userId = tonumber(string.match(query, "^#(%d+)$"))
	local partial

	for _, ply in ipairs(player.GetAll()) do
		if userId then
			if ply:UserID() == userId then return ply end
		elseif string.lower(ply:SteamID()) == query or ply:SteamID64() == query then
			return ply
		else
			local rpName, nick = string.lower(ply:GetRPName()), string.lower(ply:Nick())
			if rpName == query or nick == query then return ply end
			if string.find(rpName, query, 1, true) or string.find(nick, query, 1, true) then
				if partial then return nil, "Plusieurs joueurs correspondent à « " .. query .. " »." end
				partial = ply
			end
		end
	end
	return partial
end

local function parseArgs(command, raw)
	local parsed = {}

	for index, kind in ipairs(command.args) do
		local value = raw[index]
		if value == nil or value == "" then return nil, "Utilisation : " .. command.name .. " " .. (command.usage or "") end

		if kind == "player" then
			local target, err = Admin.FindPlayer(value)
			if not target then return nil, err or ("Joueur introuvable : " .. value) end
			parsed[index] = target
		elseif kind == "number" then
			local number = tonumber(value)
			if not number then return nil, "Nombre invalide : " .. value end
			parsed[index] = number
		elseif kind == "text" then
			parsed[index] = table.concat(raw, " ", index)
			break
		else
			parsed[index] = value
		end
	end
	return parsed
end

function Admin.Run(caller, name, raw)
	local command = Admin.Commands[string.lower(tostring(name or ""))]
	if not command then
		return Admin.Reply(caller, "Commande inconnue. Tapez !aide pour la liste.", Shinkai.NOTIFY_ERROR)
	end
	if not Admin.HasPermission(caller, command.permission) then
		return Admin.Reply(caller, "Vous n'avez pas la permission d'utiliser cette commande.", Shinkai.NOTIFY_ERROR)
	end

	local args, err = parseArgs(command, raw or {})
	if not args then
		return Admin.Reply(caller, err, Shinkai.NOTIFY_ERROR)
	end

	command.run(caller, unpack(args, 1, #command.args))
end

concommand.Add("shinkai", function(ply, _, args)
	Admin.Run(ply, table.remove(args, 1), args)
end)

-- Vérifie que la cible a un personnage chargé ; prévient l'auteur sinon.
local function requireChar(caller, target)
	if Char.Get(target) then return true end
	Admin.Reply(caller, target:Nick() .. " n'a pas de personnage chargé.", Shinkai.NOTIFY_ERROR)
	return false
end

local function log(caller, text)
	Shinkai.Log("Staff", Shinkai.LogName(caller) .. " " .. text)
end

---------------------------------------------------------------------------
-- Grades
---------------------------------------------------------------------------
Admin.Register("setgrade", {
	permission = "setgrade",
	args = { "player", "string" },
	usage = "<joueur> <numéro ou id du grade>",
	help = "Définit le grade d'un personnage.",
	run = function(caller, target, value)
		if not requireChar(caller, target) then return end

		local index = Grades.FindIndex(target:GetFaction(), value)
		if not index then
			return Admin.Reply(caller, "Grade inconnu : " .. value, Shinkai.NOTIFY_ERROR)
		end
		if Shinkai.Progression.SetGrade(target, index, caller) then
			Admin.Reply(caller, target:GetRPName() .. " est désormais " .. target:GetGradeData().name .. ".", Shinkai.NOTIFY_SUCCESS)
		else
			Admin.Reply(caller, "Ce personnage possède déjà ce grade.", Shinkai.NOTIFY_ERROR)
		end
	end,
})

Admin.Register("promote", {
	permission = "promote",
	args = { "player" },
	usage = "<joueur>",
	help = "Fait monter un personnage d'un grade.",
	run = function(caller, target)
		if not requireChar(caller, target) then return end
		if Shinkai.Progression.Promote(target, caller) then
			Admin.Reply(caller, target:GetRPName() .. " est promu " .. target:GetGradeData().name .. ".", Shinkai.NOTIFY_SUCCESS)
		else
			Admin.Reply(caller, "Ce personnage est déjà au grade maximal.", Shinkai.NOTIFY_ERROR)
		end
	end,
})

Admin.Register("demote", {
	permission = "demote",
	args = { "player" },
	usage = "<joueur>",
	help = "Fait descendre un personnage d'un grade.",
	run = function(caller, target)
		if not requireChar(caller, target) then return end
		if Shinkai.Progression.Demote(target, caller) then
			Admin.Reply(caller, target:GetRPName() .. " est rétrogradé " .. target:GetGradeData().name .. ".", Shinkai.NOTIFY_SUCCESS)
		else
			Admin.Reply(caller, "Ce personnage est déjà au grade minimal.", Shinkai.NOTIFY_ERROR)
		end
	end,
})

---------------------------------------------------------------------------
-- Souffles
---------------------------------------------------------------------------
Admin.Register("setstyle", {
	permission = "setstyle",
	args = { "player", "string" },
	usage = "<joueur> <id du Souffle | aucun>",
	help = "Attribue un Souffle (flamme, eau, foudre, vent, serpent, brume, son, bete, insecte, fleur).",
	run = function(caller, target, value)
		if not requireChar(caller, target) then return end

		local styleId = string.lower(value)
		if styleId == "aucun" then styleId = "" end

		if not Char.SetStyle(target, styleId) then
			return Admin.Reply(caller, "Souffle inconnu ou réservé à une autre faction : " .. value, Shinkai.NOTIFY_ERROR)
		end

		local style = Shinkai.Styles.Get(styleId)
		local label = style and style.name or "aucun style"
		Shinkai.Notify(target, "Votre style de combat est désormais : " .. label)
		Admin.Reply(caller, target:GetRPName() .. " : " .. label .. ".", Shinkai.NOTIFY_SUCCESS)
		log(caller, "a défini le style de " .. Shinkai.LogName(target) .. " : " .. label)

		if styleId == "" then Char.CheckStyle(target) end
	end,
})

---------------------------------------------------------------------------
-- Expérience, argent, nom
---------------------------------------------------------------------------
Admin.Register("addxp", {
	permission = "addxp",
	args = { "player", "number" },
	usage = "<joueur> <montant>",
	help = "Donne de l'expérience (récompense d'événement, d'entraînement...).",
	run = function(caller, target, amount)
		if not requireChar(caller, target) then return end
		amount = math.floor(amount)
		Shinkai.Progression.AddXP(target, amount, "récompense")
		Admin.Reply(caller, string.format("%s : %+d XP.", target:GetRPName(), amount), Shinkai.NOTIFY_SUCCESS)
		log(caller, string.format("a donné %d XP à %s", amount, Shinkai.LogName(target)))
	end,
})

Admin.Register("setxp", {
	permission = "setxp",
	args = { "player", "number" },
	usage = "<joueur> <montant>",
	help = "Définit l'expérience totale d'un personnage.",
	run = function(caller, target, amount)
		if not requireChar(caller, target) then return end
		Char.SetXP(target, amount)
		Shinkai.Progression.CheckPromotion(target)
		Char.Save(target)
		Admin.Reply(caller, target:GetRPName() .. " : " .. target:GetXP() .. " XP.", Shinkai.NOTIFY_SUCCESS)
		log(caller, string.format("a défini l'XP de %s à %d", Shinkai.LogName(target), target:GetXP()))
	end,
})

Admin.Register("setmoney", {
	permission = "setmoney",
	args = { "player", "number" },
	usage = "<joueur> <montant>",
	help = "Définit l'argent d'un personnage.",
	run = function(caller, target, amount)
		if not requireChar(caller, target) then return end
		Char.SetMoney(target, amount)
		Char.Save(target)
		Admin.Reply(caller, string.format("%s : %d %s.", target:GetRPName(), target:GetMoney(), Shinkai.Config.Currency), Shinkai.NOTIFY_SUCCESS)
		log(caller, string.format("a défini l'argent de %s à %d", Shinkai.LogName(target), target:GetMoney()))
	end,
})

Admin.Register("setname", {
	permission = "setname",
	args = { "player", "text" },
	usage = "<joueur> <nouveau nom>",
	help = "Renomme un personnage.",
	run = function(caller, target, name)
		local before = Shinkai.LogName(target)
		local ok, err = Char.SetName(target, name)
		if not ok then return Admin.Reply(caller, err, Shinkai.NOTIFY_ERROR) end

		Admin.Reply(caller, "Personnage renommé : " .. target:GetRPName(), Shinkai.NOTIFY_SUCCESS)
		log(caller, "a renommé " .. before .. " en " .. target:GetRPName())
	end,
})

---------------------------------------------------------------------------
-- Soutien en jeu
---------------------------------------------------------------------------
Admin.Register("heal", {
	permission = "heal",
	args = { "player" },
	usage = "<joueur>",
	help = "Rend tous ses PV et son endurance à un joueur.",
	run = function(caller, target)
		if not requireChar(caller, target) or not target:Alive() then return end
		target:SetHealth(target:GetMaxHealth())
		Shinkai.Stamina.Set(target, Shinkai.Stamina.Max(target))
		Admin.Reply(caller, target:GetRPName() .. " a été soigné.", Shinkai.NOTIFY_SUCCESS)
		log(caller, "a soigné " .. Shinkai.LogName(target))
	end,
})

Admin.Register("stamina", {
	permission = "stamina",
	args = { "player" },
	usage = "<joueur>",
	help = "Rend toute son endurance à un joueur.",
	run = function(caller, target)
		if not requireChar(caller, target) then return end
		Shinkai.Stamina.Set(target, Shinkai.Stamina.Max(target))
		Admin.Reply(caller, target:GetRPName() .. " a retrouvé son endurance.", Shinkai.NOTIFY_SUCCESS)
	end,
})

Admin.Register("resetcd", {
	permission = "resetcd",
	args = { "player" },
	usage = "<joueur>",
	help = "Réinitialise les temps de recharge d'un joueur.",
	run = function(caller, target)
		Shinkai.Techniques.ResetCooldowns(target)
		Admin.Reply(caller, "Recharges réinitialisées pour " .. target:GetRPName() .. ".", Shinkai.NOTIFY_SUCCESS)
	end,
})

---------------------------------------------------------------------------
-- Gestion
---------------------------------------------------------------------------
Admin.Register("whitelist", {
	permission = "whitelist",
	args = { "player", "string", "number" },
	usage = "<joueur> <slayer|demon> <1|0>",
	help = "Autorise (1) ou interdit (0) une faction sous whitelist à un joueur.",
	run = function(caller, target, factionId, state)
		factionId = string.lower(factionId)
		local faction = Shinkai.Config.Factions[factionId]
		if not faction then
			return Admin.Reply(caller, "Faction inconnue : " .. factionId, Shinkai.NOTIFY_ERROR)
		end

		local allowed = state ~= 0
		Shinkai.DB.SetWhitelisted(target:SteamID64(), factionId, allowed)
		Admin.Reply(caller, string.format("%s : faction %s %s.", target:Nick(), faction.name, allowed and "autorisée" or "retirée"), Shinkai.NOTIFY_SUCCESS)
		log(caller, string.format("whitelist %s pour %s : %s", faction.name, Shinkai.LogName(target), tostring(allowed)))
	end,
})

Admin.Register("charinfo", {
	permission = "charinfo",
	args = { "player" },
	usage = "<joueur>",
	help = "Affiche la fiche du personnage d'un joueur.",
	run = function(caller, target)
		local char = Char.Get(target)
		if not requireChar(caller, target) then return end

		local style = Shinkai.Styles.Get(char.style)
		local lines = {
			string.format("%s — joué par %s (%s)", char.name, target:Nick(), target:SteamID()),
			string.format("%s, %s, %s", Shinkai.Config.Factions[char.faction].name,
				Grades.DisplayName(target:GetGradeData()), style and style.name or "aucun style"),
			string.format("XP : %d — Argent : %d — PV : %d/%d", char.xp, char.money, target:Health(), target:GetMaxHealth()),
		}

		for _, line in ipairs(lines) do
			if IsValid(caller) then caller:ChatPrint(line) else print(line) end
		end
	end,
})

Admin.Register("annonce", {
	permission = "annonce",
	args = { "text" },
	usage = "<message>",
	help = "Envoie une annonce à tout le serveur.",
	run = function(caller, text)
		PrintMessage(HUD_PRINTTALK, "[Annonce] " .. text)
		Shinkai.Notify(nil, "[Annonce] " .. text)
		log(caller, "annonce : " .. text)
	end,
})

Admin.Register("aide", {
	permission = "menu",
	help = "Liste les commandes du staff auxquelles vous avez accès.",
	run = function(caller)
		local names = table.GetKeys(Admin.Commands)
		table.sort(names)

		for _, name in ipairs(names) do
			local command = Admin.Commands[name]
			if Admin.HasPermission(caller, command.permission) then
				local line = string.format("!%s %s — %s", name, command.usage or "", command.help or "")
				if IsValid(caller) then caller:ChatPrint(line) else print(line) end
			end
		end
	end,
})
