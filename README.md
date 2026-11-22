# Shinkai RP

Gamemode Garry's Mod — **Demon Slayer Serious RP**, écrit en GLua.

Gamemode autonome (dérivé de `base`) : grades, statistiques, dix Souffles, combat, endurance, personnages, HUD, sauvegarde et outils du staff.

## Installation

1. Copier le dossier `gamemodes/shinkairp` dans `garrysmod/gamemodes/` du serveur.
2. Lancer le serveur avec `+gamemode shinkairp`.
3. Se donner les droits : `ulx adduser <nom> superadmin` (ou l'équivalent SAM / FAdmin).

Aucune base de données à installer : la sauvegarde utilise le SQLite intégré (`garrysmod/sv.db`).

## En jeu

| Touche | Action |
|---|---|
| Clic gauche | Coup de base (dégâts = statistique Dégâts) |
| Clic droit maintenu | Garde : −50 % de dégâts de face, coûte de l'endurance |
| 1 à 7 | Techniques du Souffle (arme en main) |
| F1 | Fiche des techniques |
| F2 | Menu des personnages |
| F4 | Menu staff |

Touches personnalisées : `bind <touche> "shinkai_technique 3"`.

Chat : texte simple = parler à proximité, `/ch` chuchoter, `/c` crier, `/me` action, `//` hors-RP.

## Structure

```
gamemodes/shinkairp/
├── entities/weapons/        katana, griffes et leur base commune
└── gamemode/
    ├── shared.lua           ordre de chargement des modules
    ├── loader.lua           chargeur (préfixes sv_ / cl_ / sh_)
    ├── config/              TOUT l'équilibrage
    │   ├── sh_config.lua      réglages généraux
    │   ├── sh_grades.lua      grades et statistiques
    │   ├── sh_techniques.lua  barème dégâts / endurance / recharge
    │   └── sh_staff.lua       pôles et permissions
    ├── styles/              un fichier par Souffle
    ├── core/                outils, réseau, journal, thème d'interface
    └── modules/
        ├── data/            sauvegarde SQLite
        ├── grades/  styles/ registres
        ├── character/       personnages, menus de création et de choix du Souffle
        ├── stats/           PV, Dégâts, END, VIT
        ├── stamina/         endurance
        ├── effects/         paralysie, invisibilité, rage, soin progressif, poison...
        ├── combat/          techniques, recharges, dégâts, garde
        ├── progression/     expérience et grades
        ├── chat/            chat RP de proximité
        ├── admin/           commandes et menu du staff
        └── hud/             HUD et fiche des techniques
```

Les modules ne se parlent qu'à l'exécution (fonctions `Shinkai.*` et hooks) : on peut en ajouter un sans toucher aux autres.

## Faire évoluer le serveur

**Ajouter un Souffle** — créer `gamemode/styles/sh_monsouffle.lua` ; il apparaît seul dans les menus :

```lua
local Act = Shinkai.Actions

Shinkai.Styles.Register("glace", {
    name = "Souffle de la Glace",
    faction = "slayer",
    color = Color(150, 220, 255),
    modifiers = { speed = 1.05 },   -- hp, speed, endurance, attackDelay, cooldown
    techniques = {
        { name = "Givre", tier = 1, description = "...",
          execute = function(ply, tech, ctx)
              Act.Slash(ply, ctx, { effect = { id = "slow", duration = 2 } })
          end },
    },
})
```

Briques disponibles (`modules/combat/sv_actions.lua`) : `Slash`, `Combo`, `Burst`, `DashStrike`, `Dash`, `Launch`, `TeleportNear`, `Heal`, `Knockback`, `AimEnemy`, `AimAlly`. Effets (`modules/effects/sh_effects_defs.lua`) : `stun`, `blind`, `invisible`, `rage`, `regen`, `poison`, `haste`, `power`, `slow`.

**Ajouter un grade** — une ligne dans `config/sh_grades.lua`.
**Ajouter un effet** — un `Effects.Register` dans `sh_effects_defs.lua`.
**Ajouter une commande staff** — un `Admin.Register` dans `modules/admin/sv_admin.lua`.
**Brancher un autre système** — hooks `ShinkaiModifyStats`, `ShinkaiCanUseTechnique`, `ShinkaiTechniqueUsed`, `ShinkaiGradeChanged`, `ShinkaiCharacterLoaded`.

## Commandes du staff

Depuis le chat (`!commande`), la console (`shinkai commande`) ou le menu F4. `!aide` liste celles auxquelles on a droit.

| Commande | Niveau | Effet |
|---|---|---|
| `charinfo <joueur>` | 10 | Fiche du personnage |
| `heal`, `stamina`, `resetcd <joueur>` | 40 | Soin, endurance, recharges |
| `addxp <joueur> <montant>` | 40 | Récompense d'XP |
| `annonce <message>` | 40 | Annonce serveur |
| `promote`, `demote <joueur>` | 50 | ±1 grade |
| `setstyle <joueur> <souffle\|aucun>` | 50 | Attribue un Souffle |
| `setname <joueur> <nom>` | 50 | Renomme |
| `whitelist <joueur> <faction> <1\|0>` | 50 | Accès à une faction sous whitelist |
| `setgrade`, `setxp`, `setmoney` | 80 | Valeurs directes |

Niveaux par groupe (`config/sh_staff.lua`) : `superadmin` 100 (Direction), `admin` et `developpeur` 80, `moderateur` 50, `animateur` 40, `cm` 10.

## Choix d'équilibrage à valider

Ces points n'étaient pas fixés par le cahier des charges ; ils sont tous modifiables dans `config/`.

- **Dégâts des techniques** : le barème (20, 30, 40...) est multiplié par `Dégâts du grade / 10`. Il vaut donc tel quel pour un Mizunoto et suit la montée des PV ensuite. Sans cela, un ultime à 100 tuerait un Mizunoto (150 PV) en deux coups et ne ferait rien à un Pilier (4 800 PV). Mode fixe : `Combat.DamageMode = "flat"`.
- **Déblocage des techniques** : I Mizunoto, II Mizunoe, III Kanoto, IV Tsuchinoto, V Hinoto, Ultime Kinoto.
- **XP par grade** : 100, 250, 500, 900, 1 500, 2 400, 3 600, 5 200, 7 500, 10 500. Pilier et Rang Z s'obtiennent uniquement par le staff.
- **Bonus des Souffles** : Foudre +15 % VIT ; Insecte et Fleur +7 % ; Serpent −15 % PV et coups de base 30 % plus rapides ; Brume −30 % de recharge ; Son +25 % END.
- **Mode Rage** : 20 s, +40 VIT (fixe à tous les grades), dégâts ×1,5, PV max −25 %.
- **Soins** : Insecte 25 % des PV immédiatement ; Fleur 40 % en 8 s.
- **Démons** : END et VIT reprises du grade Pourfendeur équivalent ; régénération passive hors combat ; un seul style provisoire (« Art démoniaque ») en attendant leurs pouvoirs.
- **Noms de techniques inventés** : Serpent V et ultime, ainsi que Brume, Son, Bête, Insecte et Fleur (le cahier des charges reçu s'arrêtait au Serpent IV).

## Contenu provisoire

Aucun modèle ni son personnalisé n'est fourni : les personnages utilisent des modèles Half-Life 2, le katana le modèle du pied-de-biche, et les effets visuels des particules colorées du jeu de base. À remplacer dans `config/sh_config.lua` (modèles), `entities/weapons/` (armes) et `modules/combat/cl_fx.lua` (effets).

## Images de création de personnage

Les écrans de création utilisent trois images, à déposer dans `gamemodes/shinkairp/content/materials/shinkai/` :

| Fichier | Écran |
|---|---|
| `factions.png` (1672 × 941) | Choix de la faction : zones Démon, Pourfendeur et Confirmer |
| `pourfendeurs.png` | Fond du formulaire de création Pourfendeur |
| `demons.png` | Fond du formulaire de création Démon |

Le serveur les envoie automatiquement aux joueurs. Une image absente est remplacée par un fond uni. Si `factions.png` change, ses zones cliquables se règlent en haut de `modules/character/cl_creation.lua`.

## Tests

```
pip install lupa
python3 tests/run.py
```

Le dossier `tests/` exécute le gamemode hors du jeu, dans une simulation de l'API Garry's Mod : chargement serveur et client, création de personnage, chacune des techniques, effets, progression, sauvegarde, HUD et menus. Il vérifie la logique, pas le rendu ni le comportement du moteur : un essai en jeu reste nécessaire.
