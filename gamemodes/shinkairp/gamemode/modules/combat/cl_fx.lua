-- Effets visuels des techniques, colorés selon le Souffle.
-- Ils n'utilisent que des textures du jeu de base : remplacez-les par vos
-- propres particules (.pcf) quand votre contenu sera prêt.

local Actions = Shinkai.Actions

local SPRITE = "sprites/light_glow02_add"

local function addParticle(emitter, pos, velocity, color, life, size)
	local particle = emitter:Add(SPRITE, pos)
	if not particle then return end

	particle:SetVelocity(velocity)
	particle:SetDieTime(life)
	particle:SetStartAlpha(255)
	particle:SetEndAlpha(0)
	particle:SetStartSize(size)
	particle:SetEndSize(size * 0.2)
	particle:SetColor(color.r, color.g, color.b)
	particle:SetAirResistance(120)
end

local DRAW = {}

-- Arc de particules perpendiculaire à la direction de frappe.
DRAW[Actions.FX_SLASH] = function(emitter, pos, dir, color, scale)
	local right = dir:Angle():Right()
	for i = -8, 8 do
		local offset = right * (i * 6 * scale) + dir * ((8 - math.abs(i)) * 4 * scale)
		addParticle(emitter, pos + offset, dir * 260 * scale + VectorRand() * 20, color, 0.35, 14 * scale)
	end
end

-- Anneau qui s'étend à l'horizontale.
DRAW[Actions.FX_BURST] = function(emitter, pos, _, color, scale)
	for i = 1, 36 do
		local angle = math.rad(i * 10)
		local out = Vector(math.cos(angle), math.sin(angle), 0)
		addParticle(emitter, pos + out * 20, out * 600 * scale + Vector(0, 0, math.Rand(0, 60)), color, 0.5, 22 * scale)
	end
end

-- Traînée le long de la direction du dash.
DRAW[Actions.FX_DASH] = function(emitter, pos, dir, color, scale)
	for i = 0, 24 do
		addParticle(emitter, pos + dir * (i * 14 * scale) + VectorRand() * 10, dir * 80 + VectorRand() * 30, color, 0.6, 16)
	end
end

-- Particules qui montent autour d'un point.
DRAW[Actions.FX_AURA] = function(emitter, pos, _, color, scale)
	for _ = 1, 24 do
		local offset = VectorRand() * 26 * scale
		offset.z = math.Rand(-30, 10)
		addParticle(emitter, pos + offset, Vector(0, 0, math.Rand(60, 140)), color, 0.9, 10 * scale)
	end
end

net.Receive("Shinkai.FX", function()
	local kind = net.ReadUInt(3)
	local pos = net.ReadVector()
	local dir = net.ReadNormal()
	local color = net.ReadColor()
	local scale = net.ReadFloat()

	local painter = DRAW[kind]
	if not painter then return end

	local emitter = ParticleEmitter(pos)
	if emitter then
		painter(emitter, pos, dir, color, scale)
		emitter:Finish()
	end

	local light = DynamicLight(0)
	if light then
		light.pos = pos
		light.r, light.g, light.b = color.r, color.g, color.b
		light.brightness = 2
		light.decay = 1200
		light.size = 260 * scale
		light.dietime = CurTime() + 0.4
	end
end)
