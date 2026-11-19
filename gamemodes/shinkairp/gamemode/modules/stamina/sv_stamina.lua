-- Endurance : dépense, récupération et épuisement.

Shinkai.Stamina = Shinkai.Stamina or {}
local Stamina = Shinkai.Stamina
local CFG = Shinkai.Config.Stamina

function Stamina.Max(ply)
	return ply:GetNW2Int("ShinkaiMaxStamina", 100)
end

function Stamina.Get(ply)
	return ply.ShinkaiStamina or 0
end

function Stamina.Set(ply, value)
	value = math.Clamp(value, 0, Stamina.Max(ply))
	ply.ShinkaiStamina = value
	ply:SetNW2Int("ShinkaiStamina", math.floor(value))
end

function Stamina.CanAfford(ply, amount)
	return Stamina.Get(ply) >= amount
end

-- Dépense de l'endurance et retarde la récupération.
function Stamina.Take(ply, amount)
	if amount <= 0 then return end
	Stamina.Set(ply, Stamina.Get(ply) - amount)
	ply.ShinkaiStaminaUsed = CurTime()
end

function Stamina.Give(ply, amount)
	Stamina.Set(ply, Stamina.Get(ply) + amount)
end

local function setExhausted(ply, exhausted)
	if ply.ShinkaiExhausted == exhausted then return end
	ply.ShinkaiExhausted = exhausted
	Shinkai.Stats.Apply(ply) -- un joueur épuisé ne peut plus sprinter
end

local function update(ply, dt)
	local max = Stamina.Max(ply)
	local sprinting = ply:IsSprinting()
		and ply:OnGround()
		and ply:GetMoveType() == MOVETYPE_WALK
		and not ply.ShinkaiExhausted
		and ply:GetVelocity():Length2DSqr() > 2500

	if sprinting and CFG.SprintDrain > 0 then
		Stamina.Take(ply, CFG.SprintDrain * dt)
	elseif CurTime() - (ply.ShinkaiStaminaUsed or 0) >= CFG.RegenDelay then
		Stamina.Give(ply, max * CFG.RegenPercent * dt)
	end

	local stamina = Stamina.Get(ply)
	if stamina <= 0 then
		setExhausted(ply, true)
	elseif ply.ShinkaiExhausted and stamina >= max * CFG.ExhaustRecover then
		setExhausted(ply, false)
	end
end

timer.Create("Shinkai.Stamina", CFG.TickRate, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		if ply.ShinkaiChar and ply:Alive() then
			update(ply, CFG.TickRate)
		end
	end
end)
