-- Cycle de vie du joueur : connexion, apparition, équipement, mort, déconnexion.

local GM = GM or GAMEMODE
local C = Shinkai.Config

function GM:PlayerInitialSpawn(ply)
	ply.ShinkaiChars = {}
	ply:SetNW2Bool("ShinkaiHasChar", false)

	if ply:IsBot() then
		timer.Simple(0, function()
			if IsValid(ply) then Shinkai.Char.LoadBot(ply) end
		end)
	end
end

function GM:PlayerSpawn(ply)
	ply:UnSpectate()
	ply:StripWeapons()

	-- Sans personnage, le joueur attend dans le menu : invisible, figé, invulnérable.
	if not ply.ShinkaiChar then
		ply:SetModel("models/player/kleiner.mdl")
		ply:SetNoDraw(true)
		ply:SetNotSolid(true)
		ply:Freeze(true)
		ply:GodEnable()
		return
	end

	ply:SetNoDraw(false)
	ply:SetNotSolid(false)
	ply:Freeze(false)
	ply:GodDisable()

	hook.Call("PlayerSetModel", self, ply)
	ply:SetupHands()

	ply.ShinkaiExhausted = false
	Shinkai.Stats.Apply(ply, true)
	Shinkai.Stamina.Set(ply, Shinkai.Stamina.Max(ply))

	hook.Call("PlayerLoadout", self, ply)
	Shinkai.Char.CheckStyle(ply)
end

function GM:PlayerSetModel(ply)
	local char = ply.ShinkaiChar
	local faction = char and C.Factions[char.faction]
	local model = char and char.model or ""

	if model == "" and faction then model = faction.models[1] end
	ply:SetModel(model ~= "" and model or "models/player/kleiner.mdl")
end

function GM:PlayerLoadout(ply)
	local faction = ply:GetFactionData()
	if faction and faction.weapon then
		ply:Give(faction.weapon)
		ply:SelectWeapon(faction.weapon)
	end
	return true
end

---------------------------------------------------------------------------
-- Mort et réapparition
---------------------------------------------------------------------------
hook.Add("PlayerDeath", "Shinkai.Respawn", function(ply)
	ply.ShinkaiNextSpawn = CurTime() + C.RespawnTime
	Shinkai.Effects.Clear(ply)
end)

function GM:PlayerDeathThink(ply)
	if CurTime() < (ply.ShinkaiNextSpawn or 0) then return end
	if ply:KeyPressed(IN_ATTACK) or ply:KeyPressed(IN_JUMP) then
		ply:Spawn()
	end
end

function GM:CanPlayerSuicide(ply)
	return C.AllowSuicide and ply:HasCharacter()
end

function GM:GetFallDamage(ply, speed)
	if not C.FallDamage then return 0 end
	return math.max(0, (speed - 580) * (100 / 444))
end

function GM:PlayerSwitchFlashlight()
	return true
end

function GM:PlayerNoClip(ply)
	return Shinkai.Admin.HasPermission(ply, "noclip")
end

---------------------------------------------------------------------------
-- Touches de menu : F1 techniques, F2 personnages, F4 staff
---------------------------------------------------------------------------
function GM:ShowHelp(ply)
	ply:ConCommand("shinkai_techniques")
end

function GM:ShowTeam(ply)
	if not ply.ShinkaiReady then return end
	if ply.ShinkaiChar and not C.AllowCharSwitch then
		return Shinkai.Notify(ply, "Le changement de personnage en jeu est désactivé.", Shinkai.NOTIFY_ERROR)
	end
	Shinkai.Char.SendMenu(ply)
end

function GM:ShowSpare2(ply)
	if Shinkai.Admin.HasPermission(ply, "menu") then
		ply:ConCommand("shinkai_admin")
	end
end

---------------------------------------------------------------------------
-- Déconnexion et arrêt du serveur
---------------------------------------------------------------------------
function GM:PlayerDisconnected(ply)
	Shinkai.Char.Save(ply)
end

function GM:ShutDown()
	Shinkai.Char.SaveAll()
end
