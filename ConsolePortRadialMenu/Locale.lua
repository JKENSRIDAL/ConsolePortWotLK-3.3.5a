---------------------------------------------------------------
-- Locale.lua: textos del Menú Radial
---------------------------------------------------------------
local _, env = ...
local L = {}
env.L = L

local isES = (GetLocale() == 'esES' or GetLocale() == 'esMX')

local function T(es, en) return isES and es or en end

L.TITLE          = T('Menú radial', 'Radial menu')
L.CATEGORY       = T('Menú', 'Menu')
L.BINDING        = T('Menú radial (mantener)', 'Radial menu (hold)')
L.BAGS           = T('Bolsas', 'Bags')
L.MAP            = T('Mapa del mundo', 'World map')
L.CALENDAR       = T('Calendario', 'Calendar')
L.MACROS         = T('Macros', 'Macros')
L.CONSOLEPORT    = 'ConsolePort'
L.RELOAD         = T('Recargar IU', 'Reload UI')
L.LEAVE          = T('Abandonar grupo', 'Leave group')
L.GUILD          = T('Hermandad', 'Guild')
L.CLOSE          = T('Cerrar', 'Close')
L.SUB_CHARACTER  = T('Equipo y atributos', 'Gear and stats')
L.SUB_SPELLS     = T('Habilidades', 'Abilities')
L.SUB_TALENTS    = T('Especialización', 'Specialization')
L.SUB_BAGS       = T('Inventario', 'Inventory')
L.SUB_MENU       = T('Opciones y sistema', 'Options and system')
L.SUB_SOCIAL     = T('Amigos y grupo', 'Friends and group')
L.SUB_LFD        = T('Buscador de mazmorras', 'Dungeon finder')
L.SUB_QUESTS     = T('Registro de misiones', 'Quest log')
L.SUB_CP         = T('Configuración del mando', 'Controller settings')
L.HINT_RELEASE   = T('Suelta para confirmar', 'Release to confirm')

-- Texto de la tecla en la IU de atajos de Blizzard
BINDING_HEADER_CPRADIALMENU = 'ConsolePort: ' .. L.TITLE
_G['BINDING_NAME_CLICK ConsolePortRadialMenu:LeftButton'] = L.BINDING
