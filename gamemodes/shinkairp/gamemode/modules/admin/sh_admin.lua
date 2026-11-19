-- Permissions du staff (voir config/sh_staff.lua).
-- Compatible avec tout addon d'administration qui gère les usergroups
-- (ULX, SAM, FAdmin...) : seul le nom du groupe du joueur est utilisé.

Shinkai.Admin = Shinkai.Admin or {}
local Admin = Shinkai.Admin
local Staff = Shinkai.Config.Staff

-- Niveau d'un joueur. La console du serveur a tous les droits.
function Admin.GetLevel(ply)
	if not IsValid(ply) then return math.huge end

	local group = Staff.Groups[ply:GetUserGroup()]
	local level = group and group.level or 0

	if ply:IsSuperAdmin() then
		level = math.max(level, 100)
	elseif ply:IsAdmin() then
		level = math.max(level, 80)
	end
	return level
end

function Admin.HasPermission(ply, permission)
	local required = Staff.Permissions[permission]
	if not required then return false end
	return Admin.GetLevel(ply) >= required
end

-- Pôle du staff auquel appartient le joueur (nil pour un simple joueur).
function Admin.GetPole(ply)
	local group = IsValid(ply) and Staff.Groups[ply:GetUserGroup()]
	return group and group.pole or nil
end
