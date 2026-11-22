local checks = 0
local function check(cond, msg) checks = checks + 1; if not cond then error("ÉCHEC : " .. msg, 2) end end
local function eq(a, b, msg) checks = checks + 1; if a ~= b then error(("ÉCHEC : %s (obtenu %s, attendu %s)"):format(msg, tostring(a), tostring(b)), 2) end end
local function near(a, b, msg) checks = checks + 1; if math.abs(a - b) > 0.01 then error(("ÉCHEC : %s (obtenu %s, attendu %s)"):format(msg, tostring(a), tostring(b)), 2) end end

-- 1. Chargement
include("init.lua")
GAMEMODE = GM; GM = nil
local W = GAMEMODE_DIR .. "/entities/weapons/"
_loadWeapon("shinkai_base_melee", W .. "shinkai_base_melee.lua")
_loadWeapon("shinkai_katana", W .. "shinkai_katana.lua")
_loadWeapon("shinkai_griffes", W .. "shinkai_griffes.lua")
print("fichiers chargés côté serveur : " .. #_included)

local C, Styles, Char, Tech, Fx, Stam = Shinkai.Config, Shinkai.Styles, Shinkai.Char, Shinkai.Techniques, Shinkai.Effects, Shinkai.Stamina

-- 2. Registres
eq(#C.Grades.slayer, 12, "12 grades Pourfendeurs"); eq(#C.Grades.demon, 12, "12 grades Démons")
eq(#Styles.GetForFaction("slayer"), 10, "10 Souffles"); eq(#Styles.GetForFaction("demon"), 1, "1 style démon")
for _, s in ipairs(Styles.GetForFaction("slayer")) do
	check(#s.techniques >= 6, s.id .. " a 6 techniques")
	for i = 1, 6 do eq(s.techniques[i].tier, i, s.id .. " technique " .. i .. " de niveau " .. i) end
	for _, t in ipairs(s.techniques) do check(type(t.execute) == "function" and t.name and t.description, s.id .. " technique complète") end
end
eq(C.Grades.demon[9].hp, 2450, "Lune inférieure = PV Kinoe"); eq(C.Grades.demon[12].endurance, 1000, "END démon héritée")
eq(Styles.GetCost(Styles.Get("foudre"), Styles.Get("foudre").techniques[6]), 100, "coût ultime Foudre")
eq(Styles.GetCost(Styles.Get("flamme"), Styles.Get("flamme").techniques[6]), 90, "coût ultime Flamme")
near(Styles.GetCooldown(Styles.Get("brume"), Styles.Get("brume").techniques[1]), 3 * 0.7, "recharge Brume réduite")

-- 3. Connexion et création de personnage
local function join(nick, group)
	local p = _newPlayer(nick, group)
	hook.Call("PlayerInitialSpawn", GAMEMODE, p)
	p:Spawn()
	_receive("Shinkai.Ready", p)
	return p
end
local function create(p, name, faction)
	p.ShinkaiNextCharRequest = 0
	_receive("Shinkai.CharCreate", p, name, faction, 1)
end
local function select(p, i)
	p.ShinkaiNextCharRequest = 0
	_receive("Shinkai.CharSelect", p, p.ShinkaiChars[i].id)
end

local A = join("Alice")
check(A.god and A.frozen, "sans personnage : figé et invulnérable")
check(not A:HasCharacter(), "pas de personnage au départ")
check(_lastSent("Shinkai.CharMenu") ~= nil, "menu personnages envoyé")
create(A, "X", "slayer"); eq(#A.ShinkaiChars, 0, "nom trop court refusé")
create(A, "Haruto 123", "slayer"); eq(#A.ShinkaiChars, 0, "nom avec chiffres refusé")
create(A, "  Haruto   Minase ", "slayer"); eq(#A.ShinkaiChars, 1, "personnage créé")
check(A:HasCharacter(), "le premier personnage entre directement en jeu"); check(_lastSent("Shinkai.CharMenuClose") ~= nil, "menus fermés")
eq(A.ShinkaiChars[1].name, "Haruto Minase", "nom nettoyé")
create(A, "haruto minase", "slayer"); eq(#A.ShinkaiChars, 1, "nom en double refusé")
create(A, "Éloïse d'Arc-en-Ciel", "pirate"); eq(#A.ShinkaiChars, 1, "faction inconnue refusée")
select(A, 1)
check(A:HasCharacter() and A:Alive() and not A.god and not A.frozen, "personnage en jeu")
eq(A:GetRPName(), "Haruto Minase", "nom RP"); eq(A:GetMaxHealth(), 50, "PV Aspirant"); eq(A:Health(), 50, "PV pleins")
eq(A:GetMaxStamina(), 100, "END Aspirant"); eq(A:GetStamina(), 100, "endurance pleine")
near(A.run, 220, "vitesse de course Aspirant"); eq(A:GetMoney(), C.StartMoney, "argent de départ")
check(A:HoldsShinkaiWeapon() and A.weapon.class == "shinkai_katana", "katana équipé")
check(A:GetStyle() == nil, "Aspirant sans Souffle")

-- 4. Staff : permissions et grade
local before = _countSent("Shinkai.StyleMenu")
_concommands.shinkai(A, "shinkai", { "setgrade", "#" .. A:UserID(), "mizunoto" })
eq(A:GetGradeIndex(), 1, "un joueur ne peut pas se promouvoir")
_concommands.shinkai(NULL, "shinkai", { "setgrade", "#" .. A:UserID(), "mizunoto" })
eq(A:GetGradeIndex(), 2, "la console promeut"); eq(A:GetMaxHealth(), 150, "PV Mizunoto"); eq(A:GetXP(), 100, "XP alignée sur le grade")
eq(_countSent("Shinkai.StyleMenu"), before + 1, "menu de choix du Souffle proposé")
_receive("Shinkai.StyleChoose", A, "art_demoniaque"); eq(A:GetStyleId(), "", "style d'une autre faction refusé")
_receive("Shinkai.StyleChoose", A, "foudre"); eq(A:GetStyleId(), "foudre", "Souffle choisi")
_receive("Shinkai.StyleChoose", A, "eau"); eq(A:GetStyleId(), "foudre", "le choix est définitif")
near(A.run, 220 * 1.10 * 1.15, "vitesse Mizunoto + bonus Foudre")

-- 5. Démon et style automatique
local B = join("Bob")
create(B, "Akuma Kage", "demon"); select(B, 1)
eq(B.weapon.class, "shinkai_griffes", "griffes équipées")
Shinkai.Progression.SetGrade(B, 2)
eq(B:GetStyleId(), "art_demoniaque", "style démon attribué automatiquement")

local function face(p, target, dist)
	p:SetPos(Vector(0, 0, 0)); p.eye = Angle(0, 0, 0); p.vel = Vector()
	target:SetPos(Vector(dist, 0, 0)); target.eye = Angle(0, 180, 0); target.vel = Vector()
end
local function ready(p) Tech.ResetCooldowns(p); p.ShinkaiNextTechnique = 0; Stam.Set(p, Stam.Max(p)); p.ShinkaiStaminaUsed = CurTime() end

-- 6. Technique offensive : dégâts, coût, recharge
face(A, B, 60); ready(A)
check(Tech.Use(A, 1), "Éclair fulgurant lancé")
_advance(0.5)
eq(B:Health(), 150 - 20, "technique I = 20 dégâts à Mizunoto")
near(Stam.Get(A), 150 - 20, "coût d'endurance Foudre (20)")
check(Tech.GetCooldown(A, 1) > 0, "recharge en cours")
check(not Tech.Use(A, 1), "impossible pendant la recharge")
check(not Tech.Use(A, 3), "technique III verrouillée à Mizunoto")
A.weapon = nil; ready(A); check(not Tech.Use(A, 1), "impossible sans arme en main"); A:SelectWeapon("shinkai_katana")
Stam.Set(A, 5); Tech.ResetCooldowns(A); A.ShinkaiNextTechnique = 0; check(not Tech.Use(A, 1), "impossible sans endurance")

-- Coup de base
face(A, B, 60); B:SetHealth(150); A.weapon.nextFire = 0
A.weapon:PrimaryAttack()
check(B.lastDamage == 10, "coup de base = Dégâts du grade (10)")

-- 7. Paralysie (Foudre III)
Shinkai.Progression.SetGrade(A, 4); Shinkai.Progression.SetGrade(B, 4)
face(A, B, 80); ready(A)
check(Tech.Use(A, 3), "Tonnerre céleste lancé")
check(B:IsStunned(), "cible paralysée")
ready(B); check(not Tech.Use(B, 1), "un joueur paralysé ne peut pas agir")
_advance(3); check(not B:IsStunned(), "paralysie terminée")

-- 8. Troisièmes mouvements des autres Souffles
local Cc = join("Chloe"); create(Cc, "Sakura Hana", "slayer"); select(Cc, 1); Shinkai.Progression.SetGrade(Cc, 12)
local function setup(style)
	check(Char.SetStyle(A, style), "attribution " .. style)
	Shinkai.Progression.SetGrade(A, 12); Shinkai.Progression.SetGrade(B, 12)
	if not B:Alive() then B:Spawn() end
	Fx.Clear(A); Fx.Clear(B); Fx.Clear(Cc)
	A:SetHealth(A:GetMaxHealth()); B:SetHealth(B:GetMaxHealth())
	face(A, B, 80); Cc:SetPos(Vector(0, 60, 0)); A.lookAt = nil; ready(A)
end

setup("flamme"); check(Tech.Use(A, 3), "Croissant de feu"); check(B.vel.x > 500 and B.vel.z > 0, "Flamme III repousse")
check(B:Health() < B:GetMaxHealth(), "Flamme III inflige des dégâts")
setup("eau"); check(Tech.Use(A, 3), "Vague ascendante"); check(A.vel.z > 500, "Eau III propulse en l'air")
setup("vent"); check(Tech.Use(A, 3), "Lames venteuses"); check(A.vel.x > 2000, "Vent III : très long dash")
_advance(0.8); near(B:GetMaxHealth() - B:Health(), 40 * 320 / 10 * 1.3, "Vent III plus puissant (x1,3)")
setup("serpent"); check(Tech.Use(A, 3), "Serpent ondulant")
near(A:GetPos().x, 80 + 60, "Serpent III : dans le dos de la cible"); eq(B:Health(), B:GetMaxHealth(), "Serpent III sans dégâts")
eq(A:GetMaxHealth(), math.Round(4800 * 0.85), "Serpent : PV réduits")
setup("serpent"); check(Tech.Use(A, 7), "Mue furtive"); check(A:IsInvisible(), "Serpent : invisibilité indépendante")
B:SetPos(Vector(2000, 0, 0)); ready(A); local ok = Tech.Use(A, 3); check(not ok, "téléportation sans cible refusée")
near(Stam.Get(A), Stam.Max(A), "technique annulée non facturée")
setup("brume"); check(Tech.Use(A, 3), "Voile de brume"); check(A:IsInvisible() and A.nodraw, "Brume III rend invisible")
A.ShinkaiNextTechnique = 0; check(Tech.Use(A, 1), "attaque depuis l'invisibilité"); check(not A:IsInvisible(), "attaquer rompt l'invisibilité")
setup("brume"); Tech.Use(A, 3); _advance(7.2); check(not A:IsInvisible() and not A.nodraw, "invisibilité expirée")
setup("son"); check(Tech.Use(A, 3), "Bombe aveuglante")
check(Fx.Has(B, "blind"), "Son III aveugle l'adversaire"); check(not Fx.Has(Cc, "blind") and not Fx.Has(A, "blind"), "alliés épargnés")
eq(B:Health(), B:GetMaxHealth(), "Son III sans dégâts"); eq(A:GetMaxStamina(), 1250, "Son : endurance supérieure")
local blind = B.ShinkaiEffects.blind.ends - CurTime(); check(blind >= 5 and blind <= 7, "aveuglement de 5 à 7 s")
setup("son"); check(Tech.Use(A, 7), "Tempo éclair"); near(A:GetPos().x, 80 - 60, "Son : téléportation devant la cible")
setup("bete"); local runBefore = A.run; check(Tech.Use(A, 3), "Mode Rage")
near(A.run, 220 * (200 + 40) / 100, "Rage : +40 VIT"); eq(A:GetMaxHealth(), 3600, "Rage : PV max -25 %")
eq(A:Health(), 3600, "Rage : PV actuels réduits"); near(Shinkai.Stats.GetDamage(A), 480, "Rage : dégâts x1,5")
_advance(C.Rage.Duration + 0.2); near(A.run, runBefore, "Rage terminée : vitesse normale"); eq(A:GetMaxHealth(), 4800, "Rage terminée : PV max rétablis")
Shinkai.Progression.SetGrade(A, 4); Fx.Apply(A, "rage", 5); near(A.run - 220 * 1.20, 220 * 0.40, "bonus de rage identique à tous les grades"); Fx.Clear(A)
setup("insecte"); A:SetHealth(1000); check(Tech.Use(A, 3), "Remède du papillon"); eq(A:Health(), 1000 + 1200, "Insecte III : soin immédiat sur soi")
setup("insecte"); Cc:SetHealth(100); A.lookAt = Cc; check(Tech.Use(A, 3), "soin d'un allié"); eq(Cc:Health(), 100 + 1200, "Insecte III : soin immédiat d'un allié")
setup("fleur"); A:SetHealth(1000); check(Tech.Use(A, 3), "Floraison apaisante"); eq(A:Health(), 1000, "Fleur III : pas de soin immédiat")
_advance(8.3); eq(A:Health(), 1000 + 8 * 240, "Fleur III : 40 % en 8 s")
near(220 * 2 * 1.07, A.run, "Fleur : bonus de vitesse"); setup("insecte"); near(220 * 2 * 1.07, A.run, "Insecte : même bonus que Fleur")
check(Styles.Get("foudre").modifiers.speed > Styles.Get("insecte").modifiers.speed, "Foudre plus rapide qu'Insecte")

-- 9. Toutes les techniques de tous les styles s'exécutent sans erreur
local casts = 0
for _, style in pairs(Styles.List) do
	local user, foe = A, B
	if style.faction == "demon" then user, foe = B, A end
	for index in ipairs(style.techniques) do
		Shinkai.Progression.SetGrade(user, 12); Char.SetStyle(user, style.id)
		if not foe:Alive() then foe:Spawn() end
		if not user:Alive() then user:Spawn() end
		Fx.Clear(user); Fx.Clear(foe); foe:SetHealth(foe:GetMaxHealth()); user:SetHealth(user:GetMaxHealth() - 500)
		user:SetPos(Vector(0, 0, 0)); user.eye = Angle(0, 0, 0); foe:SetPos(Vector(80, 0, 0)); foe.eye = Angle(0, 180, 0)
		user.lookAt = nil; ready(user)
		check(Tech.Use(user, index), style.id .. " technique " .. index .. " utilisable")
		_advance(1.5); casts = casts + 1
	end
end
Char.SetStyle(A, "foudre"); Char.SetStyle(B, "art_demoniaque")
print("techniques exécutées : " .. casts)

-- 10. Tir allié, garde, PNJ
A:Spawn(); B:Spawn(); Cc:Spawn(); Fx.Clear(A); Fx.Clear(B)
Shinkai.Actions.Hurt(A, Cc, 100); eq(Cc:Health(), Cc:GetMaxHealth(), "pas de dégâts entre alliés")
face(A, B, 60); B.keys[IN_ATTACK2] = true; ready(B)
Shinkai.Actions.Hurt(A, B, 100); eq(B.lastDamage, 50, "garde : dégâts de face réduits de moitié"); near(Stam.Get(B), Stam.Max(B) - 10, "garde : coûte de l'endurance")
B.eye = Angle(0, 0, 0); Shinkai.Actions.Hurt(A, B, 100); eq(B.lastDamage, 100, "garde inefficace de dos"); B.keys = {}
local npc = _newNPC(); npc:SetPos(Vector(70, 0, 0)); npc.health = 5000; B:SetPos(Vector(5000, 0, 0)); ready(A)
Shinkai.Actions.Slash(A, { damage = 50, style = A:GetStyle() }); eq(npc.health, 4950, "les PNJ sont des cibles valides")
npc.removed = true

-- 11. Progression
local D = join("Dan"); create(D, "Ren Aoki", "slayer"); select(D, 1)
Shinkai.Progression.AddXP(D, 99); eq(D:GetGradeIndex(), 1, "99 XP : toujours Aspirant")
Shinkai.Progression.AddXP(D, 1); eq(D:GetGradeIndex(), 2, "100 XP : Mizunoto")
Shinkai.Progression.AddXP(D, 1000000); eq(D:GetGradeIndex(), 11, "promotion automatique jusqu'à Kinoe, pas Pilier")
check(Shinkai.Progression.Demote(D), "rétrogradation"); eq(D:GetXP(), 7500, "XP ramenée au seuil du grade")
Shinkai.Progression.SetGrade(D, 2); Char.SetXP(D, 100)
-- Victoire en duel
B:Spawn(); B:SetHealth(1); face(D, B, 60)
Shinkai.Actions.Hurt(D, B, 50); check(not B:Alive(), "le démon est vaincu")
eq(D:GetXP(), 100 + C.Progression.KillXP + C.Progression.KillXPPerGrade * 11, "XP de victoire")
hook.Call("PlayerDeathThink", GAMEMODE, B); check(not B:Alive(), "pas de réapparition avant le délai")
_advance(C.RespawnTime + 0.1); B.keys[IN_JUMP] = true; hook.Call("PlayerDeathThink", GAMEMODE, B); B.keys = {}
check(B:Alive() and B:Health() == B:GetMaxHealth(), "réapparition avec tous ses PV")

-- 12. Endurance : sprint, épuisement, récupération
ready(D); D.sprinting = true; D.vel = Vector(300, 0, 0)
_advance(5); near(Stam.Get(D), Stam.Max(D) - 5 * C.Stamina.SprintDrain, "le sprint consomme l'endurance")
Stam.Set(D, 0.2); _advance(0.3); check(D.ShinkaiExhausted and D.run == D.walk, "épuisé : plus de sprint")
D.sprinting = false; D.vel = Vector(); _advance(C.Stamina.RegenDelay + 6)
check(not D.ShinkaiExhausted and Stam.Get(D) > 30, "récupération après repos")
_advance(30); near(Stam.Get(D), Stam.Max(D), "endurance plafonnée au maximum")

-- 13. Régénération des Démons
B:SetHealth(1000); B.ShinkaiLastHurt = CurTime(); _advance(3); eq(B:Health(), 1000, "pas de régénération en combat")
_advance(6); check(B:Health() > 1000, "régénération démoniaque hors combat")

-- 14. Chat et commandes
local sentBefore = _countSent("Shinkai.Chat")
eq(hook.Run("PlayerSay", A, "Bonjour"), "", "chat intercepté"); eq(_countSent("Shinkai.Chat"), sentBefore + 1, "message RP diffusé")
eq(_lastSent("Shinkai.Chat").data[1], "say", "mode parler")
hook.Run("PlayerSay", A, "/me dégaine son sabre"); eq(_lastSent("Shinkai.Chat").data[1], "me", "mode action")
hook.Run("PlayerSay", A, "//salut"); eq(_lastSent("Shinkai.Chat").data[1], "ooc", "mode hors-RP")
A.group = "moderateur"; hook.Run("PlayerSay", A, "!promote Ren"); eq(D:GetGradeIndex(), 4, "!promote par un modérateur (3 atteint par la victoire, puis 4)")
hook.Run("PlayerSay", A, "!setgrade Ren 12"); eq(D:GetGradeIndex(), 4, "setgrade refusé à un modérateur")
hook.Run("PlayerSay", A, "!setname Ren Kaito Mori"); eq(D:GetRPName(), "Kaito Mori", "renommage")
hook.Run("PlayerSay", A, "!aide"); check(#A.chat > 5, "aide affichée")
hook.Run("PlayerSay", A, "!charinfo Kaito"); check(A.chat[#A.chat]:find("XP"), "fiche personnage")
A.group = "superadmin"; hook.Run("PlayerSay", A, "!setgrade Kaito pilier"); eq(D:GetGradeIndex(), 12, "Pilier attribué par la direction")
hook.Run("PlayerSay", A, "!setstyle Kaito vent"); eq(D:GetStyleId(), "vent", "Souffle attribué par le staff")
hook.Run("PlayerSay", A, "!setmoney Kaito 1234"); eq(D:GetMoney(), 1234, "argent défini")
hook.Run("PlayerSay", A, "!annonce Événement ce soir"); hook.Run("PlayerSay", A, "!heal Kaito"); hook.Run("PlayerSay", A, "!resetcd Kaito"); hook.Run("PlayerSay", A, "!stamina Kaito"); hook.Run("PlayerSay", A, "!addxp Kaito 10")
A.group = nil

-- 15. Whitelist
C.Factions.demon.whitelist = true
local E = join("Eve"); create(E, "Yoru Kuro", "demon"); eq(#E.ShinkaiChars, 0, "faction sous whitelist refusée")
_concommands.shinkai(NULL, "shinkai", { "whitelist", "Eve", "demon", "1" })
create(E, "Yoru Kuro", "demon"); eq(#E.ShinkaiChars, 1, "faction autorisée après whitelist")
C.Factions.demon.whitelist = false

-- 16. Sauvegarde et rechargement
_advance(120)
_removePlayer(D)
local D2 = join("Dan"); D2.index = D.index -- même SteamID
D2.ShinkaiReady = nil; _receive("Shinkai.Ready", D2)
eq(#D2.ShinkaiChars, 1, "personnage retrouvé en base")
local saved = D2.ShinkaiChars[1]
eq(saved.name, "Kaito Mori", "nom sauvegardé"); eq(saved.grade, 12, "grade sauvegardé"); eq(saved.style, "vent", "Souffle sauvegardé")
eq(saved.money, 1234, "argent sauvegardé"); check(saved.playtime >= 120, "temps de jeu sauvegardé"); check(saved.xp >= 15000, "XP sauvegardée")
select(D2, 1); eq(D2:GetMaxHealth(), 4800, "statistiques restaurées à la reconnexion")
-- Changement et suppression de personnage
create(D2, "Second Perso", "slayer"); eq(#D2.ShinkaiChars, 2, "second personnage")
select(D2, 2); eq(D2:GetRPName(), "Kaito Mori", "changement bloqué par le délai")
D2.ShinkaiNextSwitch = 0; select(D2, 2); eq(D2:GetRPName(), "Second Perso", "changement de personnage"); eq(D2:GetMaxHealth(), 50, "statistiques du nouveau personnage")
D2.ShinkaiNextCharRequest = 0; _receive("Shinkai.CharDelete", D2, D2.ShinkaiChars[2].id); eq(#D2.ShinkaiChars, 2, "personnage actif non supprimable")
D2.ShinkaiNextCharRequest = 0; _receive("Shinkai.CharDelete", D2, D2.ShinkaiChars[1].id); eq(#D2.ShinkaiChars, 1, "personnage supprimé")
create(D2, "Trois", "slayer"); create(D2, "Quatre", "slayer"); create(D2, "Cinq", "slayer"); eq(#D2.ShinkaiChars, C.MaxCharacters, "limite de personnages respectée")

-- 17. Bots et divers
local bot = _newPlayer("Bot01"); bot.bot = true
hook.Call("PlayerInitialSpawn", GAMEMODE, bot); _advance(0.1)
check(bot:HasCharacter() and bot:GetStyle() ~= nil, "bot avec personnage temporaire")
hook.Call("ShowHelp", GAMEMODE, A); eq(A.lastCommand, "shinkai_techniques", "F1")
hook.Call("ShowTeam", GAMEMODE, A); hook.Call("ShowSpare2", GAMEMODE, A)
eq(hook.Call("GetFallDamage", GAMEMODE, A, 2000), 0, "pas de dégâts de chute"); check(hook.Call("PlayerNoClip", GAMEMODE, A) == false, "noclip réservé au staff")
local hear = hook.Run("PlayerCanHearPlayersVoice", A, Cc); check(hear ~= nil, "voix de proximité")
Shinkai.Char.SaveAll(); hook.Call("ShutDown", GAMEMODE)
_advance(700) -- XP de présence, sauvegarde automatique
print("SERVEUR OK — " .. checks .. " vérifications réussies")
