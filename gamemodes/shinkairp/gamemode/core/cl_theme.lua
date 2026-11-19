-- Thème de l'interface : polices, couleurs et petits outils de dessin
-- partagés par le HUD et les menus.

Shinkai.UI = Shinkai.UI or {}
local UI = Shinkai.UI

UI.Colors = {
	background = Color(14, 14, 18, 235),
	panel = Color(26, 26, 32, 240),
	panelLight = Color(40, 40, 50, 240),
	border = Color(70, 70, 85),
	text = Color(235, 235, 235),
	muted = Color(160, 160, 170),
	accent = Color(215, 60, 60),
	health = Color(200, 50, 55),
	stamina = Color(70, 170, 230),
	xp = Color(230, 190, 80),
	success = Color(90, 190, 110),
}

local function font(name, size, weight)
	surface.CreateFont(name, { font = "Roboto", size = size, weight = weight or 500, extended = true })
end

font("Shinkai.Title", 34, 700)
font("Shinkai.Large", 24, 600)
font("Shinkai.Medium", 19, 500)
font("Shinkai.Small", 16, 500)
font("Shinkai.Tiny", 13, 500)

-- Barre de progression avec texte centré. fraction entre 0 et 1.
function UI.DrawBar(x, y, w, h, fraction, color, text)
	draw.RoundedBox(4, x, y, w, h, UI.Colors.background)

	local fill = math.floor((w - 4) * math.Clamp(fraction, 0, 1))
	if fill > 0 then
		draw.RoundedBox(3, x + 2, y + 2, fill, h - 4, color)
	end
	if text then
		draw.SimpleText(text, "Shinkai.Small", x + w / 2, y + h / 2, UI.Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

-- Applique le style du thème à une fenêtre DFrame.
function UI.StyleFrame(frame, title)
	frame:SetTitle("")
	frame.Paint = function(_, w, h)
		draw.RoundedBox(6, 0, 0, w, h, UI.Colors.background)
		draw.RoundedBoxEx(6, 0, 0, w, 32, UI.Colors.panel, true, true, false, false)
		draw.SimpleText(title, "Shinkai.Medium", 12, 16, UI.Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
end

-- Bouton plat du thème. `color` est facultative.
function UI.StyleButton(button, color)
	button:SetFont("Shinkai.Small")
	button:SetTextColor(UI.Colors.text)
	button.Paint = function(self, w, h)
		local base = color or UI.Colors.panelLight
		if not self:IsEnabled() then
			base = UI.Colors.panel
		elseif self:IsHovered() then
			base = Color(math.min(255, base.r + 25), math.min(255, base.g + 25), math.min(255, base.b + 25), base.a)
		end
		draw.RoundedBox(4, 0, 0, w, h, base)
	end
end
