-- Base des armes de mêlée de Shinkai RP.
-- Clic gauche : coup de base (dégâts = statistique Dégâts du personnage).
-- Clic droit maintenu : garde (voir modules/combat/sv_damage.lua).
-- Touches 1 à 9 : techniques du Souffle (voir modules/combat/cl_techniques.lua).

AddCSLuaFile()

SWEP.PrintName = "Arme de mêlée"
SWEP.Author = "Shinkai RP"
SWEP.Category = "Shinkai RP"
SWEP.Spawnable = false

-- Reconnu par le gamemode comme arme permettant d'utiliser les techniques.
SWEP.IsShinkaiWeapon = true

SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.UseHands = true
SWEP.HoldType = "melee"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.Slot = 0
SWEP.SlotPos = 1

SWEP.SwingSound = "weapons/iceaxe/iceaxe_swing1.wav"
SWEP.HitSound = "weapons/crowbar/crowbar_impact1.wav"
SWEP.HitFleshSound = "physics/flesh/flesh_impact_bullet3.wav"

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

-- Animation de frappe de l'arme en vue à la première personne.
-- Appelée aussi par les techniques.
function SWEP:PlaySwing()
	self:SendWeaponAnim(ACT_VM_MISSCENTER)
end

function SWEP:PrimaryAttack()
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return end

	local cfg = Shinkai.Config.Combat
	local delay = cfg.BasicAttackDelay
	local style = owner:GetStyle()
	if style then delay = delay * (style.modifiers.attackDelay or 1) end
	self:SetNextPrimaryFire(CurTime() + delay)

	if owner:IsStunned() or owner:IsGuarding() then return end

	owner:SetAnimation(PLAYER_ATTACK1)
	self:PlaySwing()
	self:EmitSound(self.SwingSound, 70, math.random(95, 105))

	if CLIENT then return end

	if cfg.BasicAttackCost > 0 then
		if not Shinkai.Stamina.CanAfford(owner, cfg.BasicAttackCost) then return end
		Shinkai.Stamina.Take(owner, cfg.BasicAttackCost)
	end

	owner:LagCompensation(true)
	local start = owner:GetShootPos()
	local tr = util.TraceHull({
		start = start,
		endpos = start + owner:GetAimVector() * cfg.BasicAttackRange,
		mins = Vector(-10, -10, -8),
		maxs = Vector(10, 10, 8),
		filter = owner,
		mask = MASK_SHOT_HULL,
	})
	owner:LagCompensation(false)

	if not tr.Hit then return end

	local target = tr.Entity
	if IsValid(target) then
		local living = target:IsPlayer() or target:IsNPC() or target:IsNextBot()
		sound.Play(living and self.HitFleshSound or self.HitSound, tr.HitPos, 75, 100)
		Shinkai.Actions.Hurt(owner, target, Shinkai.Stats.GetDamage(owner))
	else
		sound.Play(self.HitSound, tr.HitPos, 75, 100)
	end
end

-- Le clic droit sert à la garde : aucune action propre à l'arme.
function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end
