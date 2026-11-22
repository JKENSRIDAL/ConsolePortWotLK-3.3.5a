---------------------------------------------------------------
-- Data.lua: entradas del Menú Radial
---------------------------------------------------------------
-- Cada entrada se convierte en un botón seguro con type=macro.
-- Se prefiere "/click <BotónDeBlizzard>" (no ensucia la IU) y
-- se usa un /script de respaldo cuando el botón no existe
-- (clientes personalizados, IU reemplazada, etc).
---------------------------------------------------------------
local _, env = ...
local L = env.L

local ICON = [[Interface\Icons\%s]]

local function Click(frameName, fallback)
	return function()
		if _G[frameName] then
			return '/click ' .. frameName
		end
		return fallback
	end
end

local function Static(text)
	return function() return text end
end

env.Entries = {
	CHARACTER = {
		text  = function() return CHARACTER_BUTTON or 'Personaje' end;
		sub   = L.SUB_CHARACTER;
		icon  = 'portrait';
		macro = Click('CharacterMicroButton', '/script ToggleCharacter("PaperDollFrame")');
	};
	SPELLBOOK = {
		text  = function() return SPELLBOOK_ABILITIES_BUTTON or SPELLBOOK or 'Hechizos' end;
		sub   = L.SUB_SPELLS;
		icon  = ICON:format('INV_Misc_Book_09');
		macro = Click('SpellbookMicroButton', '/script ToggleSpellBook(BOOKTYPE_SPELL)');
	};
	TALENTS = {
		text  = function() return TALENTS_BUTTON or TALENTS or 'Talentos' end;
		sub   = L.SUB_TALENTS;
		icon  = ICON:format('Ability_Marksmanship');
		macro = Click('TalentMicroButton', '/script ToggleTalentFrame()');
	};
	BAGS = {
		text  = function() return L.BAGS end;
		sub   = L.SUB_BAGS;
		icon  = ICON:format('INV_Misc_Bag_08');
		macro = Static('/script OpenAllBags()');
	};
	GAMEMENU = {
		text  = function() return MAINMENU_BUTTON or 'Menú' end;
		sub   = L.SUB_MENU;
		icon  = ICON:format('INV_Misc_Gear_01');
		macro = Click('MainMenuMicroButton', '/script ToggleGameMenu()');
	};
	SOCIAL = {
		text  = function() return SOCIAL_BUTTON or 'Social' end;
		sub   = L.SUB_SOCIAL;
		icon  = ICON:format('INV_Letter_17');
		macro = Click('SocialsMicroButton', '/script ToggleFriendsFrame()');
	};
	LFD = {
		text  = function() return DUNGEONS_BUTTON or LOOKING_FOR_DUNGEON or 'Mazmorras' end;
		sub   = L.SUB_LFD;
		icon  = ICON:format('INV_Misc_GroupLooking');
		macro = Click('LFDMicroButton', '/script ToggleLFDParentFrame()');
	};
	QUESTLOG = {
		text  = function() return QUESTLOG_BUTTON or QUEST_LOG or 'Misiones' end;
		sub   = L.SUB_QUESTS;
		icon  = ICON:format('INV_Misc_Note_01');
		macro = Click('QuestLogMicroButton', '/script ToggleFrame(QuestLogFrame)');
	};
	ACHIEVEMENTS = {
		text  = function() return ACHIEVEMENT_BUTTON or ACHIEVEMENTS or 'Logros' end;
		icon  = ICON:format('Achievement_Win_Wintergrasp');
		macro = Click('AchievementMicroButton', '/script ToggleAchievementFrame()');
	};
	PVP = {
		text  = function() return PLAYER_V_PLAYER or 'JcJ' end;
		icon  = function()
			local faction = UnitFactionGroup('player')
			return ICON:format(faction == 'Horde' and 'Achievement_PVP_H_H' or 'Achievement_PVP_A_A')
		end;
		macro = Click('PVPMicroButton', '/script TogglePVPFrame()');
	};
	MAP = {
		text  = function() return WORLD_MAP or L.MAP end;
		icon  = ICON:format('INV_Misc_Map02');
		macro = Click('MiniMapWorldMapButton', '/script ToggleFrame(WorldMapFrame)');
	};
	CALENDAR = {
		text  = function() return L.CALENDAR end;
		icon  = ICON:format('INV_Misc_Note_03');
		macro = Click('GameTimeFrame', '/script Calendar_Toggle()');
	};
	MACROS = {
		text  = function() return MACROS or L.MACROS end;
		icon  = ICON:format('INV_Misc_Note_06');
		macro = Static('/macro');
	};
	CONSOLEPORT = {
		text  = function() return L.CONSOLEPORT end;
		sub   = L.SUB_CP;
		icon  = [[Interface\AddOns\ConsolePort\Textures\Logos\CP]];
		flat  = true; -- no aplicar recorte circular
		macro = Static('/consoleport');
	};
	HELP = {
		text  = function() return HELP_BUTTON or 'Ayuda' end;
		icon  = ICON:format('INV_Misc_QuestionMark');
		macro = Click('HelpMicroButton', '/script ToggleHelpFrame()');
	};
	RELOAD = {
		text  = function() return L.RELOAD end;
		icon  = ICON:format('Spell_Holy_BorrowedTime');
		macro = Static('/console reloadui');
	};
}

-- Orden horario empezando arriba. El tamaño lo dicta el tipo de
-- radial configurado en ConsolePort (8 o 16 direcciones).
env.Layouts = {
	[8] = {
		'CHARACTER', 'SPELLBOOK', 'TALENTS', 'BAGS',
		'GAMEMENU', 'SOCIAL', 'LFD', 'QUESTLOG',
	};
	[16] = {
		'CHARACTER', 'SPELLBOOK', 'TALENTS', 'ACHIEVEMENTS',
		'BAGS', 'MAP', 'CALENDAR', 'CONSOLEPORT',
		'GAMEMENU', 'RELOAD', 'MACROS', 'HELP',
		'SOCIAL', 'PVP', 'LFD', 'QUESTLOG',
	};
}

function env:GetLayout(size)
	local custom = ConsolePortRadialMenuDB and ConsolePortRadialMenuDB.layouts and ConsolePortRadialMenuDB.layouts[size]
	return custom or self.Layouts[size] or self.Layouts[8]
end

function env:Resolve(value, ...)
	if type(value) == 'function' then
		return value(...)
	end
	return value
end
