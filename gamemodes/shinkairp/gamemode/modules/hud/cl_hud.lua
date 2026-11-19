-- HUD : identité du personnage, PV, endurance, expérience, barre de
-- techniques avec temps de recharge, effets actifs.

local UI = Shinkai.UI
local Colors = UI.Colors
local Styles = Shinkai.Styles
local Techniques = Shinkai.Techniques
local Effects = Shinkai.Effects
local Util = Shinkai.Util

local HIDDEN = {
	CHudHealth = true,
	CHudBattery = true,
	CHudAmmo = true,
	CHudSecondaryAmmo = true,
}

hook.Add("HUDShouldDraw", "Shinkai.HUD", function(name)
	if HIDDEN[name] then return false end
end)

-- Valeurs lissées pour des barres fluides.
local smoothHealth, smoothStamina = 0, 0

local PANEL_W, PANEL_H, MARGIN = 340, 148, 24

---------------------------------------------------------------------------
-- Bloc du personnage (bas gauche)
---------------------------------------------------------------------------
local function drawCharacter(ply, scrH)
	local w, h = PANEL_W, PANEL_H
	local x, y = MARGIN, scrH - h - MARGIN

	draw.RoundedBox(6, x, y, w, h, Colors.panel)

	local faction = ply:GetFactionData()
	local factionColor = faction and faction.color or Colors.text
	surface.SetDrawColor(factionColor)
	surface.DrawRect(x, y + 6, 4, h - 12)

	draw.SimpleText(ply:GetRPName(), "Shinkai.Large", x + 16, y + 8, Colors.text)

	local grade = ply:GetGradeData()
	local style = ply:GetStyle()
	draw.SimpleText(Shinkai.Grades.DisplayName(grade), "Shinkai.Small", x + 16, y + 34, factionColor)
	draw.SimpleText(style and style.name or "Aucun Souffle", "Shinkai.Small", x + w - 12, y + 34,
		style and style.color or Colors.muted, TEXT_ALIGN_RIGHT)

	local frame = FrameTime() * 8
	local maxHealth = math.max(1, ply:GetMaxHealth())
	local maxStamina = math.max(1, ply:GetMaxStamina())
	smoothHealth = Lerp(frame, smoothHealth, math.max(0, ply:Health()))
	smoothStamina = Lerp(frame, smoothStamina, ply:GetStamina())

	UI.DrawBar(x + 16, y + 58, w - 28, 22, smoothHealth / maxHealth, Colors.health,
		Util.FormatNumber(math.max(0, ply:Health())) .. " / " .. Util.FormatNumber(maxHealth) .. " PV")
	UI.DrawBar(x + 16, y + 84, w - 28, 22, smoothStamina / maxStamina, Colors.stamina,
		ply:GetStamina() .. " / " .. maxStamina .. " END")

	-- Expérience vers le grade suivant.
	local nextGrade = Shinkai.Grades.Get(ply:GetFaction(), ply:GetGradeIndex() + 1)
	local fraction, label = 1, "Grade maximal"
	if nextGrade and grade then
		local span = math.max(1, nextGrade.xp - grade.xp)
		fraction = (ply:GetXP() - grade.xp) / span
		label = nextGrade.staffOnly and "Prochain grade : décision du staff"
			or (Util.FormatNumber(ply:GetXP()) .. " / " .. Util.FormatNumber(nextGrade.xp) .. " XP")
	end
	UI.DrawBar(x + 16, y + 130, w - 28, 8, fraction, Colors.xp)
	draw.SimpleText(label, "Shinkai.Tiny", x + w - 12, y + 112, Colors.muted, TEXT_ALIGN_RIGHT)

	draw.SimpleText(Util.FormatNumber(ply:GetMoney()) .. " " .. Shinkai.Config.Currency, "Shinkai.Tiny",
		x + 16, y + 112, Colors.xp)

	if ply:IsGuarding() then
		draw.SimpleText("GARDE", "Shinkai.Medium", x + w + 14, y + h - 26, Colors.stamina)
	end
end

---------------------------------------------------------------------------
-- Effets actifs (au-dessus du bloc du personnage)
---------------------------------------------------------------------------
local function drawEffects(scrH)
	local x, y = MARGIN, scrH - PANEL_H - MARGIN - 28

	for id in pairs(Effects.Active) do
		local remaining = Effects.Remaining(id)
		local def = Effects.GetDefinition(id)

		if def and remaining > 0 then
			local text = string.format("%s  %.1f s", def.name, remaining)
			surface.SetFont("Shinkai.Small")
			local w = surface.GetTextSize(text) + 20

			draw.RoundedBox(4, x, y, w, 24, Colors.panel)
			surface.SetDrawColor(def.color)
			surface.DrawRect(x, y, 3, 24)
			draw.SimpleText(text, "Shinkai.Small", x + 12, y + 12, def.negative and Colors.accent or Colors.text,
				TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			y = y - 28
		end
	end
end

---------------------------------------------------------------------------
-- Barre de techniques (bas centre)
---------------------------------------------------------------------------
local SLOT, GAP = 68, 8

local function drawTechniques(ply, scrW, scrH)
	local style = ply:GetStyle()
	if not style or #style.techniques == 0 then return end

	local count = #style.techniques
	local x = (scrW - (count * SLOT + (count - 1) * GAP)) / 2
	local y = scrH - SLOT - 44
	local armed = ply:HoldsShinkaiWeapon()

	for index, tech in ipairs(style.techniques) do
		local unlocked = Styles.IsUnlocked(ply, tech)
		local remaining, duration = Techniques.GetCooldown(index)
		local affordable = ply:GetStamina() >= Styles.GetCost(style, tech)
		local usable = unlocked and armed and remaining <= 0 and affordable

		draw.RoundedBox(6, x, y, SLOT, SLOT, Colors.panel)
		surface.SetDrawColor(usable and style.color or Colors.border)
		surface.DrawOutlinedRect(x, y, SLOT, SLOT, 2)

		draw.SimpleText(index, "Shinkai.Tiny", x + 6, y + 4, Colors.muted)
		draw.SimpleText(Styles.GetTierLabel(tech), "Shinkai.Medium", x + SLOT / 2, y + SLOT / 2 - 6,
			unlocked and (affordable and Colors.text or Colors.accent) or Colors.border,
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if not unlocked then
			local required = Shinkai.Grades.Get(ply:GetFaction(), Styles.GetUnlockGrade(tech))
			draw.SimpleText(required and required.name or "Verrouillé", "Shinkai.Tiny", x + SLOT / 2, y + SLOT - 16,
				Colors.muted, TEXT_ALIGN_CENTER)
		else
			draw.SimpleText(Styles.GetCost(style, tech) .. " END", "Shinkai.Tiny", x + SLOT / 2, y + SLOT - 16,
				affordable and Colors.stamina or Colors.accent, TEXT_ALIGN_CENTER)
		end

		-- Voile de recharge qui se vide de haut en bas.
		if remaining > 0 then
			local cover = math.ceil(SLOT * math.Clamp(remaining / duration, 0, 1))
			surface.SetDrawColor(0, 0, 0, 190)
			surface.DrawRect(x, y + SLOT - cover, SLOT, cover)
			draw.SimpleText(string.format(remaining >= 10 and "%d" or "%.1f", remaining), "Shinkai.Large",
				x + SLOT / 2, y + SLOT / 2, Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		draw.SimpleText(tech.name, "Shinkai.Tiny", x + SLOT / 2, y + SLOT + 4, Colors.muted, TEXT_ALIGN_CENTER)
		x = x + SLOT + GAP
	end
end

-- Nom de la technique lancée, affiché brièvement au centre de l'écran.
local function drawLastCast(scrW, scrH)
	local cast = Techniques.LastCast
	local age = CurTime() - cast.time
	if age > 1.5 or cast.name == "" then return end

	local color = ColorAlpha(cast.color or Colors.text, 255 * (1 - age / 1.5))
	draw.SimpleText(cast.name, "Shinkai.Title", scrW / 2, scrH * 0.68, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "Shinkai.HUD", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:HasCharacter() then return end

	local scrW, scrH = ScrW(), ScrH()

	if not ply:Alive() then
		draw.SimpleText("Vous avez succombé à vos blessures", "Shinkai.Title", scrW / 2, scrH / 2 - 20,
			Colors.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Clic gauche ou saut pour réapparaître une fois le délai écoulé", "Shinkai.Medium",
			scrW / 2, scrH / 2 + 18, Colors.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		return
	end

	drawCharacter(ply, scrH)
	drawEffects(scrH)
	drawTechniques(ply, scrW, scrH)
	drawLastCast(scrW, scrH)
end)

---------------------------------------------------------------------------
-- Nom des personnages regardés (jamais celui d'un joueur invisible)
---------------------------------------------------------------------------
local GM = GM or GAMEMODE

function GM:HUDDrawTargetID()
	local tr = LocalPlayer():GetEyeTrace()
	local target = tr.Entity
	if not (IsValid(target) and target:IsPlayer()) then return end
	if not target:HasCharacter() or target:IsInvisible() then return end
	if tr.HitPos:DistToSqr(EyePos()) > 500 * 500 then return end

	draw.SimpleTextOutlined(target:GetRPName(), "Shinkai.Medium", ScrW() / 2, ScrH() / 2 + 34,
		Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
end
