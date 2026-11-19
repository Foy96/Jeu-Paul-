-- Simulation minimale de l'API Garry's Mod pour exécuter le gamemode hors du jeu.
SERVER = (REALM == "server"); CLIENT = not SERVER

local ALLOWED_NIL = { Shinkai = true, GM = true, GAMEMODE = true, SWEP = true, jit = true }
setmetatable(_G, { __index = function(_, k)
	if ALLOWED_NIL[k] then return nil end
	error("GLOBAL INEXISTANT : " .. tostring(k), 2)
end })

---------------------------------------------------------------- temps / timers
local now = 100
function CurTime() return now end
function FrameTime() return 0.016 end
function SysTime() return now end

timer = {}
local timers, anon = {}, 0
function timer.Create(name, delay, reps, fn) timers[name] = { delay = delay, reps = reps, fn = fn, nextRun = now + delay } end
function timer.Simple(delay, fn) anon = anon + 1; timer.Create("__anon" .. anon, delay, 1, fn) end
function timer.Remove(name) timers[name] = nil end
function timer.Exists(name) return timers[name] ~= nil end
function _advance(dt)
	local target = now + dt
	while now < target - 1e-9 do
		now = math.min(target, now + 0.05)
		local names = {}
		for name in pairs(timers) do names[#names + 1] = name end
		table.sort(names)
		for _, name in ipairs(names) do
			local t = timers[name]
			if t and now >= t.nextRun - 1e-9 then
				t.nextRun = t.nextRun + math.max(t.delay, 0.05)
				if t.reps > 0 then t.reps = t.reps - 1; if t.reps == 0 then timers[name] = nil end end
				t.fn()
			end
		end
	end
end

---------------------------------------------------------------- hooks
hook = {}
local hooks = {}
function hook.Add(name, id, fn) hooks[name] = hooks[name] or {}; hooks[name][id] = fn end
function hook.Remove(name, id) if hooks[name] then hooks[name][id] = nil end end
function hook.Call(name, gm, ...)
	for _, fn in pairs(hooks[name] or {}) do
		local a, b, c = fn(...)
		if a ~= nil then return a, b, c end
	end
	if gm and gm[name] then return gm[name](gm, ...) end
end
function hook.Run(name, ...) return hook.Call(name, GAMEMODE, ...) end
function _hooks(name) return hooks[name] or {} end

---------------------------------------------------------------- bibliothèques Lua étendues
function math.Clamp(v, a, b) return math.max(a, math.min(b, v)) end
function math.Round(v, d) local m = 10 ^ (d or 0); return math.floor(v * m + 0.5) / m end
function math.Rand(a, b) return a + (b - a) * math.random() end
function Lerp(t, a, b) return a + (b - a) * math.Clamp(t, 0, 1) end
function string.Trim(s, char) assert(char == nil or type(char) == "string", "string.Trim: second argument invalide"); return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
function string.Explode(sep, s) local out = {}; for part in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do out[#out + 1] = part end; return out end
function string.GetFileFromFilename(p) return p:match("[^/]+$") or p end
function table.Copy(t) local o = {}; for k, v in pairs(t) do o[k] = (type(v) == "table" and getmetatable(v) == nil) and table.Copy(v) or v end; return o end
function table.GetKeys(t) local o = {}; for k in pairs(t) do o[#o + 1] = k end; return o end
utf8 = { len = function(s) local _, n = s:gsub("[^\128-\191]", ""); return n end }
bit = bit or { band = function(a, b) return a == b and a or 0 end }

function IsValid(o) return o ~= nil and type(o) == "table" and o.IsValid ~= nil and o:IsValid() or false end
function MsgC() end
function ErrorNoHalt(msg) error("ErrorNoHalt: " .. tostring(msg), 2) end
function AddCSLuaFile() end
function DeriveGamemode() end
function PrintMessage() end
function RunConsoleCommand(...) _console[#_console + 1] = { ... } end
_console = {}

---------------------------------------------------------------- Vector / Angle / Color
local VEC = {}; VEC.__index = VEC
function Vector(x, y, z) return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, VEC) end
VEC.__add = function(a, b) return Vector(a.x + b.x, a.y + b.y, a.z + b.z) end
VEC.__sub = function(a, b) return Vector(a.x - b.x, a.y - b.y, a.z - b.z) end
VEC.__unm = function(a) return Vector(-a.x, -a.y, -a.z) end
VEC.__mul = function(a, b) if type(a) == "number" then a, b = b, a end; assert(type(b) == "number", "Vector * non-nombre"); return Vector(a.x * b, a.y * b, a.z * b) end
function VEC:Dot(o) return self.x * o.x + self.y * o.y + self.z * o.z end
function VEC:LengthSqr() return self:Dot(self) end
function VEC:Length() return math.sqrt(self:LengthSqr()) end
function VEC:Length2DSqr() return self.x ^ 2 + self.y ^ 2 end
function VEC:DistToSqr(o) return (self - o):LengthSqr() end
function VEC:GetNormalized() local l = self:Length(); if l == 0 then return Vector() end; return self * (1 / l) end
function VEC:Normalize() local n = self:GetNormalized(); self.x, self.y, self.z = n.x, n.y, n.z end
function VEC:Angle() return Angle(-math.deg(math.atan2(self.z, math.sqrt(self.x ^ 2 + self.y ^ 2))), math.deg(math.atan2(self.y, self.x)), 0) end
function VectorRand() return Vector(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(-1, 1)) end
vector_up = Vector(0, 0, 1); vector_origin = Vector(0, 0, 0)

local ANG = {}; ANG.__index = ANG
function Angle(p, y, r) return setmetatable({ p = p or 0, y = y or 0, r = r or 0 }, ANG) end
function ANG:Forward() local p, y = math.rad(self.p), math.rad(self.y); return Vector(math.cos(p) * math.cos(y), math.cos(p) * math.sin(y), -math.sin(p)) end
function ANG:Right() local y = math.rad(self.y); return Vector(math.sin(y), -math.cos(y), 0) end

local COL = {}; COL.__index = COL
function Color(r, g, b, a) assert(r and g and b, "Color incomplet"); return setmetatable({ r = r, g = g, b = b, a = a or 255 }, COL) end
function ColorAlpha(c, a) return Color(c.r, c.g, c.b, a) end
color_white = Color(255, 255, 255); color_black = Color(0, 0, 0)

---------------------------------------------------------------- constantes
IN_ATTACK, IN_JUMP, IN_ATTACK2 = 1, 2, 2048
MOVETYPE_WALK, MOVETYPE_NONE = 2, 0
MASK_SOLID_BRUSHONLY, MASK_PLAYERSOLID, MASK_SHOT_HULL = 1, 2, 3
DMG_SLASH, DMG_POISON = 4, 131072
PLAYER_ATTACK1, ACT_VM_MISSCENTER = 1, 2
HUD_PRINTTALK = 3
TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, TEXT_ALIGN_BOTTOM = 0, 1, 2, 3, 4
FILL, LEFT, RIGHT, TOP, BOTTOM = 1, 2, 3, 4, 5
NULL = setmetatable({}, { __index = function(_, k) if k == "IsValid" then return function() return false end end; error("accès à NULL." .. tostring(k), 2) end })

---------------------------------------------------------------- fichiers / include
file = {}
function file.Find(pattern, where) assert(where == "LUA"); return _pyfind(pattern) end
function file.CreateDir() end
function file.Append() end
local dirStack = { GAMEMODE_DIR .. "/gamemode/" }
function include(path)
	local full
	if path:sub(1, #"shinkairp/gamemode/") == "shinkairp/gamemode/" then
		full = GAMEMODE_DIR .. "/gamemode/" .. path:sub(#"shinkairp/gamemode/" + 1)
	else
		full = dirStack[#dirStack] .. path
	end
	local chunk, err = loadfile(full)
	if not chunk then error("include " .. path .. " : " .. tostring(err), 2) end
	_included[#_included + 1] = full
	dirStack[#dirStack + 1] = full:match("^(.*/)")
	chunk()
	dirStack[#dirStack] = nil
end
_included = {}

---------------------------------------------------------------- util / sql / divers
util = {}
function util.AddNetworkString(name) _netstrings[name] = true end
_netstrings = {}
function util.JSONToTable(s) return {} end
function util.TableToJSON(t) return "{}" end
function util.TraceLine(t) return { Hit = false, HitPos = t.endpos } end
function util.TraceHull(t)
	local dir = t.endpos - t.start
	local len = dir:Length()
	if len > 1 then
		dir = dir * (1 / len)
		for _, e in ipairs(ents.FindInSphere(t.start, len + 40)) do
			local skip = e == t.filter or e.owner ~= nil
			if type(t.filter) == "table" and getmetatable(t.filter) == nil then for _, f in ipairs(t.filter) do if f == e then skip = true end end end
			if not skip then
				local rel = e:WorldSpaceCenter() - t.start
				local along = rel:Dot(dir)
				if along >= 0 and along <= len + 16 and (rel - dir * along):Length() < 40 then
					return { Hit = true, Entity = e, HitPos = t.start + dir * along }
				end
			end
		end
	end
	return { Hit = false, HitPos = t.endpos }
end
sql = {}
function sql.SQLStr(s) return "'" .. tostring(s):gsub("'", "''") .. "'" end
function sql.Query(q) local r = _pysql(q); if r == false then return false end; return r end
function sql.LastError() return _pysqlerr() end
sound = { Play = function() end }
game = { GetWorld = function() return _world end }
concommand = { Add = function(name, fn) _concommands[name] = fn end }
_concommands = {}
surface = { PlaySound = function() end }

---------------------------------------------------------------- réseau
net = {}
local receivers, buffer, current = {}, {}, nil
_sent = {}
function net.Receive(name, fn) receivers[name] = fn end
function net.Start(name) if SERVER then assert(_netstrings[name], "message réseau non déclaré : " .. name) end; current = { name = name, data = {} } end
local function writer(kind) return function(v, ...) assert(v ~= nil, "net.Write" .. kind .. "(nil)"); current.data[#current.data + 1] = v end end
for _, kind in ipairs({ "String", "UInt", "Float", "Vector", "Normal", "Color", "Entity", "Table", "Bool" }) do
	net["Write" .. kind] = writer(kind)
	net["Read" .. kind] = function() assert(#buffer > 0, "net.Read" .. kind .. " : tampon vide"); return table.remove(buffer, 1) end
end
local function flush(target) current.target = target; _sent[#_sent + 1] = current; current = nil end
function net.Send(t) assert(t ~= nil, "net.Send(nil)"); flush(t) end
function net.Broadcast() flush("all") end
function net.SendPVS() flush("pvs") end
function net.SendToServer() flush("server") end
-- Simule la réception d'un message : _receive("Nom", joueur, valeurs...)
function _receive(name, ply, ...)
	assert(receivers[name], "aucun récepteur pour " .. name)
	buffer = { ... }
	receivers[name](0, ply)
	buffer = {}
end
function _lastSent(name) for i = #_sent, 1, -1 do if _sent[i].name == name then return _sent[i] end end end
function _countSent(name) local n = 0; for _, m in ipairs(_sent) do if m.name == name then n = n + 1 end end; return n end

---------------------------------------------------------------- entités
local ENT = {}; ENT.__index = ENT
local entities, nextIndex = {}, 0
function ENT:IsValid() return not self.removed end
function ENT:IsPlayer() return false end
function ENT:IsNPC() return self.npc == true end
function ENT:IsNextBot() return false end
function ENT:EntIndex() return self.index end
function ENT:GetPos() return self.pos end
function ENT:SetPos(p) self.pos = Vector(p.x, p.y, p.z) end
function ENT:WorldSpaceCenter() return self.pos + Vector(0, 0, 36) end
function ENT:GetAngles() return self.ang end
function ENT:SetNoDraw(b) self.nodraw = b end
function ENT:DrawShadow() end
function ENT:EmitSound() end
function ENT:Health() return self.health end
function ENT:SetHealth(h) assert(type(h) == "number"); self.health = h end
function ENT:GetMaxHealth() return self.maxHealth end
function ENT:SetMaxHealth(h) self.maxHealth = h end
function ENT:SetVelocity(v) self.vel = self.vel + v end
function ENT:GetVelocity() return self.vel end
function ENT:Alive() return self.health > 0 end
function ENT:TakeDamageInfo(info)
	if hook.Run("EntityTakeDamage", self, info) == true then return end
	if self:IsPlayer() then
		if hook.Run("PlayerShouldTakeDamage", self, info:GetAttacker()) == false or self.god then return end
	end
	self.health = self.health - info:GetDamage()
	self.lastDamage = info:GetDamage()
	if self.health <= 0 and self:IsPlayer() and self.alive then
		self.alive = false
		hook.Run("PlayerDeath", self, info:GetInflictor(), info:GetAttacker())
	end
end
local function newEntity(meta)
	nextIndex = nextIndex + 1
	local e = setmetatable({ index = nextIndex, pos = Vector(), ang = Angle(), vel = Vector(), health = 100, maxHealth = 100, nw = {} }, meta)
	entities[#entities + 1] = e
	return e
end
function _newNPC() local e = newEntity(ENT); e.npc = true; return e end
_world = setmetatable({ IsValid = function() return false end, IsPlayer = function() return false end }, {})
ents = {}
function ents.FindInSphere(pos, radius)
	local out = {}
	for _, e in ipairs(entities) do
		if not e.removed and e.pos:DistToSqr(pos) <= radius ^ 2 then out[#out + 1] = e end
	end
	return out
end

local PLAYER = setmetatable({}, { __index = ENT }); PLAYER.__index = PLAYER
local WEAPON = setmetatable({}, { __index = ENT }); WEAPON.__index = WEAPON
function FindMetaTable(name) assert(name == "Player"); return PLAYER end

for _, kind in ipairs({ "Bool", "String", "Int", "Float" }) do
	PLAYER["SetNW2" .. kind] = function(self, k, v) assert(v ~= nil, "SetNW2" .. kind .. "(" .. k .. ", nil)"); self.nw[k] = v end
	PLAYER["GetNW2" .. kind] = function(self, k, d) local v = self.nw[k]; if v == nil then return d end; return v end
end
function PLAYER:IsPlayer() return true end
function PLAYER:Alive() return self.alive end
function PLAYER:Nick() return self.nick end
function PLAYER:SteamID() return "STEAM_0:1:" .. self.index end
function PLAYER:SteamID64() return "7656119" .. (7960265728 + self.index) end
function PLAYER:UserID() return self.index end
function PLAYER:IsBot() return self.bot == true end
function PLAYER:GetUserGroup() return self.group or "user" end
function PLAYER:IsAdmin() return self.group == "admin" or self.group == "superadmin" end
function PLAYER:IsSuperAdmin() return self.group == "superadmin" end
function PLAYER:EyePos() return self.pos + Vector(0, 0, 64) end
function PLAYER:GetShootPos() return self:EyePos() end
function PLAYER:EyeAngles() return self.eye end
function PLAYER:SetEyeAngles(a) self.eye = a end
function PLAYER:GetAimVector() return self.eye:Forward() end
function PLAYER:GetEyeTrace() return { Hit = false, Entity = self.lookAt, HitPos = self.lookAt and self.lookAt:WorldSpaceCenter() or (self:EyePos() + self:GetAimVector() * 4000) } end
function PLAYER:KeyDown(k) return self.keys[k] == true end
function PLAYER:KeyPressed(k) return self.keys[k] == true end
function PLAYER:GetActiveWeapon() return self.weapon or NULL end
function PLAYER:GetWeapons() return self.weapons end
function PLAYER:StripWeapons() self.weapons = {}; self.weapon = nil end
function PLAYER:Give(class)
	local def = assert(_weapons[class], "arme inconnue : " .. class)
	local w = newEntity({ __index = function(_, k) local v = def[k]; if v ~= nil then return v end; return WEAPON[k] end })
	w.pos = self.pos; w.owner = self; w.class = class
	self.weapons[#self.weapons + 1] = w
	if w.Initialize then w:Initialize() end
	return w
end
function PLAYER:SelectWeapon(class) for _, w in ipairs(self.weapons) do if w.class == class then self.weapon = w end end end
function PLAYER:Spawn() self.alive = true; self.health = 100; hook.Call("PlayerSpawn", GAMEMODE, self) end
function PLAYER:UnSpectate() end
function PLAYER:SetModel(m) assert(type(m) == "string" and m ~= ""); self.model = m end
function PLAYER:SetupHands() end
function PLAYER:SetNotSolid() end
function PLAYER:SetNoTarget() end
function PLAYER:Freeze(b) self.frozen = b end
function PLAYER:GodEnable() self.god = true end
function PLAYER:GodDisable() self.god = false end
function PLAYER:SetWalkSpeed(v) self.walk = v end
function PLAYER:SetRunSpeed(v) self.run = v end
function PLAYER:SetJumpPower(v) self.jump = v end
function PLAYER:SetLocalVelocity(v) self.vel = v end
function PLAYER:SetGroundEntity() end
function PLAYER:GetHull() return Vector(-16, -16, 0), Vector(16, 16, 72) end
function PLAYER:SetAnimation() end
function PLAYER:IsSprinting() return self.sprinting == true end
function PLAYER:OnGround() return true end
function PLAYER:GetMoveType() return MOVETYPE_WALK end
function PLAYER:LagCompensation() end
function PLAYER:ConCommand(c) self.lastCommand = c end
function PLAYER:ChatPrint(t) self.chat[#self.chat + 1] = t end
function PLAYER:GetViewModel() return NULL end

function WEAPON:GetOwner() return self.owner end
function WEAPON:SetHoldType() end
function WEAPON:SetNextPrimaryFire(t) self.nextFire = t end
function WEAPON:SendWeaponAnim() end

local players = {}
player = { GetAll = function() local o = {}; for _, p in ipairs(players) do if not p.removed then o[#o + 1] = p end end; return o end }
function _newPlayer(nick, group)
	local p = newEntity(PLAYER)
	p.nick = nick; p.group = group; p.alive = false; p.eye = Angle(); p.keys = {}; p.weapons = {}; p.chat = {}
	players[#players + 1] = p
	return p
end
function _removePlayer(p) hook.Call("PlayerDisconnected", GAMEMODE, p); p.removed = true end

local DMG = {}; DMG.__index = DMG
function DamageInfo() return setmetatable({ dmg = 0, type = 0 }, DMG) end
function DMG:SetDamage(d) assert(type(d) == "number"); self.dmg = d end
function DMG:GetDamage() return self.dmg end
function DMG:ScaleDamage(s) self.dmg = self.dmg * s end
function DMG:SetAttacker(a) assert(a ~= nil); self.attacker = a end
function DMG:GetAttacker() return self.attacker end
function DMG:SetInflictor(i) assert(i ~= nil); self.inflictor = i end
function DMG:GetInflictor() return self.inflictor end
function DMG:SetDamageType(t) self.type = t end
function DMG:IsDamageType(t) return self.type == t end
function DMG:SetDamagePosition() end

---------------------------------------------------------------- armes
_weapons = {}
function _loadWeapon(class, path, baseDefault)
	SWEP = { Primary = {}, Secondary = {} }
	assert(loadfile(path))()
	local def = SWEP; SWEP = nil
	local base = def.Base and _weapons[def.Base]
	if base then setmetatable(def, { __index = base }) end
	_weapons[class] = def
end

---------------------------------------------------------------- gamemode
GM = { FolderName = "shinkairp" }
