local checks = 0
local function check(cond, msg) checks = checks + 1; if not cond then error("ÉCHEC : " .. msg, 2) end end

_local = _newPlayer("Moi", "superadmin")
include("cl_init.lua")
GAMEMODE = GM; GM = nil
local W = GAMEMODE_DIR .. "/entities/weapons/"
_loadWeapon("shinkai_base_melee", W .. "shinkai_base_melee.lua")
_loadWeapon("shinkai_katana", W .. "shinkai_katana.lua")
_loadWeapon("shinkai_griffes", W .. "shinkai_griffes.lua")
print("fichiers chargés côté client : " .. #_included)
for _, path in ipairs(_included) do check(not path:match("/sv_[^/]*$"), "aucun fichier serveur chargé côté client : " .. path) end

local function setChar(p, faction, grade, style, name)
	p.nw = { ShinkaiHasChar = true, ShinkaiName = name or "Haruto Minase", ShinkaiFaction = faction, ShinkaiGrade = grade,
		ShinkaiStyle = style, ShinkaiXP = Shinkai.Config.Grades[faction][grade].xp + 10, ShinkaiMoney = 15000,
		ShinkaiStamina = 80, ShinkaiMaxStamina = 150 }
	p.alive = true; p.health = 120; p.maxHealth = 150; p.weapons = {}; p.weapon = nil
	p:Give(Shinkai.Config.Factions[faction].weapon); p:SelectWeapon(Shinkai.Config.Factions[faction].weapon)
end
local function paintHUD()
	local before = _drawn
	for _, name in ipairs({ "HUDPaintBackground", "HUDPaint" }) do for _, fn in pairs(_hooks(name)) do fn() end end
	GAMEMODE:HUDDrawTargetID()
	return _drawn - before
end

-- Connexion : pas de personnage
for _, fn in pairs(_hooks("InitPostEntity")) do fn() end
check(_lastSent("Shinkai.Ready") ~= nil, "le client signale qu'il est prêt")
check(paintHUD() == 0, "pas de HUD sans personnage")
check(hook.Run("HUDShouldDraw", "CHudHealth") == false and hook.Run("HUDShouldDraw", "CHudChat") == nil, "HUD par défaut masqué")

-- HUD pour chaque faction, chaque grade et chaque style
local other = _newPlayer("Autre"); setChar(other, "demon", 5, "art_demoniaque", "Akuma Kage")
local total = 0
for _, faction in ipairs({ "slayer", "demon" }) do
	for grade = 1, 12 do
		for _, style in ipairs(Shinkai.Styles.GetForFaction(faction)) do
			setChar(_local, faction, grade, style.id)
			_local.lookAt = other; _local.keys[IN_ATTACK2] = (grade % 2 == 0)
			local n = paintHUD(); check(n > 5, "HUD dessiné"); total = total + n
		end
	end
end
setChar(_local, "slayer", 2, ""); check(paintHUD() > 3, "HUD sans Souffle")
other.nw.ShinkaiInvisible = true; local hidden = paintHUD(); other.nw.ShinkaiInvisible = false
check(paintHUD() == hidden + 1, "le nom d'un joueur invisible n'est pas affiché")
_local.alive = false; check(paintHUD() >= 2, "écran de mort"); _local.alive = true
print("éléments de HUD dessinés : " .. total)

-- Effets, recharges, techniques
setChar(_local, "slayer", 12, "son"); _local.keys = {}
_receive("Shinkai.Effect", nil, "blind", 6); _receive("Shinkai.Effect", nil, "rage", 20); _receive("Shinkai.Effect", nil, "stun", 2)
check(Shinkai.Effects.Remaining("blind") > 5, "aveuglement suivi côté client"); paintHUD()
_receive("Shinkai.Effect", nil, "stun", 0); check(Shinkai.Effects.Remaining("stun") == 0, "effet retiré")
_receive("Shinkai.Cooldown", nil, 3, 20); local left, dur = Shinkai.Techniques.GetCooldown(3)
check(left > 19 and dur == 20, "recharge suivie côté client"); check(Shinkai.Techniques.LastCast.name == "Bombe aveuglante", "nom de la technique affiché")
_receive("Shinkai.Cooldown", nil, 1, 3); paintHUD(); _advance(1); paintHUD()
_receive("Shinkai.CooldownReset", nil); check(Shinkai.Techniques.GetCooldown(3) == 0, "recharges réinitialisées")
_receive("Shinkai.EffectClear", nil); check(Shinkai.Effects.Remaining("blind") == 0, "effets effacés")

local bind = _hooks("PlayerBindPress")["Shinkai.Techniques"]
check(bind(_local, "slot3", true) == true, "touche 3 capturée"); check(_lastSent("Shinkai.UseTechnique").data[1] == 3, "demande de technique envoyée")
check(bind(_local, "slot7", true) == true and _lastSent("Shinkai.UseTechnique").data[1] == 7, "7e technique accessible")
check(bind(_local, "+forward", true) == nil, "les autres touches ne sont pas bloquées")
_local.weapon = nil; check(bind(_local, "slot3", true) == nil, "sans arme : sélection d'arme normale"); _local:SelectWeapon("shinkai_katana")
_concommands.shinkai_technique(_local, "shinkai_technique", { "2" }); check(_lastSent("Shinkai.UseTechnique").data[1] == 2, "commande shinkai_technique")

-- Effets visuels, chat, notifications
for kind = 1, 4 do _receive("Shinkai.FX", nil, kind, Vector(0, 0, 0), Vector(1, 0, 0), Color(255, 0, 0), 1) end
for _, kind in ipairs({ "say", "whisper", "yell", "me", "ooc" }) do _receive("Shinkai.Chat", nil, kind, other, "Bonjour") end
check(_chat == 5, "5 modes de chat affichés")
_receive("Shinkai.Notify", nil, "Test", 1); check(_notes == 1, "notification affichée")

-- Prédiction : paralysie et pas silencieux
local cleared = 0
local cmd = { ClearMovement = function() cleared = cleared + 1 end, ClearButtons = function() cleared = cleared + 1 end }
_hooks("StartCommand")["Shinkai.Stun"](_local, cmd); check(cleared == 0, "libre de ses mouvements")
_local.nw.ShinkaiStunEnd = CurTime() + 5; _hooks("StartCommand")["Shinkai.Stun"](_local, cmd); check(cleared == 2, "paralysé : commandes annulées")
_local.nw.ShinkaiStunEnd = 0
check(_hooks("PlayerFootstep")["Shinkai.Invisible"](_local) == nil, "pas audibles")
_local.nw.ShinkaiInvisible = true; check(_hooks("PlayerFootstep")["Shinkai.Invisible"](_local) == true, "invisible : pas silencieux"); _local.nw.ShinkaiInvisible = false

-- Menus
local chars = {
	{ id = 1, name = "Haruto Minase", faction = "slayer", grade = 12, style = "son", model = "x" },
	{ id = 2, name = "Akuma Kage", faction = "demon", grade = 1, style = "", model = "x" },
}
_receive("Shinkai.CharMenu", nil, { characters = chars, factions = { slayer = true, demon = true }, active = 1 })
local n = _exercise(); check(n > 10, "liste des personnages construite (" .. n .. " panneaux)")
check(_lastSent("Shinkai.CharSelect") ~= nil and _lastSent("Shinkai.CharDelete") ~= nil, "sélection et suppression envoyées")

-- Écran de choix de la faction : on clique au centre des zones de factions.png.
local function screenOf(list) for i = #list, 1, -1 do if rawget(list[i], "OnMousePressed") then return list[i] end end end
local function click(screen, x, y) -- coordonnées dans l'image 1672 x 941, écran 1920 x 1080
	local scale = math.min(1920 / 1672, 1080 / 941)
	screen.cursor = { (1920 - 1672 * scale) / 2 + x * scale, (1080 - 941 * scale) / 2 + y * scale }
	screen.OnMousePressed(screen, MOUSE_LEFT)
end
local function factionFlow(images, factions, x, y, expected, preselected)
	_images = images
	_receive("Shinkai.CharMenu", nil, { characters = {}, factions = factions, active = 0 })
	local screen = screenOf(_panels); check(screen, "le premier personnage ouvre le choix de faction")
	_polys = 0
	screen.hovered = false; screen.Paint(screen, 1920, 1080)
	if not preselected then
		click(screen, 850, 870) -- Confirmer sans faction : rien
		check(#_panels == 1, "confirmer sans faction ne fait rien")
		click(screen, 1300, 710)
	end
	local notes = _notes
	click(screen, x, y); screen.Paint(screen, 1920, 1080)
	if not factions[expected == "slayer" and "demon" or "slayer"] then check(_notes == notes + 1, "faction verrouillée signalée") end
	check(_polys > 0, "zones dessinées")
	click(screen, 850, 870)
	local form = _panels; _panels = {}
	for _, p in ipairs(form) do local paint = rawget(p, "Paint"); if type(paint) == "function" then paint(p, 820, 520) end end
	for _, p in ipairs(form) do if rawget(p, "OnSelect") then p.OnSelect(p, 1, "Apparence 1", 1) end end
	-- Le bouton « Créer » est le seul DButton du formulaire avec une couleur de faction.
	local sent = _countSent("Shinkai.CharCreate")
	for _, p in ipairs(form) do local c = rawget(p, "DoClick"); if c and p.class == "DButton" then c(p) end end
	check(_countSent("Shinkai.CharCreate") == sent + 1, "formulaire envoyé")
	local msg = _lastSent("Shinkai.CharCreate")
	check(msg.data[1] == "Akira Test Akira Test", "prénom et nom réunis"); check(msg.data[2] == expected, "faction choisie : " .. expected)
	_panels = {}
end
factionFlow({ ["shinkai/factions.png"] = true, ["shinkai/pourfendeurs.png"] = true }, { slayer = true, demon = true }, 1300, 710, "slayer")
factionFlow({}, { slayer = true, demon = true }, 370, 710, "demon") -- sans images : fond uni
factionFlow({}, { slayer = true, demon = false }, 370, 710, "slayer", true) -- démon sous whitelist : refusé, Pourfendeur présélectionné
_receive("Shinkai.CharMenuClose", nil)
_receive("Shinkai.CharMenu", nil, { characters = { chars[1], chars[2], chars[1] }, factions = { slayer = true }, active = 0 }); _exercise()

setChar(_local, "slayer", 2, "")
_receive("Shinkai.StyleMenu", nil); n = _exercise(); check(n >= 12, "menu des 10 Souffles construit")
check(_lastSent("Shinkai.StyleChoose") ~= nil, "choix du Souffle envoyé")
for _, style in pairs(Shinkai.Styles.List) do check(#Shinkai.Styles.DescribeModifiers(style) >= 1, "particularités décrites") end

for _, setup in ipairs({ { "slayer", 12, "serpent" }, { "slayer", 1, "" }, { "demon", 6, "art_demoniaque" } }) do
	setChar(_local, setup[1], setup[2], setup[3])
	_concommands.shinkai_techniques(); n = _exercise(); check(n >= 3, "fiche des techniques construite")
	_concommands.shinkai_techniques() -- second appel : referme
	_exercise()
end

setChar(_local, "slayer", 12, "son")
_concommands.shinkai_admin(); n = _exercise(); check(n > 15, "menu staff construit (" .. n .. " panneaux)")
local commands = {}
for _, c in ipairs(_console) do commands[c[2]] = true; check(c[1] == "shinkai" and c[3]:match("^#%d+$"), "commande staff bien formée") end
for _, name in ipairs({ "setgrade", "promote", "demote", "setstyle", "addxp", "heal", "resetcd", "charinfo" }) do check(commands[name], "bouton staff : " .. name) end
_local.group = nil; _concommands.shinkai_admin(); check(_exercise() == 0, "menu staff fermé aux joueurs")

print("CLIENT OK — " .. checks .. " vérifications réussies")
