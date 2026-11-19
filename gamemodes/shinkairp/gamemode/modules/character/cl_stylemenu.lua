-- Menu de choix du Souffle, proposé quand le personnage atteint le grade requis.

local UI = Shinkai.UI
local Colors = UI.Colors

local frame

local function open()
	if IsValid(frame) then frame:Remove() end

	local ply = LocalPlayer()
	local styles = Shinkai.Styles.GetForFaction(ply:GetFaction())
	if #styles == 0 then return end

	frame = vgui.Create("DFrame")
	frame:SetSize(620, math.min(ScrH() - 120, 640))
	frame:Center()
	frame:MakePopup()
	UI.StyleFrame(frame, "Choisissez votre Souffle — ce choix est définitif")

	local scroll = vgui.Create("DScrollPanel", frame)
	scroll:Dock(FILL)
	scroll:DockMargin(4, 8, 4, 4)

	for _, style in ipairs(styles) do
		local bonus = table.concat(Shinkai.Styles.DescribeModifiers(style), " • ")
		local special = style.techniques[3]

		local row = vgui.Create("DButton", scroll)
		row:Dock(TOP)
		row:DockMargin(0, 0, 0, 6)
		row:SetTall(84)
		row:SetText("")
		row.Paint = function(self, w, h)
			draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Colors.panelLight or Colors.panel)
			surface.SetDrawColor(style.color)
			surface.DrawRect(0, 6, 4, h - 12)
			draw.SimpleText(style.name, "Shinkai.Large", 16, 6, style.color)
			draw.SimpleText(style.description or "", "Shinkai.Tiny", 16, 34, Colors.text)
			draw.SimpleText(bonus, "Shinkai.Tiny", 16, 50, Colors.xp)
			if special then
				draw.SimpleText("3e mouvement : " .. special.name, "Shinkai.Tiny", 16, 66, Colors.muted)
			end
		end
		row.DoClick = function()
			Derma_Query("Apprendre le " .. style.name .. " ?", "Choix du Souffle", "Confirmer", function()
				net.Start("Shinkai.StyleChoose")
				net.WriteString(style.id)
				net.SendToServer()
				if IsValid(frame) then frame:Remove() end
			end, "Annuler")
		end
	end
end

net.Receive("Shinkai.StyleMenu", open)
