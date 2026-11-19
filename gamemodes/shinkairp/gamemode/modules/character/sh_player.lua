-- Accès aux informations du personnage depuis un joueur.
-- Ces données sont synchronisées par le serveur (variables NW2) et donc
-- lisibles côté client comme côté serveur.

local PLAYER = FindMetaTable("Player")

function PLAYER:HasCharacter()
	return self:GetNW2Bool("ShinkaiHasChar", false)
end

-- Nom RP du personnage (nom Steam tant qu'aucun personnage n'est chargé).
function PLAYER:GetRPName()
	local name = self:GetNW2String("ShinkaiName", "")
	return name ~= "" and name or self:Nick()
end

function PLAYER:GetFaction()
	return self:GetNW2String("ShinkaiFaction", "")
end

function PLAYER:GetFactionData()
	return Shinkai.Config.Factions[self:GetFaction()]
end

function PLAYER:GetGradeIndex()
	return self:GetNW2Int("ShinkaiGrade", 1)
end

function PLAYER:GetGradeData()
	return Shinkai.Grades.Get(self:GetFaction(), self:GetGradeIndex())
end

function PLAYER:GetStyleId()
	return self:GetNW2String("ShinkaiStyle", "")
end

-- Style de combat actif. Renvoie nil sous le grade minimal (l'Aspirant n'a pas de Souffle).
function PLAYER:GetStyle()
	if self:GetGradeIndex() < Shinkai.Config.StyleMinGrade then return nil end
	return Shinkai.Styles.Get(self:GetStyleId())
end

function PLAYER:GetXP()
	return self:GetNW2Int("ShinkaiXP", 0)
end

function PLAYER:GetMoney()
	return self:GetNW2Int("ShinkaiMoney", 0)
end

function PLAYER:GetStamina()
	return self:GetNW2Int("ShinkaiStamina", 0)
end

function PLAYER:GetMaxStamina()
	return self:GetNW2Int("ShinkaiMaxStamina", 100)
end

function PLAYER:IsStunned()
	return self:GetNW2Float("ShinkaiStunEnd", 0) > CurTime()
end

function PLAYER:IsInvisible()
	return self:GetNW2Bool("ShinkaiInvisible", false)
end

function PLAYER:HoldsShinkaiWeapon()
	local weapon = self:GetActiveWeapon()
	return IsValid(weapon) and weapon.IsShinkaiWeapon == true
end

function PLAYER:IsGuarding()
	return Shinkai.Config.Guard.Enabled
		and self:Alive()
		and self:KeyDown(IN_ATTACK2)
		and self:HoldsShinkaiWeapon()
		and not self:IsStunned()
end

-- Deux joueurs sont alliés s'ils appartiennent à la même faction.
function PLAYER:IsAllyOf(other)
	if not (IsValid(other) and other:IsPlayer()) then return false end
	if other == self then return true end
	return self:HasCharacter() and other:HasCharacter() and self:GetFaction() == other:GetFaction()
end
