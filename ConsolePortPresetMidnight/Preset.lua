---------------------------------------------------------------
-- Preset.lua: disposición "Izquierda" de ConsolePort 3.x (Midnight)
---------------------------------------------------------------
-- Retail, esquema "Gatillos" (mando Xbox):
--   LT = Shift (M1)   RT = Ctrl (M2)   LB / RB = acciones
-- Ranuras del núcleo LK:
--   CP_R_DOWN=A  CP_R_RIGHT=B  CP_R_LEFT=X  CP_R_UP=Y
--   CP_L_*=cruceta  CP_X_LEFT=Back  CP_X_RIGHT=Start
--   CP_T1=LB  CP_T2=RB  CP_T3..T6=grips/paletas
---------------------------------------------------------------
local function B(none, shift, ctrl, both, alt, altShift, altCtrl, altAll)
	return {
		[''] = none, ['SHIFT-'] = shift, ['CTRL-'] = ctrl, ['CTRL-SHIFT-'] = both,
		-- capa ALT (paleta P1): requiere ConsolePort WotLK 0.2.0 o superior
		['ALT-'] = alt, ['ALT-SHIFT-'] = altShift, ['ALT-CTRL-'] = altCtrl, ['ALT-CTRL-SHIFT-'] = altAll,
	}
end
local function MB(bar, i) return 'MULTIACTIONBAR' .. bar .. 'BUTTON' .. i end

local RADIAL_MENU = 'CLICK ConsolePortRadialMenu:LeftButton'
local UTILITY     = 'CLICK ConsolePortUtilityToggle:LeftButton'
local RAIDCURSOR  = 'CLICK ConsolePortRaidCursorToggle:LeftButton'

local PRESET = {
	-- Bumpers (en retail esquema Gatillos: LB = ACTIONBUTTON2, RB = ACTIONBUTTON1)
	--                 solo            +LT (Shift)              +RT (Ctrl)               +LT+RT                     +P1 (ALT)   +P1+LT      +P1+RT       +P1+LT+RT
	CP_T1      = B('ACTIONBUTTON2', MB(1, 2), MB(1, 10), MB(1, 12),                 MB(3, 2),  MB(4, 2),  MB(3, 12), MB(4, 12)),
	CP_T2      = B('ACTIONBUTTON1', 'TARGETNEARESTENEMY', MB(1, 1), MB(1, 11),      MB(3, 1),  MB(4, 1),  MB(3, 11), MB(4, 11)),
	-- Botones frontales
	CP_R_DOWN  = B('JUMP', MB(1, 9), RADIAL_MENU, UTILITY,                          MB(3, 6),  MB(4, 6)),
	CP_R_RIGHT = B('ACTIONBUTTON5', 'ACTIONBUTTON8', MB(1, 5), MB(1, 8),            MB(3, 5),  MB(4, 5)),
	CP_R_LEFT  = B('ACTIONBUTTON3', 'ACTIONBUTTON6', MB(1, 3), MB(1, 6),            MB(3, 3),  MB(4, 3)),
	CP_R_UP    = B('ACTIONBUTTON4', 'ACTIONBUTTON7', MB(1, 4), MB(1, 7),            MB(3, 4),  MB(4, 4)),
	-- Cruceta
	CP_L_LEFT  = B('ACTIONBUTTON9',  MB(2, 1), MB(2, 5), MB(2, 9),                  MB(3, 7),  MB(4, 7)),
	CP_L_UP    = B('ACTIONBUTTON10', MB(2, 2), MB(2, 6), MB(2, 10),                 MB(3, 8),  MB(4, 8)),
	CP_L_RIGHT = B('ACTIONBUTTON11', MB(2, 3), MB(2, 7), MB(2, 11),                 MB(3, 9),  MB(4, 9)),
	CP_L_DOWN  = B('ACTIONBUTTON12', MB(2, 4), MB(2, 8), MB(2, 12),                 MB(3, 10), MB(4, 10)),
	-- Centro
	CP_X_LEFT  = B('OPENALLBAGS', 'TOGGLECHARACTER0', 'TOGGLEWORLDMAP', 'TOGGLEAUTORUN'),
	CP_X_RIGHT = B('TOGGLEGAMEMENU', RAIDCURSOR, 'CP_CAMZOOMOUT', 'CP_CAMZOOMIN'),
	CP_X_CENTER = B('TOGGLECHARACTER0', 'TOGGLESPELLBOOK', 'TOGGLETALENTS', nil),
	-- Paletas P2-P4: libres por ahora (P1 es ALT)
	CP_T3      = {},
	CP_T4      = {},
	CP_T5      = {},
	CP_T6      = {},
	CP_T_L3    = {},
	CP_T_R3    = {},
}

-- Qué botón físico muestra cada ranura lógica (iconos y textos)
local SETTINGS = {
	CP_M1 = 'CP_TL2',  -- Shift  -> LT
	CP_M2 = 'CP_TR2',  -- Ctrl   -> RT
	CP_T1 = 'CP_TL1',  -- acción -> LB
	CP_T2 = 'CP_TR1',  -- acción -> RB
	CP_M3 = 'CP_R_GRIP1', -- ALT    -> paleta P1 (Elite 2)
	skipGuideBtn = true, -- el botón Guía lo reserva Steam
	-- Un mando Xbox normal no tiene grips/paletas: no pedirlos al calibrar
	skipCP_T3 = true, skipCP_T4 = true, skipCP_T5 = true, skipCP_T6 = true,
}

local function Copy(t)
	local c = {}
	for k, v in pairs(t) do c[k] = type(v) == 'table' and Copy(v) or v end
	return c
end

local function Print(msg)
	print('|cff69ccf0ConsolePort|r Midnight: ' .. msg)
end

local function BuildSet(db)
	local set = Copy(PRESET)
	if db.Settings.wotlkUtilityRing == 'ALT-CTRL-SHIFT-' then -- elegido con /cpuring
		set.CP_R_DOWN['CTRL-SHIFT-'] = nil
		set.CP_R_DOWN['ALT-CTRL-SHIFT-'] = UTILITY
	end
	if not (ConsolePortRadialMenu) then
		set.CP_R_DOWN['CTRL-'] = nil -- sin el módulo de menú radial
	end
	return set
end

local function Apply()
	if InCombatLockdown() then
		return Print('no se puede aplicar en combate.')
	end
	local db = ConsolePort and ConsolePort.GetData and ConsolePort:GetData()
	if not db or not db.Settings then
		return Print('ConsolePort no está cargado.')
	end
	for k, v in pairs(SETTINGS) do
		db.Settings[k] = v
	end
	local set = BuildSet(db)
	db.Bindings = set
	ConsolePortBindingSet = ConsolePortBindingSet or {}
	local spec = db.CPAPI and db.CPAPI.GetSpecialization and db.CPAPI.GetSpecialization() or 1
	ConsolePortBindingSet[spec] = set
	Print('disposición aplicada. Recargando la interfaz...')
	ReloadUI()
end

StaticPopupDialogs.CONSOLEPORT_MIDNIGHT_PRESET = {
	text = 'ConsolePort: ¿aplicar la disposición de botones de Midnight?\n\nLT = Shift, RT = Ctrl, P1 = Alt, LB y RB = acciones.\nSe reemplazan tus atajos actuales del mando (de este personaje).',
	button1 = ACCEPT or 'Aceptar',
	button2 = CANCEL or 'Cancelar',
	OnAccept = Apply,
	timeout = 0, whileDead = true, hideOnEscape = true,
}

-- WotLK 0.2.3: Midnight es la disposición predeterminada.
-- Los personajes nuevos (sin atajos) la reciben al aceptar "cargar atajos por
-- defecto", y el botón "Default" de la ventana de atajos vuelve a ella.
if ConsolePort then
	function ConsolePort:GetDefaultBindingSet()
		local db = self.GetData and self:GetData()
		return BuildSet(db or {Settings = {}})
	end
end

-- Primera vez: mapeo de modificadores de Midnight (LT = Shift, RT = Ctrl, P1 = Alt)
local Defaults = CreateFrame('Frame')
Defaults:RegisterEvent('ADDON_LOADED')
Defaults:SetScript('OnEvent', function(self, _, name)
	if name ~= 'ConsolePortPresetMidnight' then return end
	self:UnregisterAllEvents()
	local settings = ConsolePortSettings
	if settings and not settings.wotlkDefaults then
		for k, v in pairs(SETTINGS) do
			settings[k] = v
		end
		settings.wotlkDefaults = 1
	end
end)

SLASH_CPMIDNIGHT1 = '/cpmidnight'
SlashCmdList.CPMIDNIGHT = function()
	StaticPopup_Show('CONSOLEPORT_MIDNIGHT_PRESET')
end
