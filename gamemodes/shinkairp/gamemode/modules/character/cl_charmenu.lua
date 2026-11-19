-- Menu des personnages : sélection, création, suppression.
-- S'ouvre à la connexion, puis avec F2.

local UI = Shinkai.UI
local Colors = UI.Colors
local C = Shinkai.Config

local menu

-- Signale au serveur que le client est prêt à recevoir ses personnages.
hook.Add("InitPostEntity", "Shinkai.Ready", function()
	net.Start("Shinkai.Ready")
	net.SendToServer()
end)

local function sendId(message, id)
	net.Start(message)
	net.WriteUInt(id, 32)
	net.SendToServer()
end

local function label(parent, text, font, color)
	local panel = vgui.Create("DLabel", parent)
	panel:SetText(text)
	panel:SetFont(font or "Shinkai.Small")
	panel:SetTextColor(color or Colors.text)
	panel:SizeToContents()
	return panel
end

---------------------------------------------------------------------------
-- Liste des personnages existants
---------------------------------------------------------------------------
local function buildList(parent, payload)
	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:Dock(FILL)

	if #payload.characters == 0 then
		local empty = label(scroll, "Aucun personnage. Créez-en un pour commencer.", "Shinkai.Medium", Colors.muted)
		empty:Dock(TOP)
		empty:DockMargin(8, 8, 8, 8)
	end

	for _, char in ipairs(payload.characters) do
		local faction = C.Factions[char.faction] or { name = "?", color = Colors.text }
		local grade = Shinkai.Grades.Get(char.faction, char.grade)
		local style = Shinkai.Styles.Get(char.style)
		local active = char.id == payload.active

		local card = vgui.Create("DPanel", scroll)
		card:Dock(TOP)
		card:DockMargin(0, 0, 0, 8)
		card:SetTall(76)
		card.Paint = function(_, w, h)
			draw.RoundedBox(6, 0, 0, w, h, active and Colors.panelLight or Colors.panel)
			surface.SetDrawColor(faction.color)
			surface.DrawRect(0, 6, 4, h - 12)
			draw.SimpleText(char.name, "Shinkai.Large", 16, 10, Colors.text)
			draw.SimpleText(faction.name .. " — " .. Shinkai.Grades.DisplayName(grade), "Shinkai.Small", 16, 38, faction.color)
			draw.SimpleText(style and style.name or "", "Shinkai.Tiny", 16, 56, style and style.color or Colors.muted)
		end

		local play = vgui.Create("DButton", card)
		play:SetText(active and "En jeu" or "Jouer")
		play:SetEnabled(not active)
		play:SetSize(90, 30)
		UI.StyleButton(play, Colors.success)
		play.DoClick = function()
			sendId("Shinkai.CharSelect", char.id)
			menu:Remove()
		end

		local delete = vgui.Create("DButton", card)
		delete:SetText("Supprimer")
		delete:SetSize(90, 30)
		delete:SetVisible(C.AllowCharDelete and not active)
		UI.StyleButton(delete, Colors.accent)
		delete.DoClick = function()
			Derma_Query("Supprimer définitivement " .. char.name .. " ?", "Suppression", "Supprimer", function()
				sendId("Shinkai.CharDelete", char.id)
			end, "Annuler")
		end

		card.PerformLayout = function(_, w)
			play:SetPos(w - 100, 8)
			delete:SetPos(w - 100, 40)
		end
	end
end

---------------------------------------------------------------------------
-- Formulaire de création
---------------------------------------------------------------------------
local function buildCreation(parent, payload)
	if #payload.characters >= C.MaxCharacters then
		local full = label(parent, "Nombre maximal de personnages atteint.", "Shinkai.Medium", Colors.muted)
		full:Dock(TOP)
		return
	end

	local selectedFaction, selectedModel = nil, 1

	local title = label(parent, "Nouveau personnage", "Shinkai.Large")
	title:Dock(TOP)
	title:DockMargin(0, 0, 0, 12)

	local nameTitle = label(parent, "Nom et prénom", "Shinkai.Small", Colors.muted)
	nameTitle:Dock(TOP)

	local nameEntry = vgui.Create("DTextEntry", parent)
	nameEntry:Dock(TOP)
	nameEntry:DockMargin(0, 4, 0, 12)
	nameEntry:SetTall(30)
	nameEntry:SetFont("Shinkai.Small")
	nameEntry:SetPlaceholderText("Ex. : Haruto Minase")

	local factionTitle = label(parent, "Faction", "Shinkai.Small", Colors.muted)
	factionTitle:Dock(TOP)

	local factionBox = vgui.Create("DComboBox", parent)
	factionBox:Dock(TOP)
	factionBox:DockMargin(0, 4, 0, 12)
	factionBox:SetTall(30)
	factionBox:SetFont("Shinkai.Small")

	local modelTitle = label(parent, "Apparence", "Shinkai.Small", Colors.muted)
	modelTitle:Dock(TOP)

	local modelBox = vgui.Create("DComboBox", parent)
	modelBox:Dock(TOP)
	modelBox:DockMargin(0, 4, 0, 12)
	modelBox:SetTall(30)
	modelBox:SetFont("Shinkai.Small")

	local create = vgui.Create("DButton", parent)
	create:Dock(BOTTOM)
	create:SetTall(40)
	create:SetText("Créer le personnage")
	UI.StyleButton(create, Colors.accent)

	local preview = vgui.Create("DModelPanel", parent)
	preview:Dock(FILL)
	preview:SetFOV(38)
	preview.LayoutEntity = function(_, entity)
		entity:SetAngles(Angle(0, 35 + math.sin(CurTime() * 0.6) * 20, 0))
	end

	local function setModel(index)
		selectedModel = index
		local faction = C.Factions[selectedFaction]
		if faction and faction.models[index] then
			preview:SetModel(faction.models[index])
		end
	end

	local function setFaction(id)
		selectedFaction = id
		modelBox:Clear()
		for index in ipairs(C.Factions[id].models) do
			modelBox:AddChoice("Apparence " .. index, index, index == 1)
		end
		setModel(1)
	end

	factionBox.OnSelect = function(_, _, _, id) setFaction(id) end
	modelBox.OnSelect = function(_, _, _, index) setModel(index) end

	local first = true
	for _, id in ipairs(C.FactionOrder) do
		if payload.factions[id] then
			factionBox:AddChoice(C.Factions[id].name, id, first)
			first = false
		end
	end

	create.DoClick = function()
		if not selectedFaction then return end
		net.Start("Shinkai.CharCreate")
		net.WriteString(nameEntry:GetValue())
		net.WriteString(selectedFaction)
		net.WriteUInt(selectedModel, 8)
		net.SendToServer()
	end
end

---------------------------------------------------------------------------
-- Fenêtre
---------------------------------------------------------------------------
local function open(payload)
	if IsValid(menu) then menu:Remove() end

	menu = vgui.Create("EditablePanel")
	menu:SetSize(ScrW(), ScrH())
	menu:MakePopup()
	menu.Paint = function(_, w, h)
		surface.SetDrawColor(8, 8, 12, 250)
		surface.DrawRect(0, 0, w, h)
		draw.SimpleText("SHINKAI RP", "Shinkai.Title", w / 2, h * 0.08, Colors.accent, TEXT_ALIGN_CENTER)
		draw.SimpleText("Demon Slayer — Serious RP", "Shinkai.Medium", w / 2, h * 0.08 + 38, Colors.muted, TEXT_ALIGN_CENTER)
	end

	local body = vgui.Create("DPanel", menu)
	body:SetSize(math.min(980, ScrW() - 80), math.min(560, ScrH() - 220))
	body:Center()
	body.Paint = nil

	local right = vgui.Create("DPanel", body)
	right:Dock(RIGHT)
	right:SetWide(body:GetWide() * 0.42)
	right:DockPadding(16, 16, 16, 16)
	right.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, Colors.panel) end

	local left = vgui.Create("DPanel", body)
	left:Dock(FILL)
	left:DockMargin(0, 0, 16, 0)
	left.Paint = nil

	buildList(left, payload)
	buildCreation(right, payload)

	-- On ne peut fermer le menu que si un personnage est déjà en jeu.
	if payload.active ~= 0 then
		local close = vgui.Create("DButton", menu)
		close:SetText("Retour au jeu")
		close:SetSize(160, 36)
		close:SetPos(ScrW() / 2 - 80, ScrH() - 90)
		UI.StyleButton(close)
		close.DoClick = function() menu:Remove() end
	end
end

net.Receive("Shinkai.CharMenu", function()
	open(net.ReadTable())
end)
