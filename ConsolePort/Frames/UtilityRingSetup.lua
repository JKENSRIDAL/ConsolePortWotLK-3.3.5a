---------------------------------------------------------------
-- UtilityRingSetup.lua: combinación del anillo de utilidad
-- ConsolePort WotLK (Kenshín) — añadido en 0.2.2
---------------------------------------------------------------
-- La primera vez que se carga el addon pregunta con qué
-- combinación se abre el anillo de utilidad:
--   LT + RT + A       (Ctrl + Shift)
--   P1 + LT + RT + A  (Alt + Ctrl + Shift)
-- Se puede volver a elegir con /cpuring.
-- La elección se guarda en ConsolePortSettings.wotlkUtilityRing.
---------------------------------------------------------------
local _, db = ...

local UTILITY = 'CLICK ConsolePortUtilityToggle:LeftButton'
local BUTTON  = 'CP_R_DOWN' -- A en mandos Xbox
local COMBOS  = {
	['CTRL-SHIFT-']     = 'LT + RT + A',
	['ALT-CTRL-SHIFT-'] = 'P1 + LT + RT + A',
}

local isES = (GetLocale() == 'esES' or GetLocale() == 'esMX')
local function T(es, en) return isES and es or en end

local function Print(msg)
	print('|cff69ccf0ConsolePort|r: ' .. msg)
end

local function Settings()
	return db.Settings or ConsolePortSettings
end

-- Aplica la combinación a los atajos actuales del mando.
local function ApplyCombo(combo)
	local settings = Settings()
	if not settings or not COMBOS[combo] then return end
	settings.wotlkUtilityRing = combo

	if InCombatLockdown() then
		Print(T('se aplicará al salir de combate.', 'will apply after combat.'))
		local f = CreateFrame('Frame')
		f:RegisterEvent('PLAYER_REGEN_ENABLED')
		f:SetScript('OnEvent', function(self)
			self:UnregisterAllEvents()
			ApplyCombo(combo)
		end)
		return
	end

	local bindings = db.Bindings
	if type(bindings) == 'table' then
		local key = bindings[BUTTON] or {}
		bindings[BUTTON] = key
		-- quitar el anillo de la otra combinación y ponerlo en la elegida
		for other in pairs(COMBOS) do
			if other ~= combo and key[other] == UTILITY then
				key[other] = nil
			end
		end
		key[combo] = UTILITY

		ConsolePortBindingSet = ConsolePortBindingSet or {}
		local spec = db.CPAPI and db.CPAPI.GetSpecialization and db.CPAPI.GetSpecialization() or 1
		ConsolePortBindingSet[spec] = bindings
		if ConsolePort.LoadBindingSet then
			ConsolePort:LoadBindingSet(bindings, true)
		end
	end

	Print(T('anillo de utilidad en |cffffd200%s|r. Para cambiarlo escribe |cff69ccf0/cpuring|r.',
	        'utility ring on |cffffd200%s|r. To change it type |cff69ccf0/cpuring|r.'):format(COMBOS[combo]))
end

StaticPopupDialogs.CONSOLEPORT_WOTLK_UTILITYRING = {
	text = T('ConsolePort: ¿con qué combinación quieres abrir el anillo de utilidad?\n\n(LT = Shift, RT = Ctrl, P1 = Alt)\n\nPuedes cambiarlo cuando quieras con /cpuring',
	         'ConsolePort: which combination should open the utility ring?\n\n(LT = Shift, RT = Ctrl, P1 = Alt)\n\nYou can change it anytime with /cpuring'),
	button1 = COMBOS['CTRL-SHIFT-'],
	button2 = COMBOS['ALT-CTRL-SHIFT-'],
	OnAccept = function() ApplyCombo('CTRL-SHIFT-') end,
	OnCancel = function(_, _, reason)
		-- solo el clic en el botón 2; si la ventana se cerró por otra causa
		-- no se guarda nada y se vuelve a preguntar en el próximo inicio
		if reason == 'clicked' then ApplyCombo('ALT-CTRL-SHIFT-') end
	end,
	timeout = 0, whileDead = true, hideOnEscape = false, exclusive = true,
}

local function Ask()
	StaticPopup_Show('CONSOLEPORT_WOTLK_UTILITYRING')
end

-- Comando para volver a configurar
SLASH_CPURING1 = '/cpuring'
SlashCmdList.CPURING = Ask

-- Primera vez: esperar a que terminen la elección de mando y la
-- calibración (sus ventanas tienen prioridad) y a estar fuera de combate.
local Waiter = CreateFrame('Frame')
Waiter:RegisterEvent('PLAYER_ENTERING_WORLD')
Waiter:SetScript('OnEvent', function(self)
	self:UnregisterAllEvents()
	local settings = Settings()
	if not settings or settings.wotlkUtilityRing then return end
	self.wait = 6
	self:SetScript('OnUpdate', function(self, elapsed)
		self.wait = self.wait - elapsed
		if self.wait > 0 then return end
		self.wait = 3
		local busy = InCombatLockdown()
			or not settings.type
			or (ConsolePortSplashFrame and ConsolePortSplashFrame:IsShown())
			or (ConsolePort.calibrationFrame and ConsolePort.calibrationFrame:IsShown())
			or (StaticPopup1 and StaticPopup1:IsShown())
		if not busy then
			self:SetScript('OnUpdate', nil)
			Ask()
		end
	end)
end)
