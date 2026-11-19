-- Progression : expérience et évolution des grades.
-- L'XP d'un grade (config/sh_grades.lua) est le total à atteindre pour
-- l'obtenir. Les grades marqués staffOnly ne s'obtiennent que par le staff.

Shinkai.Progression = Shinkai.Progression or {}
local Progression = Shinkai.Progression
local Grades = Shinkai.Grades
local Char = Shinkai.Char
local CFG = Shinkai.Config.Progression

-- Change le grade d'un joueur. `by` (facultatif) est le membre du staff responsable.
function Progression.SetGrade(ply, index, by)
	local char = Char.Get(ply)
	if not char then return false end

	local grade = Grades.Get(char.faction, index)
	if not grade or index == char.grade then return false end

	local oldIndex = char.grade
	local promoted = index > oldIndex
	local oldGrade = Grades.Get(char.faction, oldIndex)

	-- L'XP suit le grade : au moins le seuil en montant, exactement le seuil en descendant.
	Char.SetXP(ply, promoted and math.max(char.xp, grade.xp) or grade.xp)
	Char.SetGrade(ply, index)

	Shinkai.Notify(ply, (promoted and "Promotion : " or "Rétrogradation : ") .. Grades.DisplayName(grade),
		promoted and Shinkai.NOTIFY_SUCCESS or Shinkai.NOTIFY_INFO)
	Shinkai.Log("Grade", string.format("%s : %s -> %s (%s)", Shinkai.LogName(ply),
		oldGrade and oldGrade.name or "?", grade.name, IsValid(by) and Shinkai.LogName(by) or "automatique"))

	hook.Run("ShinkaiGradeChanged", ply, index, oldIndex)
	return true
end

function Progression.Promote(ply, by)
	local char = Char.Get(ply)
	return char ~= nil and Progression.SetGrade(ply, char.grade + 1, by)
end

function Progression.Demote(ply, by)
	local char = Char.Get(ply)
	return char ~= nil and Progression.SetGrade(ply, char.grade - 1, by)
end

-- Monte automatiquement de grade tant que l'XP le permet.
function Progression.CheckPromotion(ply)
	if not CFG.AutoPromote then return end

	local char = Char.Get(ply)
	while char do
		local nextGrade = Grades.Get(char.faction, char.grade + 1)
		if not nextGrade or nextGrade.staffOnly or char.xp < nextGrade.xp then break end
		if not Progression.SetGrade(ply, char.grade + 1) then break end
	end
end

function Progression.AddXP(ply, amount, reason)
	local char = Char.Get(ply)
	if not char or amount == 0 then return false end

	Char.SetXP(ply, char.xp + amount)
	if amount > 0 then
		Shinkai.Notify(ply, string.format("+%d XP%s", amount, reason and (" — " .. reason) or ""))
	end
	Progression.CheckPromotion(ply)
	return true
end

---------------------------------------------------------------------------
-- Sources d'expérience
---------------------------------------------------------------------------
hook.Add("PlayerDeath", "Shinkai.Progression", function(victim, _, attacker)
	if not (IsValid(attacker) and attacker:IsPlayer()) or attacker == victim then return end
	if not attacker:HasCharacter() or not victim:HasCharacter() or attacker:IsAllyOf(victim) then return end

	local xp = CFG.KillXP + CFG.KillXPPerGrade * (victim:GetGradeIndex() - 1)
	if xp > 0 then Progression.AddXP(attacker, xp, "adversaire vaincu") end
end)

hook.Add("OnNPCKilled", "Shinkai.Progression", function(_, attacker)
	if IsValid(attacker) and attacker:IsPlayer() and CFG.NPCKillXP > 0 then
		Progression.AddXP(attacker, CFG.NPCKillXP, "créature vaincue")
	end
end)

if CFG.PlaytimeXP > 0 then
	timer.Create("Shinkai.PlaytimeXP", CFG.PlaytimeInterval, 0, function()
		for _, ply in ipairs(player.GetAll()) do
			if ply.ShinkaiChar and not ply:IsBot() then
				Progression.AddXP(ply, CFG.PlaytimeXP, "temps de jeu")
			end
		end
	end)
end
