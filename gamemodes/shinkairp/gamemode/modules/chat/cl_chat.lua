-- Affichage du chat RP.

local WHITE = Color(235, 235, 235)
local NAME = Color(240, 210, 130)
local GREY = Color(170, 170, 170)
local ACTION = Color(200, 170, 255)
local YELL = Color(255, 150, 90)
local OOC = Color(120, 190, 255)

local FORMATS = {
	say = function(name, text, color)
		chat.AddText(color, name, WHITE, " dit : ", text)
	end,
	whisper = function(name, text, color)
		chat.AddText(color, name, GREY, " chuchote : ", text)
	end,
	yell = function(name, text, color)
		chat.AddText(color, name, YELL, " crie : ", text)
	end,
	me = function(name, text)
		chat.AddText(ACTION, "* ", name, " ", text)
	end,
}

net.Receive("Shinkai.Chat", function()
	local kind = net.ReadString()
	local speaker = net.ReadEntity()
	local text = net.ReadString()
	if not IsValid(speaker) then return end

	if kind == "ooc" then
		chat.AddText(OOC, "[HRP] ", speaker:Nick(), WHITE, " : ", text)
		return
	end

	local format = FORMATS[kind]
	if not format then return end

	-- Couleur neutre : le chat ne doit pas trahir la faction d'un personnage.
	format(speaker:GetRPName(), text, NAME)
end)
