-- Déclaration de tous les messages réseau du gamemode.

local MESSAGES = {
	"Shinkai.Notify",
	"Shinkai.Ready",
	-- Personnages
	"Shinkai.CharMenu",
	"Shinkai.CharCreate",
	"Shinkai.CharSelect",
	"Shinkai.CharDelete",
	"Shinkai.StyleMenu",
	"Shinkai.StyleChoose",
	-- Combat
	"Shinkai.UseTechnique",
	"Shinkai.Cooldown",
	"Shinkai.CooldownReset",
	"Shinkai.Effect",
	"Shinkai.EffectClear",
	"Shinkai.FX",
	-- Chat
	"Shinkai.Chat",
}

for _, name in ipairs(MESSAGES) do
	util.AddNetworkString(name)
end
