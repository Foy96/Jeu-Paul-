-- Fiche des techniques du personnage (F1 ou commande shinkai_techniques).

local UI = Shinkai.UI
local Colors = UI.Colors
local Styles = Shinkai.Styles

local frame

local function open()
	if IsValid(frame) then
		frame:Remove()
		return
	end

	local ply = LocalPlayer()
	if not ply:HasCharacter() then return end

	local style = ply:GetStyle()
	local grade = ply:GetGradeData()

	frame = vgui.Create("DFrame")
	frame:SetSize(680, math.min(ScrH() - 120, 620))
	frame:Center()
	frame:MakePopup()
	UI.StyleFrame(frame, style and style.name or "Techniques")

	local scroll = vgui.Create("DScrollPanel", frame)
	scroll:Dock(FILL)
	scroll:DockMargin(4, 8, 4, 4)

	local header = vgui.Create("DPanel", scroll)
	header:Dock(TOP)
	header:DockMargin(0, 0, 0, 8)
	header:SetTall(style and 62 or 40)
	header.Paint = function(_, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Colors.panel)
		if not style then
			draw.SimpleText("Votre personnage ne maîtrise encore aucun Souffle.", "Shinkai.Small", 12, h / 2,
				Colors.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			return
		end
		draw.SimpleText(style.description or "", "Shinkai.Tiny", 12, 8, Colors.text)
		draw.SimpleText(table.concat(Styles.DescribeModifiers(style), " • "), "Shinkai.Tiny", 12, 24, Colors.xp)
		draw.SimpleText("Touches 1 à 9 avec l'arme en main — clic droit : garde", "Shinkai.Tiny", 12, 40, Colors.muted)
	end

	if not style then return end

	local combat = Shinkai.Config.Combat

	for index, tech in ipairs(style.techniques) do
		local unlocked = Styles.IsUnlocked(ply, tech)
		local required = Shinkai.Grades.Get(ply:GetFaction(), Styles.GetUnlockGrade(tech))

		local damage = Styles.GetBaseDamage(tech)
		if combat.DamageMode ~= "flat" and grade then
			damage = damage * grade.damage / combat.DamageReference
		end

		local stats = string.format("%s%d END  •  recharge %s s",
			damage > 0 and (math.Round(damage) .. " dégâts  •  ") or "",
			Styles.GetCost(style, tech),
			math.Round(Styles.GetCooldown(style, tech), 1))

		local row = vgui.Create("DPanel", scroll)
		row:Dock(TOP)
		row:DockMargin(0, 0, 0, 6)
		row:SetTall(64)
		row.Paint = function(_, w, h)
			draw.RoundedBox(6, 0, 0, w, h, Colors.panel)
			draw.SimpleText(index, "Shinkai.Large", 24, h / 2, unlocked and style.color or Colors.border,
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(tech.name .. "  —  " .. Styles.GetTierLabel(tech), "Shinkai.Medium", 52, 6,
				unlocked and Colors.text or Colors.muted)
			draw.SimpleText(tech.description or "", "Shinkai.Tiny", 52, 28, Colors.muted)
			draw.SimpleText(stats, "Shinkai.Tiny", 52, 44, Colors.stamina)
			if not unlocked then
				draw.SimpleText("Débloquée au grade " .. (required and required.name or "?"), "Shinkai.Tiny",
					w - 12, 8, Colors.accent, TEXT_ALIGN_RIGHT)
			end
		end
	end
end

concommand.Add("shinkai_techniques", open)
