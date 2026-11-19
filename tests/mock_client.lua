-- Compléments client de la simulation : dessin, panneaux, chat.
local fonts = {}
local function isColor(c) return type(c) == "table" and c.r ~= nil and c.g ~= nil and c.b ~= nil end
_drawn = 0; _chat = 0; _notes = 0

surface.CreateFont = function(name, data) assert(type(data) == "table" and data.size); fonts[name] = true end
surface.SetFont = function(name) assert(fonts[name], "police inconnue : " .. tostring(name)) end
surface.GetTextSize = function(text) assert(type(text) == "string"); return #text * 7, 14 end
surface.SetDrawColor = function(r, g, b) assert(isColor(r) or (type(r) == "number" and type(g) == "number" and type(b) == "number"), "SetDrawColor invalide") end
surface.DrawRect = function(x, y, w, h) assert(x and y and w and h) end
surface.DrawOutlinedRect = function(x, y, w, h) assert(x and y and w and h) end

draw = {}
local function text(t, font, x, y, color)
	assert(t ~= nil, "texte nil"); assert(fonts[font], "police inconnue : " .. tostring(font))
	assert(type(x) == "number" and type(y) == "number", "position invalide pour : " .. tostring(t))
	assert(color == nil or isColor(color), "couleur invalide pour : " .. tostring(t))
	_drawn = _drawn + 1
end
draw.SimpleText = text
draw.SimpleTextOutlined = function(t, font, x, y, color, ax, ay, ow, oc) text(t, font, x, y, color); assert(isColor(oc)) end
draw.RoundedBox = function(r, x, y, w, h, color) assert(x and y and w and h and isColor(color), "RoundedBox invalide") end
draw.RoundedBoxEx = function(r, x, y, w, h, color) assert(isColor(color)) end

function ScrW() return 1920 end
function ScrH() return 1080 end
function EyePos() return _local:EyePos() end
function LocalPlayer() return _local end
chat = { AddText = function(...) local n = select("#", ...); assert(n > 0); for i = 1, n do assert(select(i, ...) ~= nil, "chat.AddText argument nil") end; _chat = (_chat or 0) + 1 end }
notification = { AddLegacy = function(t, kind, len) assert(type(t) == "string" and kind and len); _notes = (_notes or 0) + 1 end }
function Derma_Query(textArg, title, b1, f1) assert(type(textArg) == "string"); if f1 then f1() end end
function ParticleEmitter(pos) assert(pos); return { Add = function(_, mat, p) assert(type(mat) == "string" and p); return setmetatable({}, { __index = function() return function() end end }) end, Finish = function() end } end
function DynamicLight() return {} end

-- Panneaux : toute méthode inconnue est acceptée ; les fonctions affectées
-- (Paint, DoClick...) sont conservées pour être exécutées par le test.
_panels = {}
local PANEL = {}
function PANEL:IsValid() return not rawget(self, "removed") end
function PANEL:Remove() self.removed = true end
function PANEL:GetWide() return 400 end
function PANEL:GetTall() return 300 end
function PANEL:SetNumeric(b) self.numeric = b end
function PANEL:GetValue() return rawget(self, "numeric") and "250" or "Akira Test" end
function PANEL:IsHovered() return rawget(self, "hovered") == true end
function PANEL:IsEnabled() return true end
function PANEL:SetText(t) assert(t ~= nil, "SetText(nil)") end
function PANEL:SetFont(f) assert(fonts[f], "police inconnue : " .. tostring(f)) end
function PANEL:SetModel(m) assert(type(m) == "string") end
function PANEL:GetSelected() local c = rawget(self, "choices"); if c and c[1] then return c[1][1], c[1][2] end end
function PANEL:Clear() self.choices = {}; self.lines = {} end
function PANEL:AddChoice(value, data, sel)
	assert(value ~= nil, "AddChoice(nil)")
	self.choices = rawget(self, "choices") or {}; table.insert(self.choices, { value, data })
	if sel and rawget(self, "OnSelect") then self.OnSelect(self, #self.choices, value, data) end
end
function PANEL:AddLine(...)
	for i = 1, select("#", ...) do assert(select(i, ...) ~= nil, "AddLine argument nil") end
	local line = {}; self.lines = rawget(self, "lines") or {}; table.insert(self.lines, line); return line
end
vgui = { Create = function(class, parent)
	assert(type(class) == "string")
	local p = setmetatable({ class = class }, { __index = function(_, k) local v = PANEL[k]; if v ~= nil then return v end; if type(k) == "string" and k:match("^[A-Z]") then return function() end end end })
	_panels[#_panels + 1] = p
	return p
end }
-- Exécute tout ce que les panneaux créés savent faire.
function _exercise()
	local list = _panels; _panels = {}
	local entity = { SetAngles = function() end }
	for _, p in ipairs(list) do
		for _, hovered in ipairs({ false, true }) do
			p.hovered = hovered
			local paint = rawget(p, "Paint"); if type(paint) == "function" then paint(p, 400, 84) end
		end
		local layout = rawget(p, "PerformLayout"); if type(layout) == "function" then layout(p, 400, 84) end
		local ent = rawget(p, "LayoutEntity"); if type(ent) == "function" then ent(p, entity) end
		for _, line in ipairs(rawget(p, "lines") or {}) do local sel = rawget(p, "OnRowSelected"); if sel then sel(p, 1, line) end end
	end
	for _, p in ipairs(list) do
		local click = rawget(p, "DoClick"); if type(click) == "function" then click(p) end
	end
	local created = _panels; _panels = {}
	return #list, #created
end
