-- Création, sélection, modification et sauvegarde des personnages.

Shinkai.Char = Shinkai.Char or {}
local Char = Shinkai.Char
local C = Shinkai.Config
local DB = Shinkai.DB

function Char.Get(ply)
	return ply.ShinkaiChar
end

-- Recopie le personnage actif dans les variables réseau du joueur.
function Char.Sync(ply)
	local char = ply.ShinkaiChar
	ply:SetNW2Bool("ShinkaiHasChar", char ~= nil)
	if not char then return end

	ply:SetNW2String("ShinkaiName", char.name)
	ply:SetNW2String("ShinkaiFaction", char.faction)
	ply:SetNW2String("ShinkaiStyle", char.style)
	ply:SetNW2Int("ShinkaiGrade", char.grade)
	ply:SetNW2Int("ShinkaiXP", char.xp)
	ply:SetNW2Int("ShinkaiMoney", char.money)
end

function Char.Save(ply)
	local char = ply.ShinkaiChar
	if not char then return end

	local now = CurTime()
	char.playtime = char.playtime + (now - (ply.ShinkaiPlayStamp or now))
	ply.ShinkaiPlayStamp = now

	DB.SaveCharacter(char)
end

function Char.SaveAll()
	for _, ply in ipairs(player.GetAll()) do
		Char.Save(ply)
	end
end

---------------------------------------------------------------------------
-- Règles de création
---------------------------------------------------------------------------
function Char.CanUseFaction(ply, factionId)
	local faction = C.Factions[factionId]
	if not faction then return false end
	if not faction.whitelist then return true end
	if Shinkai.Admin.HasPermission(ply, "whitelist") then return true end
	return DB.IsWhitelisted(ply:SteamID64(), factionId)
end

-- Renvoie le nom nettoyé, ou nil et un message d'erreur.
function Char.ValidateName(name)
	name = string.Trim((string.gsub(tostring(name or ""), "%s+", " ")))

	local length = utf8.len(name) or #name
	if length < C.NameMinLength or length > C.NameMaxLength then
		return nil, string.format("Le nom doit contenir entre %d et %d caractères.", C.NameMinLength, C.NameMaxLength)
	end
	-- Lettres (accents compris), espaces, tirets et apostrophes uniquement.
	if string.find(name, "[^%a%s%-'\128-\255]") then
		return nil, "Le nom ne peut contenir que des lettres, espaces, tirets et apostrophes."
	end
	if DB.NameExists(name) then
		return nil, "Ce nom est déjà porté par un autre personnage."
	end
	return name
end

---------------------------------------------------------------------------
-- Menu des personnages
---------------------------------------------------------------------------
function Char.SendMenu(ply)
	local characters = {}
	for _, char in ipairs(ply.ShinkaiChars or {}) do
		characters[#characters + 1] = {
			id = char.id, name = char.name, faction = char.faction,
			grade = char.grade, style = char.style, model = char.model,
		}
	end

	local factions = {}
	for id in pairs(C.Factions) do
		factions[id] = Char.CanUseFaction(ply, id)
	end

	net.Start("Shinkai.CharMenu")
	net.WriteTable({
		characters = characters,
		factions = factions,
		active = ply.ShinkaiChar and ply.ShinkaiChar.id or 0,
	})
	net.Send(ply)
end

-- Charge un personnage et fait apparaître le joueur.
function Char.Load(ply, char)
	Char.Save(ply)

	Shinkai.Effects.Clear(ply)
	Shinkai.Techniques.ResetCooldowns(ply)

	ply.ShinkaiChar = char
	ply.ShinkaiPlayStamp = CurTime()
	ply.ShinkaiNextSwitch = CurTime() + C.CharSwitchCooldown
	Char.Sync(ply)
	ply:Spawn()

	Shinkai.Log("Personnage", Shinkai.LogName(ply) .. " incarne " .. char.name)
	hook.Run("ShinkaiCharacterLoaded", ply, char)
end

-- Les bots reçoivent un personnage temporaire (non sauvegardé) pour pouvoir
-- tester les combats : un bot sur deux est un Démon.
function Char.LoadBot(bot)
	local factionId = bot:UserID() % 2 == 0 and "slayer" or "demon"
	local styles = Shinkai.Styles.GetForFaction(factionId)

	Char.Load(bot, {
		id = 0, steamid = "BOT", name = bot:Nick(), faction = factionId,
		grade = C.StyleMinGrade, style = styles[1] and styles[1].id or "",
		xp = 0, money = 0, model = C.Factions[factionId].models[1],
		playtime = 0, created = os.time(), data = {},
	})
end

local function findOwned(ply, id)
	for index, char in ipairs(ply.ShinkaiChars or {}) do
		if char.id == id then return char, index end
	end
end

-- Limite la fréquence des demandes d'un client.
local function throttled(ply)
	if (ply.ShinkaiNextCharRequest or 0) > CurTime() then return true end
	ply.ShinkaiNextCharRequest = CurTime() + 0.5
	return false
end

net.Receive("Shinkai.Ready", function(_, ply)
	if ply.ShinkaiReady then return end
	ply.ShinkaiReady = true
	ply.ShinkaiChars = DB.LoadCharacters(ply:SteamID64())
	Char.SendMenu(ply)
end)

net.Receive("Shinkai.CharCreate", function(_, ply)
	if throttled(ply) or not ply.ShinkaiReady then return end

	local name = net.ReadString()
	local factionId = net.ReadString()
	local modelIndex = net.ReadUInt(8)

	if #ply.ShinkaiChars >= C.MaxCharacters then
		return Shinkai.Notify(ply, "Vous avez atteint le nombre maximal de personnages.", Shinkai.NOTIFY_ERROR)
	end

	local faction = C.Factions[factionId]
	if not faction or not Char.CanUseFaction(ply, factionId) then
		return Shinkai.Notify(ply, "Cette faction ne vous est pas accessible.", Shinkai.NOTIFY_ERROR)
	end

	local cleanName, err = Char.ValidateName(name)
	if not cleanName then
		return Shinkai.Notify(ply, err, Shinkai.NOTIFY_ERROR)
	end

	local char = DB.CreateCharacter({
		steamid = ply:SteamID64(),
		name = cleanName,
		faction = factionId,
		grade = 1,
		money = C.StartMoney,
		model = faction.models[modelIndex] or faction.models[1],
	})
	if not char then
		return Shinkai.Notify(ply, "La création du personnage a échoué.", Shinkai.NOTIFY_ERROR)
	end

	table.insert(ply.ShinkaiChars, char)
	Shinkai.Log("Personnage", Shinkai.LogName(ply) .. " a créé " .. char.name .. " (" .. faction.name .. ")")
	Shinkai.Notify(ply, "Personnage créé : " .. char.name, Shinkai.NOTIFY_SUCCESS)
	Char.SendMenu(ply)
end)

net.Receive("Shinkai.CharSelect", function(_, ply)
	if throttled(ply) or not ply.ShinkaiReady then return end

	local char = findOwned(ply, net.ReadUInt(32))
	if not char or char == ply.ShinkaiChar then return end

	if ply.ShinkaiChar then
		if not C.AllowCharSwitch then return end
		local wait = (ply.ShinkaiNextSwitch or 0) - CurTime()
		if wait > 0 then
			return Shinkai.Notify(ply, string.format("Changement de personnage possible dans %d s.", math.ceil(wait)), Shinkai.NOTIFY_ERROR)
		end
	end

	Char.Load(ply, char)
end)

net.Receive("Shinkai.CharDelete", function(_, ply)
	if throttled(ply) or not ply.ShinkaiReady or not C.AllowCharDelete then return end

	local char, index = findOwned(ply, net.ReadUInt(32))
	if not char then return end
	if char == ply.ShinkaiChar then
		return Shinkai.Notify(ply, "Impossible de supprimer le personnage en cours d'utilisation.", Shinkai.NOTIFY_ERROR)
	end

	DB.DeleteCharacter(char.id)
	table.remove(ply.ShinkaiChars, index)
	Shinkai.Log("Personnage", Shinkai.LogName(ply) .. " a supprimé " .. char.name)
	Char.SendMenu(ply)
end)

---------------------------------------------------------------------------
-- Modification du personnage actif
---------------------------------------------------------------------------
function Char.SetGrade(ply, index)
	local char = ply.ShinkaiChar
	if not char or not Shinkai.Grades.Get(char.faction, index) then return false end

	char.grade = index
	ply:SetNW2Int("ShinkaiGrade", index)
	Shinkai.Stats.Apply(ply, true)
	Char.CheckStyle(ply)
	Char.Save(ply)
	return true
end

-- Attribue un style ("" pour le retirer).
function Char.SetStyle(ply, styleId)
	local char = ply.ShinkaiChar
	if not char then return false end

	if styleId ~= "" then
		local style = Shinkai.Styles.Get(styleId)
		if not style or style.faction ~= char.faction then return false end
	end

	char.style = styleId
	ply:SetNW2String("ShinkaiStyle", styleId)
	Shinkai.Techniques.ResetCooldowns(ply)
	Shinkai.Stats.Apply(ply, true)
	Char.Save(ply)
	return true
end

function Char.SetXP(ply, amount)
	local char = ply.ShinkaiChar
	if not char then return false end
	char.xp = math.max(0, math.floor(amount))
	ply:SetNW2Int("ShinkaiXP", char.xp)
	return true
end

function Char.SetMoney(ply, amount)
	local char = ply.ShinkaiChar
	if not char then return false end
	char.money = math.max(0, math.floor(amount))
	ply:SetNW2Int("ShinkaiMoney", char.money)
	return true
end

function Char.SetName(ply, name)
	local char = ply.ShinkaiChar
	if not char then return false, "Aucun personnage chargé." end

	local cleanName, err = Char.ValidateName(name)
	if not cleanName then return false, err end

	char.name = cleanName
	ply:SetNW2String("ShinkaiName", cleanName)
	Char.Save(ply)
	return true
end

-- Données libres attachées au personnage (sauvegardées en JSON), pour les
-- futurs systèmes : inventaire, quêtes, réputation...
function Char.GetData(ply, key, default)
	local char = ply.ShinkaiChar
	if not char or char.data[key] == nil then return default end
	return char.data[key]
end

function Char.SetData(ply, key, value)
	local char = ply.ShinkaiChar
	if char then char.data[key] = value end
end

---------------------------------------------------------------------------
-- Choix du Souffle
---------------------------------------------------------------------------
local function needsStyle(char)
	if char.grade < C.StyleMinGrade then return false end
	local style = Shinkai.Styles.Get(char.style)
	return not style or style.faction ~= char.faction
end

-- Vérifie que le personnage possède un style dès qu'il y a droit.
function Char.CheckStyle(ply)
	local char = ply.ShinkaiChar
	if not char or not needsStyle(char) then return end

	local styles = Shinkai.Styles.GetForFaction(char.faction)
	if #styles == 1 then
		Char.SetStyle(ply, styles[1].id)
		Shinkai.Notify(ply, "Vous maîtrisez désormais : " .. styles[1].name, Shinkai.NOTIFY_SUCCESS)
	elseif #styles > 1 then
		if C.StyleSelfChoice then
			net.Start("Shinkai.StyleMenu")
			net.Send(ply)
		else
			Shinkai.Notify(ply, "Vous pouvez apprendre un Souffle : adressez-vous à un formateur.")
		end
	end
end

net.Receive("Shinkai.StyleChoose", function(_, ply)
	local char = ply.ShinkaiChar
	if not char or not C.StyleSelfChoice or not needsStyle(char) then return end

	local style = Shinkai.Styles.Get(net.ReadString())
	if not style or style.faction ~= char.faction then return end

	Char.SetStyle(ply, style.id)
	Shinkai.Notify(ply, "Vous maîtrisez désormais : " .. style.name, Shinkai.NOTIFY_SUCCESS)
	Shinkai.Log("Souffle", Shinkai.LogName(ply) .. " a choisi " .. style.name)
end)

---------------------------------------------------------------------------
-- Sauvegarde automatique
---------------------------------------------------------------------------
timer.Create("Shinkai.Autosave", C.AutosaveInterval, 0, Char.SaveAll)
