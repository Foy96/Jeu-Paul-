-- Écrans de création de personnage illustrés :
--   1. choix de la faction sur l'image materials/shinkai/factions.png,
--      avec des zones cliquables en forme de polygone ;
--   2. saisie du prénom, du nom et de l'apparence sur l'image de la faction.
--
-- Si une image manque, l'écran s'affiche sur un fond uni : le menu reste utilisable.

Shinkai.CharCreation = Shinkai.CharCreation or {}
local Creation = Shinkai.CharCreation
local UI = Shinkai.UI
local Colors = UI.Colors
local C = Shinkai.Config

surface.CreateFont("Shinkai.Creation.Title", { font = "Georgia", size = 42, weight = 700, extended = true })
surface.CreateFont("Shinkai.Creation.Input", { font = "Georgia", size = 25, weight = 500, extended = true })
surface.CreateFont("Shinkai.Creation.Button", { font = "Georgia", size = 28, weight = 700, extended = true })

---------------------------------------------------------------------------
-- Zones cliquables de factions.png, en pixels de l'image d'origine.
-- Si l'image change, il suffit de reprendre ces coordonnées.
---------------------------------------------------------------------------
local IMAGE_W, IMAGE_H = 1672, 941

local ZONES = {
	-- Case rouge à gauche
	demon = {
		{ x = 55, y = 645 }, { x = 115, y = 610 }, { x = 230, y = 605 }, { x = 350, y = 625 },
		{ x = 510, y = 605 }, { x = 635, y = 615 }, { x = 690, y = 655 }, { x = 665, y = 715 },
		{ x = 685, y = 760 }, { x = 615, y = 795 }, { x = 455, y = 810 }, { x = 260, y = 815 },
		{ x = 105, y = 790 }, { x = 45, y = 735 },
	},
	-- Case bleue à droite
	slayer = {
		{ x = 1010, y = 655 }, { x = 1060, y = 615 }, { x = 1200, y = 605 }, { x = 1370, y = 615 },
		{ x = 1530, y = 615 }, { x = 1625, y = 665 }, { x = 1600, y = 715 }, { x = 1625, y = 760 },
		{ x = 1550, y = 795 }, { x = 1400, y = 810 }, { x = 1210, y = 805 }, { x = 1050, y = 790 },
		{ x = 990, y = 735 },
	},
	-- Bouton du bas
	confirm = {
		{ x = 580, y = 815 }, { x = 1090, y = 815 }, { x = 1145, y = 870 },
		{ x = 1090, y = 925 }, { x = 580, y = 925 }, { x = 525, y = 870 },
	},
}

local CONFIRM_COLOR = Color(230, 190, 80)

---------------------------------------------------------------------------
-- Outils
---------------------------------------------------------------------------
local materials = {}

-- Renvoie le Material d'une image de materials/, ou nil si elle est absente.
local function loadImage(path)
	if not path then return nil end
	if materials[path] == nil then
		local mat = Material(path, "smooth")
		materials[path] = (mat and not mat:IsError()) and mat or false
	end
	return materials[path] or nil
end

-- Place l'image en conservant ses proportions (bandes noires si besoin).
local function fitImage(w, h)
	local scale = math.min(w / IMAGE_W, h / IMAGE_H)
	local drawW, drawH = IMAGE_W * scale, IMAGE_H * scale
	return (w - drawW) / 2, (h - drawH) / 2, drawW, drawH, scale
end

local function scalePolygon(polygon, offsetX, offsetY, scale)
	local points = {}
	for i, p in ipairs(polygon) do
		points[i] = { x = offsetX + p.x * scale, y = offsetY + p.y * scale }
	end
	return points
end

local function pointInPolygon(px, py, polygon)
	local inside = false
	local j = #polygon
	for i = 1, #polygon do
		local a, b = polygon[i], polygon[j]
		if (a.y > py) ~= (b.y > py) and px < (b.x - a.x) * (py - a.y) / (b.y - a.y) + a.x then
			inside = not inside
		end
		j = i
	end
	return inside
end

-- surface.DrawPoly ne sait dessiner que des polygones convexes et dans le sens
-- horaire. Les zones de l'image ne sont pas convexes : on les découpe en
-- triangles autour de leur centre, chacun remis dans le bon sens.
local function triangulate(polygon)
	local cx, cy = 0, 0
	for _, p in ipairs(polygon) do cx, cy = cx + p.x, cy + p.y end
	cx, cy = cx / #polygon, cy / #polygon

	local triangles = {}
	for i, a in ipairs(polygon) do
		local b = polygon[i % #polygon + 1]
		local triangle = { { x = cx, y = cy }, { x = a.x, y = a.y }, { x = b.x, y = b.y } }
		if (a.x - cx) * (b.y - cy) - (a.y - cy) * (b.x - cx) < 0 then
			triangle[2], triangle[3] = triangle[3], triangle[2]
		end
		triangles[#triangles + 1] = triangle
	end
	return triangles
end

local function drawZone(polygon, color, fillAlpha)
	draw.NoTexture()
	surface.SetDrawColor(color.r, color.g, color.b, fillAlpha)
	for _, triangle in ipairs(triangulate(polygon)) do
		surface.DrawPoly(triangle)
	end

	surface.SetDrawColor(color.r, color.g, color.b, 230)
	for i, a in ipairs(polygon) do
		local b = polygon[i % #polygon + 1]
		surface.DrawLine(a.x, a.y, b.x, b.y)
		surface.DrawLine(a.x + 1, a.y + 1, b.x + 1, b.y + 1)
	end
end

local function drawBackground(path, w, h)
	surface.SetDrawColor(8, 8, 12, 255)
	surface.DrawRect(0, 0, w, h)

	local mat = loadImage(path)
	if not mat then return false end

	local x, y, drawW, drawH = fitImage(w, h)
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(mat)
	surface.DrawTexturedRect(x, y, drawW, drawH)
	return true
end

local current

local function close()
	if IsValid(current) then current:Remove() end
end

local function newScreen()
	close()
	current = vgui.Create("EditablePanel")
	current:SetSize(ScrW(), ScrH())
	current:MakePopup()
	return current
end

-- Bouton « Retour » vers la liste des personnages, s'il y en a déjà.
local function addBackButton(screen, text, onClick)
	local back = vgui.Create("DButton", screen)
	back:SetText(text)
	back:SetFont("Shinkai.Creation.Input")
	back:SetSize(160, 40)
	back:SetPos(24, 24)
	UI.StyleButton(back)
	back:SetFont("Shinkai.Creation.Input")
	back.DoClick = onClick
end

---------------------------------------------------------------------------
-- Écran 1 : choix de la faction
---------------------------------------------------------------------------
function Creation.OpenFactions(payload)
	local screen = newScreen()
	local selected

	-- Faction proposée par défaut : la seule accessible, s'il n'y en a qu'une.
	local available = {}
	for _, id in ipairs(C.FactionOrder) do
		if payload.factions[id] then available[#available + 1] = id end
	end
	if #available == 1 then selected = available[1] end

	local function zoneAt(mx, my)
		local x, y, _, _, scale = fitImage(screen:GetWide(), screen:GetTall())
		for id, polygon in pairs(ZONES) do
			if pointInPolygon(mx, my, scalePolygon(polygon, x, y, scale)) then return id end
		end
	end

	local function zoneColor(id)
		if id == "confirm" then return CONFIRM_COLOR end
		return C.Factions[id] and C.Factions[id].color or color_white
	end

	screen.Paint = function(self, w, h)
		local hasImage = drawBackground(C.FactionScreenImage, w, h)
		local x, y, _, _, scale = fitImage(w, h)
		local hovered = zoneAt(self:CursorPos())

		for id, polygon in pairs(ZONES) do
			local points = scalePolygon(polygon, x, y, scale)
			local locked = id ~= "confirm" and not payload.factions[id]
			local disabled = id == "confirm" and not selected

			if locked then
				drawZone(points, Color(0, 0, 0), 200)
			elseif id == selected then
				drawZone(points, zoneColor(id), 70)
			elseif id == hovered and not disabled then
				drawZone(points, zoneColor(id), 35)
			elseif not hasImage then
				drawZone(points, zoneColor(id), 15) -- sans image, on montre les zones
			end

			-- Sans image, les zones n'ont pas de texte : on l'écrit par-dessus.
			if not hasImage or locked then
				local cx, cy = 0, 0
				for _, p in ipairs(points) do cx, cy = cx + p.x, cy + p.y end
				local label = id == "confirm" and "Confirmer" or C.Factions[id].plural
				if locked then label = label .. " (whitelist)" end
				draw.SimpleText(label, "Shinkai.Creation.Button", cx / #points, cy / #points,
					disabled and Colors.muted or Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end

		if not hasImage then
			draw.SimpleText("Choisissez votre camp", "Shinkai.Creation.Title", w / 2, h * 0.25,
				Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	screen.OnMousePressed = function(self, code)
		if code ~= MOUSE_LEFT then return end

		local id = zoneAt(self:CursorPos())
		if not id then return end

		if id == "confirm" then
			if not selected then return end
			surface.PlaySound("buttons/button14.wav")
			Creation.OpenForm(payload, selected)
		elseif payload.factions[id] then
			selected = id
			surface.PlaySound("buttons/lightswitch2.wav")
		else
			Shinkai.Notify(nil, "Cette faction est réservée aux joueurs whitelistés.", Shinkai.NOTIFY_ERROR)
		end
	end

	if #payload.characters > 0 then
		addBackButton(screen, "Retour", function()
			close()
			Shinkai.CharMenu.Open(payload)
		end)
	end
end

---------------------------------------------------------------------------
-- Écran 2 : prénom, nom et apparence
---------------------------------------------------------------------------
function Creation.OpenForm(payload, factionId)
	local faction = C.Factions[factionId]
	local screen = newScreen()
	local modelIndex = 1

	screen.Paint = function(_, w, h)
		drawBackground(faction.creationImage, w, h)
	end

	local form = vgui.Create("DPanel", screen)
	form:SetSize(math.min(820, ScrW() - 48), math.min(520, ScrH() - 140))
	form:Center()
	form:DockPadding(24, 70, 24, 24)
	form.Paint = function(_, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(10, 10, 14, 225))
		surface.SetDrawColor(faction.color)
		surface.DrawRect(0, 0, w, 4)
		draw.SimpleText("Nouveau " .. faction.name, "Shinkai.Creation.Title", 24, 14, Colors.text)
	end

	local preview = vgui.Create("DModelPanel", form)
	preview:Dock(RIGHT)
	preview:SetWide(form:GetWide() * 0.38)
	preview:SetFOV(38)
	preview.LayoutEntity = function(_, entity)
		entity:SetAngles(Angle(0, 35 + math.sin(CurTime() * 0.6) * 20, 0))
	end

	local fields = vgui.Create("DPanel", form)
	fields:Dock(FILL)
	fields:DockMargin(0, 0, 24, 0)
	fields.Paint = nil

	local function caption(text)
		local panel = vgui.Create("DLabel", fields)
		panel:Dock(TOP)
		panel:SetFont("Shinkai.Creation.Input")
		panel:SetTextColor(Colors.muted)
		panel:SetText(text)
		panel:SetTall(30)
	end

	local function entry(placeholder)
		local panel = vgui.Create("DTextEntry", fields)
		panel:Dock(TOP)
		panel:DockMargin(0, 2, 0, 14)
		panel:SetTall(38)
		panel:SetFont("Shinkai.Creation.Input")
		panel:SetPlaceholderText(placeholder)
		return panel
	end

	caption("Prénom")
	local firstName = entry("Ex. : Haruto")
	caption("Nom")
	local lastName = entry("Ex. : Minase")

	caption("Apparence")
	local models = vgui.Create("DComboBox", fields)
	models:Dock(TOP)
	models:DockMargin(0, 2, 0, 14)
	models:SetTall(38)
	models:SetFont("Shinkai.Creation.Input")
	models.OnSelect = function(_, _, _, index)
		modelIndex = index
		preview:SetModel(faction.models[index])
	end
	for index in ipairs(faction.models) do
		models:AddChoice("Apparence " .. index, index, index == 1)
	end

	local create = vgui.Create("DButton", fields)
	create:Dock(BOTTOM)
	create:SetTall(52)
	create:SetText("Créer le personnage")
	UI.StyleButton(create, faction.color)
	create:SetFont("Shinkai.Creation.Button")
	create.DoClick = function()
		local first, last = string.Trim(firstName:GetValue()), string.Trim(lastName:GetValue())
		if first == "" or last == "" then
			return Shinkai.Notify(nil, "Indiquez un prénom et un nom.", Shinkai.NOTIFY_ERROR)
		end

		-- Le serveur vérifie le nom complet (longueur, caractères, doublons).
		net.Start("Shinkai.CharCreate")
		net.WriteString(first .. " " .. last)
		net.WriteString(factionId)
		net.WriteUInt(modelIndex, 8)
		net.SendToServer()
	end

	addBackButton(screen, "Retour", function()
		Creation.OpenFactions(payload)
	end)
end

function Creation.Close()
	close()
end

-- Le serveur ferme les menus quand le premier personnage entre en jeu.
net.Receive("Shinkai.CharMenuClose", function()
	close()
	if Shinkai.CharMenu.Close then Shinkai.CharMenu.Close() end
end)
