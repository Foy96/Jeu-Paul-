-- Accès aux grades définis dans config/sh_grades.lua.

Shinkai.Grades = Shinkai.Grades or {}
local Grades = Shinkai.Grades

function Grades.GetAll(faction)
	return Shinkai.Config.Grades[faction] or {}
end

function Grades.Get(faction, index)
	return Grades.GetAll(faction)[index]
end

function Grades.Count(faction)
	return #Grades.GetAll(faction)
end

-- Retrouve un numéro de grade à partir d'un numéro, d'un id ou d'un nom.
function Grades.FindIndex(faction, query)
	local list = Grades.GetAll(faction)

	local number = tonumber(query)
	if number then
		number = math.floor(number)
		return list[number] and number or nil
	end

	query = string.lower(tostring(query))
	for index, grade in ipairs(list) do
		if grade.id == query or string.lower(grade.name) == query then
			return index
		end
	end
end

-- Nom complet affiché : "Rang SS — Lune inférieure" ou "Mizunoto".
function Grades.DisplayName(grade)
	if not grade then return "Inconnu" end
	if grade.title then return grade.name .. " — " .. grade.title end
	return grade.name
end
