-- Organisation du staff.
-- Chaque groupe (usergroup de ULX / SAM / FAdmin ou "ulx adduser") appartient
-- à un pôle et possède un niveau. Une commande est autorisée si le niveau du
-- joueur est supérieur ou égal au niveau demandé par la permission.

local C = Shinkai.Config

C.Staff = {}

C.Staff.Groups = {
	superadmin  = { pole = "Direction générale",      level = 100 },
	admin       = { pole = "Administration",          level = 80 },
	developpeur = { pole = "Développement",           level = 80 },
	moderateur  = { pole = "Modération",              level = 50 },
	animateur   = { pole = "Animation et événements", level = 40 },
	cm          = { pole = "Community management",    level = 10 },
}

C.Staff.Permissions = {
	menu      = 10,  -- ouvrir le menu staff (F4)
	charinfo  = 10,
	annonce   = 40,
	heal      = 40,
	stamina   = 40,
	resetcd   = 40,
	noclip    = 40,
	addxp     = 40,
	promote   = 50,
	demote    = 50,
	setstyle  = 50,
	setname   = 50,
	whitelist = 50,
	setgrade  = 80,
	setxp     = 80,
	setmoney  = 80,
}
