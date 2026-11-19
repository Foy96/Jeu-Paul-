-- Menu staff (F4 ou commande shinkai_admin).
-- Chaque bouton exécute simplement une commande de sv_admin.lua : les
-- permissions sont toujours vérifiées par le serveur.

local UI = Shinkai.UI
local Colors = UI.Colors
local Admin = Shinkai.Admin

local frame

local function open()
	if IsValid(frame) then
		frame:Remove()
		return
	end
	if not Admin.HasPermission(LocalPlayer(), "menu") then return end

	local selected

	frame = vgui.Create("DFrame")
	frame:SetSize(940, 560)
	frame:Center()
	frame:MakePopup()
	UI.StyleFrame(frame, "Staff Shinkai RP — " .. (Admin.GetPole(LocalPlayer()) or "Staff"))

	-- Exécute une commande sur le joueur sélectionné.
	local function run(command, ...)
		if not IsValid(selected) then
			return Shinkai.Notify(nil, "Sélectionnez d'abord un joueur.", Shinkai.NOTIFY_ERROR)
		end
		RunConsoleCommand("shinkai", command, "#" .. selected:UserID(), ...)
	end

	---------------------------------------------------------------------
	-- Actions (à droite)
	---------------------------------------------------------------------
	local side = vgui.Create("DScrollPanel", frame)
	side:Dock(RIGHT)
	side:SetWide(290)
	side:DockMargin(8, 8, 4, 4)

	local function section(text)
		local title = vgui.Create("DLabel", side)
		title:Dock(TOP)
		title:DockMargin(0, 8, 0, 4)
		title:SetFont("Shinkai.Small")
		title:SetTextColor(Colors.xp)
		title:SetText(text)
	end

	local function button(text, permission, onClick, color)
		local panel = vgui.Create("DButton", side)
		panel:Dock(TOP)
		panel:DockMargin(0, 0, 0, 4)
		panel:SetTall(28)
		panel:SetText(text)
		panel:SetEnabled(Admin.HasPermission(LocalPlayer(), permission))
		UI.StyleButton(panel, color)
		panel.DoClick = onClick
		return panel
	end

	local function combo()
		local panel = vgui.Create("DComboBox", side)
		panel:Dock(TOP)
		panel:DockMargin(0, 0, 0, 4)
		panel:SetTall(26)
		panel:SetFont("Shinkai.Small")
		return panel
	end

	section("Grade")
	local gradeBox = combo()
	button("Définir le grade", "setgrade", function()
		local _, index = gradeBox:GetSelected()
		if index then run("setgrade", tostring(index)) end
	end)
	button("Promouvoir", "promote", function() run("promote") end, Colors.success)
	button("Rétrograder", "demote", function() run("demote") end, Colors.accent)

	section("Souffle")
	local styleBox = combo()
	button("Attribuer le Souffle", "setstyle", function()
		local _, id = styleBox:GetSelected()
		if id then run("setstyle", id) end
	end)

	section("Expérience")
	local xpEntry = vgui.Create("DTextEntry", side)
	xpEntry:Dock(TOP)
	xpEntry:DockMargin(0, 0, 0, 4)
	xpEntry:SetTall(26)
	xpEntry:SetNumeric(true)
	xpEntry:SetPlaceholderText("Montant d'XP")
	button("Donner l'XP", "addxp", function()
		local amount = tonumber(xpEntry:GetValue())
		if amount then run("addxp", tostring(amount)) end
	end)

	section("Soutien")
	button("Soigner (PV + endurance)", "heal", function() run("heal") end)
	button("Réinitialiser les recharges", "resetcd", function() run("resetcd") end)
	button("Fiche du personnage (chat)", "charinfo", function() run("charinfo") end)

	---------------------------------------------------------------------
	-- Liste des joueurs (à gauche)
	---------------------------------------------------------------------
	local refresh

	-- Créé avant la liste : un panneau en Dock(FILL) doit être ajouté en dernier.
	local refreshButton = vgui.Create("DButton", frame)
	refreshButton:Dock(BOTTOM)
	refreshButton:DockMargin(4, 4, 0, 4)
	refreshButton:SetTall(26)
	refreshButton:SetText("Actualiser la liste")
	UI.StyleButton(refreshButton)
	refreshButton.DoClick = function() refresh() end

	local list = vgui.Create("DListView", frame)
	list:Dock(FILL)
	list:DockMargin(4, 8, 0, 4)
	list:SetMultiSelect(false)
	list:AddColumn("Personnage")
	list:AddColumn("Joueur")
	list:AddColumn("Faction")
	list:AddColumn("Grade")
	list:AddColumn("Souffle")

	function refresh()
		list:Clear()
		for _, ply in ipairs(player.GetAll()) do
			local faction = ply:GetFactionData()
			local grade = ply:GetGradeData()
			local style = Shinkai.Styles.Get(ply:GetStyleId())

			local line = list:AddLine(
				ply:HasCharacter() and ply:GetRPName() or "(aucun)",
				ply:Nick(),
				faction and faction.name or "-",
				grade and grade.name or "-",
				style and style.name or "-"
			)
			line.Player = ply
		end
	end

	-- Adapte les listes de grades et de Souffles à la faction du joueur choisi.
	list.OnRowSelected = function(_, _, line)
		selected = line.Player
		gradeBox:Clear()
		styleBox:Clear()
		if not IsValid(selected) or not selected:HasCharacter() then return end

		for index, grade in ipairs(Shinkai.Grades.GetAll(selected:GetFaction())) do
			gradeBox:AddChoice(index .. ". " .. grade.name, index, index == selected:GetGradeIndex())
		end
		for _, style in ipairs(Shinkai.Styles.GetForFaction(selected:GetFaction())) do
			styleBox:AddChoice(style.name, style.id, style.id == selected:GetStyleId())
		end
		styleBox:AddChoice("Aucun", "aucun")
	end

	refresh()
end

concommand.Add("shinkai_admin", open)
