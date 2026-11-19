-- Griffes du Démon : combat à mains nues.

AddCSLuaFile()

SWEP.Base = "shinkai_base_melee"
SWEP.PrintName = "Griffes"
SWEP.Instructions = "Clic gauche : attaquer — Clic droit : garde — 1 à 9 : techniques"

SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.HoldType = "fist"

SWEP.SwingSound = "npc/zombie/claw_miss1.wav"
SWEP.HitSound = "npc/zombie/claw_strike1.wav"
SWEP.HitFleshSound = "npc/zombie/claw_strike2.wav"

local SWINGS = { "fists_left", "fists_right" }

local function playSequence(weapon, name)
	local owner = weapon:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return end

	local viewModel = owner:GetViewModel()
	if not IsValid(viewModel) then return end

	local sequence = viewModel:LookupSequence(name)
	if sequence and sequence >= 0 then
		viewModel:SendViewModelMatchingSequence(sequence)
	end
end

function SWEP:Deploy()
	playSequence(self, "fists_draw")
	return true
end

function SWEP:PlaySwing()
	playSequence(self, SWINGS[math.random(#SWINGS)])
end
