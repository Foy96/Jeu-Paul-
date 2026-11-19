-- Sauvegarde des données (SQLite intégré à Garry's Mod : garrysmod/sv.db).
-- Tout l'accès à la base passe par Shinkai.DB : pour migrer vers MySQL,
-- seul ce fichier est à réécrire.

Shinkai.DB = Shinkai.DB or {}
local DB = Shinkai.DB

local function query(str)
	local result = sql.Query(str)
	if result == false then
		ErrorNoHalt("[Shinkai] Erreur SQL : " .. tostring(sql.LastError()) .. "\n  Requête : " .. str .. "\n")
	end
	return result
end

local function esc(value)
	return sql.SQLStr(tostring(value))
end

function DB.Init()
	query([[CREATE TABLE IF NOT EXISTS shinkai_characters (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		steamid TEXT NOT NULL,
		name TEXT NOT NULL,
		faction TEXT NOT NULL,
		grade INTEGER NOT NULL DEFAULT 1,
		style TEXT NOT NULL DEFAULT '',
		xp INTEGER NOT NULL DEFAULT 0,
		money INTEGER NOT NULL DEFAULT 0,
		model TEXT NOT NULL DEFAULT '',
		playtime INTEGER NOT NULL DEFAULT 0,
		created INTEGER NOT NULL DEFAULT 0,
		data TEXT NOT NULL DEFAULT '{}'
	)]])
	query("CREATE INDEX IF NOT EXISTS shinkai_characters_steamid ON shinkai_characters (steamid)")

	query([[CREATE TABLE IF NOT EXISTS shinkai_whitelist (
		steamid TEXT NOT NULL,
		faction TEXT NOT NULL,
		PRIMARY KEY (steamid, faction)
	)]])
end

-- Convertit une ligne SQL (tout en texte) en personnage.
local function rowToCharacter(row)
	return {
		id = tonumber(row.id),
		steamid = row.steamid,
		name = row.name,
		faction = row.faction,
		grade = tonumber(row.grade) or 1,
		style = row.style or "",
		xp = tonumber(row.xp) or 0,
		money = tonumber(row.money) or 0,
		model = row.model or "",
		playtime = tonumber(row.playtime) or 0,
		created = tonumber(row.created) or 0,
		data = util.JSONToTable(row.data or "{}") or {},
	}
end

function DB.LoadCharacters(steamid64)
	local rows = query("SELECT * FROM shinkai_characters WHERE steamid = " .. esc(steamid64) .. " ORDER BY id")
	local characters = {}
	for _, row in ipairs(rows or {}) do
		characters[#characters + 1] = rowToCharacter(row)
	end
	return characters
end

function DB.NameExists(name)
	local found = query("SELECT id FROM shinkai_characters WHERE LOWER(name) = LOWER(" .. esc(name) .. ") LIMIT 1")
	return found ~= nil and found ~= false
end

-- Crée un personnage et le renvoie (nil en cas d'erreur).
function DB.CreateCharacter(character)
	local ok = query(string.format(
		"INSERT INTO shinkai_characters (steamid, name, faction, grade, style, xp, money, model, playtime, created, data) VALUES (%s, %s, %s, %d, %s, %d, %d, %s, 0, %d, '{}')",
		esc(character.steamid), esc(character.name), esc(character.faction),
		character.grade or 1, esc(character.style or ""), character.xp or 0,
		character.money or 0, esc(character.model or ""), os.time()
	))
	if ok == false then return nil end

	local row = query("SELECT * FROM shinkai_characters WHERE id = last_insert_rowid()")
	return row and row[1] and rowToCharacter(row[1]) or nil
end

function DB.SaveCharacter(character)
	if character.id <= 0 then return end -- personnage temporaire (bot)

	query(string.format(
		"UPDATE shinkai_characters SET name = %s, grade = %d, style = %s, xp = %d, money = %d, model = %s, playtime = %d, data = %s WHERE id = %d",
		esc(character.name), character.grade, esc(character.style), character.xp,
		character.money, esc(character.model), math.floor(character.playtime),
		esc(util.TableToJSON(character.data or {})), character.id
	))
end

function DB.DeleteCharacter(id)
	query("DELETE FROM shinkai_characters WHERE id = " .. math.floor(id))
end

---------------------------------------------------------------------------
-- Whitelist des factions
---------------------------------------------------------------------------
function DB.IsWhitelisted(steamid64, faction)
	local found = query("SELECT 1 FROM shinkai_whitelist WHERE steamid = " .. esc(steamid64) .. " AND faction = " .. esc(faction) .. " LIMIT 1")
	return found ~= nil and found ~= false
end

function DB.SetWhitelisted(steamid64, faction, allowed)
	if allowed then
		query("INSERT OR IGNORE INTO shinkai_whitelist (steamid, faction) VALUES (" .. esc(steamid64) .. ", " .. esc(faction) .. ")")
	else
		query("DELETE FROM shinkai_whitelist WHERE steamid = " .. esc(steamid64) .. " AND faction = " .. esc(faction))
	end
end

DB.Init()
