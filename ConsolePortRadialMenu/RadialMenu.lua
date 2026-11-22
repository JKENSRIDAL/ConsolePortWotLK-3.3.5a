---------------------------------------------------------------
-- RadialMenu.lua: menú de juego radial (estilo ConsolePort 3.x)
---------------------------------------------------------------
-- Réplica para 3.3.5a del "ConsolePortMenuRing" del retail:
--  * anillo de porciones con la porción activa iluminada,
--  * arte de fondo según la clase del personaje,
--  * etiquetas alrededor y texto central de la opción enfocada.
--
-- 3.3.5a no tiene MaskTexture, Line ni C_GamePad, así que:
--  * las máscaras (barril, hueco central, cuñas) vienen horneadas
--    en las texturas de Assets (ver tools/make_radialmenu_assets.py),
--  * la entrada direccional la provee el driver radial del núcleo
--    (ConsolePortRadialHandler), igual que el anillo de utilidad.
--
-- Uso: mantener el atajo, inclinar el stick, soltar para abrir.
---------------------------------------------------------------
local addOnName, env = ...
local L = env.L

local ASSETS   = [[Interface\AddOns\ConsolePortRadialMenu\Assets\]]
local BUTTON   = [[Interface\AddOns\ConsolePort\Textures\Button\]]
local FRAME_SZ = 450   -- referencia de todas las medidas (igual que el retail)
local RADIUS   = 225   -- radio de los botones
local LABEL_R  = 316   -- radio de las etiquetas
local LABEL_Y  = 318   -- límite vertical de etiquetas (no pisar las líneas)
local RING_SZ  = 720   -- tamaño del anillo marmolado
local BTN_SZ   = 60

local pi, cos, sin, rad, abs = math.pi, math.cos, math.sin, math.rad, math.abs

---------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------
local function GetClassColor()
	local _, class = UnitClass('player')
	local c = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class or 'PRIEST'] or { r = 1, g = 1, b = 1 }
	return c.r, c.g, c.b, class
end

-- SetRotation existe en 3.3.5a, pero dejamos un respaldo por texcoords
-- por si algún cliente personalizado no la expone.
local function Rotate(texture, radians)
	if texture.SetRotation then
		return texture:SetRotation(radians)
	end
	local c, s = cos(radians), sin(radians)
	local function p(x, y) -- rota (x,y) alrededor de (0.5,0.5)
		x, y = x - 0.5, y - 0.5
		return 0.5 + (x * c + y * s), 0.5 + (-x * s + y * c)
	end
	local ulx, uly = p(0, 0); local llx, lly = p(0, 1)
	local urx, ury = p(1, 0); local lrx, lry = p(1, 1)
	texture:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
end

-- Distancia angular con signo, por el camino más corto.
local function AngleDelta(from, to)
	local d = (to - from) % (2 * pi)
	if d > pi then d = d - 2 * pi end
	return d
end

local function NewTexture(parent, layer, sub, file, size, blend)
	local t = parent:CreateTexture(nil, layer, nil, sub)
	if file then t:SetTexture(file) end
	if size then t:SetSize(size, size) end
	t:SetPoint('CENTER')
	if blend then t:SetBlendMode(blend) end
	return t
end

---------------------------------------------------------------
-- Frame seguro principal
---------------------------------------------------------------
local Menu = CreateFrame('Button', 'ConsolePortRadialMenu', UIParent,
	'SecureHandlerStateTemplate, SecureHandlerShowHideTemplate, SecureActionButtonTemplate')
Menu:SetSize(FRAME_SZ, FRAME_SZ)
Menu:SetPoint('CENTER', 0, 0)
Menu:SetFrameStrata('DIALOG')
Menu:RegisterForClicks('LeftButtonDown', 'LeftButtonUp')
Menu:Hide()
Menu.Buttons, Menu.ByAngle = {}, {}
env.Menu = Menu

-- Algunos clientes personalizados (Ascension) no mezclan los métodos
-- de SecureHandler en frames creados desde Lua (ver Init.lua del núcleo).
if ConsolePort and ConsolePort.GetData then
	local CPAPI = ConsolePort:GetData().CPAPI
	if CPAPI and CPAPI.IsCustomClient and CPAPI.IsCustomClient() then
		function Menu:SetFrameRef(label, ref) SecureHandlerSetFrameRef(self, label, ref) end
		function Menu:Execute(body) SecureHandlerExecute(self, body) end
		function Menu:WrapScript(frame, script, body) SecureHandlerWrapScript(frame, script, self, body) end
	end
end

---------------------------------------------------------------
-- Capa visual (no segura: se puede animar en combate)
---------------------------------------------------------------
local Art = CreateFrame('Frame', nil, Menu)
Art:SetAllPoints()
Art:SetFrameLevel(Menu:GetFrameLevel())
Menu.Art = Art

Art.Backdrop   = NewTexture(Art, 'BACKGROUND', 0, nil)
Art.Backdrop:SetSize(1400, 700)
Art.Ring       = NewTexture(Art, 'BACKGROUND', 2, ASSETS .. 'Pie_Ring', RING_SZ)
Art.Ring:SetVertexColor(0.10, 0.10, 0.12, 0.78)
Art.Separators = NewTexture(Art, 'BORDER', 0, nil, RING_SZ)
Art.Slice      = NewTexture(Art, 'BORDER', 1, nil, RING_SZ, 'ADD')
Art.Pointer    = NewTexture(Art, 'ARTWORK', 0, ASSETS .. 'Pie_Pointer', RING_SZ)

Art.TopLine    = Art:CreateTexture(nil, 'ARTWORK')
Art.TopLine:SetTexture(ASSETS .. 'TopLine')
Art.TopLine:SetSize(900, 16)
Art.TopLine:SetPoint('CENTER', 0, 352)
Art.BottomLine = Art:CreateTexture(nil, 'ARTWORK')
Art.BottomLine:SetTexture(ASSETS .. 'TopLine')
Art.BottomLine:SetSize(900, 16)
Art.BottomLine:SetPoint('CENTER', 0, -352)

Art.Title = Art:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
Art.Title:SetPoint('CENTER', 0, 10)
Art.Title:SetWidth(260)
Art.Sub = Art:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
Art.Sub:SetPoint('TOP', Art.Title, 'BOTTOM', 0, -4)
Art.Sub:SetWidth(260)
Art.Hint = Art:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
Art.Hint:SetPoint('CENTER', 0, -46)
Art.Hint:SetText(L.HINT_RELEASE)

do -- fuente con contorno para el texto central (como GameFontHighlightOutline)
	local font, size = Art.Title:GetFont()
	Art.Title:SetFont(font, size + 4, 'OUTLINE')
end

function Menu:ApplyClassArt()
	local r, g, b, class = GetClassColor()
	self.cc = { r, g, b }
	local file = ASSETS .. 'Art\\' .. (class or 'PRIEST')
	Art.Backdrop:SetTexture(file)
	if not Art.Backdrop:GetTexture() then -- clase sin arte (cliente custom)
		Art.Backdrop:SetTexture(ASSETS .. 'Art\\PRIEST')
	end
	Art.Separators:SetVertexColor(r, g, b, 0.35)
	Art.Slice:SetVertexColor(r, g, b, 0.55)
	Art.Pointer:SetVertexColor(r, g, b, 0.95)
	Art.TopLine:SetVertexColor(1, 1, 1, 1)
	Art.BottomLine:SetVertexColor(1, 1, 1, 1)
	for _, button in ipairs(self.Buttons) do
		button.Glow:SetVertexColor(r, g, b, 1)
	end
end

---------------------------------------------------------------
-- Botones
---------------------------------------------------------------
local ButtonMixin = {}

function ButtonMixin:SetEntry(key)
	local entry = env.Entries[key]
	self.key, self.entry = key, entry
	if not entry then
		self:SetAttribute('type', nil)
		self:SetAttribute('macrotext', nil)
		self.Icon:SetTexture(nil)
		self.Label:SetText('')
		return
	end
	self:SetAttribute('type', 'macro')
	self:SetAttribute('macrotext', env:Resolve(entry.macro))
	self:UpdateDisplay()
end

function ButtonMixin:UpdateDisplay()
	local entry = self.entry
	if not entry then return end
	local icon = env:Resolve(entry.icon)
	if icon == 'portrait' then
		SetPortraitTexture(self.Icon, 'player')
	elseif entry.flat then
		self.Icon:SetTexture(icon)
	else
		SetPortraitToTexture(self.Icon, icon)
	end
	self.text = env:Resolve(entry.text)
	self.sub  = env:Resolve(entry.sub)
	self.Label:SetText(self.text)
end

function ButtonMixin:SetFocus(enabled)
	self.focused = enabled
	if enabled then
		self.Glow:Show()
		self.Hilite:Show()
		self.Icon:SetVertexColor(1, 1, 1)
		self.Label:SetTextColor(1, 1, 1)
	else
		self.Glow:Hide()
		self.Hilite:Hide()
		self.Icon:SetVertexColor(0.8, 0.8, 0.8)
		self.Label:SetTextColor(0.86, 0.82, 0.70)
	end
end

function ButtonMixin:PostClick()
	PlaySound('igMainMenuOptionCheckBoxOn')
end

local function CreateMenuButton(index)
	local button = CreateFrame('Button', 'ConsolePortRadialMenuButton' .. index, Menu, 'SecureActionButtonTemplate')
	button:SetSize(BTN_SZ, BTN_SZ)
	button:RegisterForClicks('AnyUp')

	button.Glow = button:CreateTexture(nil, 'BACKGROUND')
	button.Glow:SetTexture(ASSETS .. 'Glow')
	button.Glow:SetBlendMode('ADD')
	button.Glow:SetSize(BTN_SZ * 2.2, BTN_SZ * 2.2)
	button.Glow:SetPoint('CENTER')
	button.Glow:Hide()

	button.Shadow = button:CreateTexture(nil, 'BACKGROUND', nil, 1)
	button.Shadow:SetTexture(BUTTON .. 'NormalShadow')
	button.Shadow:SetSize(BTN_SZ * 1.25, BTN_SZ * 1.25)
	button.Shadow:SetPoint('CENTER', 0, -5)
	button.Shadow:SetAlpha(0.75)

	button.Icon = button:CreateTexture(nil, 'ARTWORK')
	button.Icon:SetSize(BTN_SZ - 4, BTN_SZ - 4)
	button.Icon:SetPoint('CENTER')

	button.Border = button:CreateTexture(nil, 'OVERLAY')
	button.Border:SetTexture(BUTTON .. 'Normal')
	button.Border:SetAllPoints()

	button.Hilite = button:CreateTexture(nil, 'OVERLAY', nil, 1)
	button.Hilite:SetTexture(BUTTON .. 'Hilite')
	button.Hilite:SetBlendMode('ADD')
	button.Hilite:SetAllPoints()
	button.Hilite:Hide()

	button.Label = Art:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	do
		local font, size = button.Label:GetFont()
		button.Label:SetFont(font, size + 1, 'OUTLINE')
	end

	for k, v in pairs(ButtonMixin) do button[k] = v end
	button:SetScript('PostClick', button.PostClick)
	button:SetFocus(false)
	return button
end

---------------------------------------------------------------
-- Entorno seguro
---------------------------------------------------------------
-- '_onuse' del driver radial se reemplaza: el original intercambia
-- presets del anillo de utilidad, lo que aquí borraría los macros.
local ONUSE = [[
	local istoggled = ...
	self:SetAttribute('toggled', istoggled)
	if istoggled then
		self:SetAttribute('KEYUP', nil)
		self:SetAttribute('KEYDOWN', nil)
		self:SetAttribute('KEYLEFT', nil)
		self:SetAttribute('KEYRIGHT', nil)
		self:SetAttribute('KEYHORZ', nil)
		self:SetAttribute('KEYVERT', nil)
		self:SetAttribute('index', nil)
		control:CallMethod('CallMethodFromFrame', self:GetName(), 'OnButtonFocused', 'nil')
		control:RunFor(HANDLE, HANDLE:GetAttribute('hBind'), self:GetName())
		self:Show()
	else
		control:RunFor(HANDLE, HANDLE:GetAttribute('hClear'), self:GetName())
		self:Hide()
	end
]]

Menu.CallMethodFromFrame = function(self, frameName, method, ...)
	local frame = _G[frameName]
	if frame and type(frame[method]) == 'function' then
		frame[method](frame, ...)
	end
end

function Menu:Initialize()
	if self.initialized or InCombatLockdown() then return end
	local HANDLE = ConsolePortRadialHandler
	if not HANDLE or not HANDLE.RegisterFrame then return end
	self.HANDLE = HANDLE
	HANDLE:RegisterFrame(self)                 -- inyecta onkey/bits/_preclick...
	self:SetAttribute('_onuse', ONUSE)
	self:WrapScript(self, 'PreClick', self:GetAttribute('_preclick'))
	self.initialized = true
	self:Refresh()
end

---------------------------------------------------------------
-- Disposición
---------------------------------------------------------------
function Menu:Refresh()
	if InCombatLockdown() or not self.HANDLE then
		self.pendingRefresh = true
		return
	end
	self.pendingRefresh = nil

	local size = self.HANDLE:GetIndexSize()
	size = (size >= 16) and 16 or 8
	self.size = size
	self:SetAttribute('size', size)
	wipe(self.ByAngle)

	local layout = env:GetLayout(size)
	for i = 1, math.max(size, #self.Buttons) do
		local button = self.Buttons[i]
		if i <= size then
			button = button or CreateMenuButton(i)
			self.Buttons[i] = button

			local angle = self.HANDLE:GetAngleForIndex(i)
			local x, y = -(RADIUS * cos(rad(angle))), RADIUS * sin(rad(angle))
			button:ClearAllPoints()
			button:SetPoint('CENTER', x, y)
			button:SetID(i)
			button.rotation = -(i - 1) * (2 * pi / size)
			button:SetEntry(layout[i])
			button:Show()

			-- etiqueta: hacia afuera del anillo, justificada según el lado
			local lx = -(LABEL_R * cos(rad(angle)))
			local ly = math.max(-LABEL_Y, math.min(LABEL_Y, LABEL_R * sin(rad(angle))))
			local label = button.Label
			label:ClearAllPoints()
			if abs(lx) < 40 then
				label:SetPoint('CENTER', Art, 'CENTER', lx, ly)
				label:SetJustifyH('CENTER')
			elseif lx < 0 then
				label:SetPoint('RIGHT', Art, 'CENTER', lx, ly)
				label:SetJustifyH('RIGHT')
			else
				label:SetPoint('LEFT', Art, 'CENTER', lx, ly)
				label:SetJustifyH('LEFT')
			end
			label:Show()

			local key = tostring(angle)
			self.ByAngle[key] = button
			self:SetFrameRef(key, button)
		elseif button then
			button:Hide()
			button.Label:Hide()
			button:SetEntry(nil)
		end
	end

	Art.Separators:SetTexture(ASSETS .. 'Pie_Separators' .. size)
	Art.Slice:SetTexture(ASSETS .. 'Pie_Slice' .. size)
	self:SetScale((ConsolePortRadialMenuDB and ConsolePortRadialMenuDB.scale) or 1)
	self:ApplyClassArt()
end

---------------------------------------------------------------
-- Foco y animación
---------------------------------------------------------------
function Menu:OnButtonFocused(index)
	local button = self.ByAngle[index]
	if self.focus and self.focus ~= button then
		self.focus:SetFocus(false)
	end
	self.focus = button
	if button and button.entry then
		button:SetFocus(true)
		Art.Title:SetText(button.text)
		Art.Sub:SetText(button.sub or '')
		Art.Hint:Show()
		self.targetRot = button.rotation
		if not self.curRot then
			self.curRot = button.rotation
		end
		self.sliceAlpha = 1
		if self.lastFocus ~= button then
			PlaySound('igMainMenuOptionCheckBoxOff')
			self.lastFocus = button
		end
	else
		Art.Title:SetText(L.TITLE)
		Art.Sub:SetText('')
		Art.Hint:Hide()
		self.sliceAlpha = 0
		self.lastFocus = nil
	end
end

local RING_SPIN, SMOOTH = 0.05, 12

function Menu:OnUpdate(elapsed)
	-- giro lento del mármol (como el BgAnim de 60s del retail)
	self.spin = ((self.spin or 0) + elapsed * RING_SPIN * 2 * pi) % (2 * pi)
	Rotate(Art.Ring, self.spin)

	-- la porción activa y el puntero siguen al foco suavemente
	if self.targetRot and self.curRot then
		local d = AngleDelta(self.curRot, self.targetRot)
		if abs(d) < 0.002 then
			self.curRot = self.targetRot
		else
			self.curRot = self.curRot + d * math.min(1, elapsed * SMOOTH)
		end
		Rotate(Art.Slice, self.curRot)
		Rotate(Art.Pointer, self.curRot)
	end

	local a = Art.Slice:GetAlpha()
	local target = self.sliceAlpha or 0
	if a ~= target then
		a = a + (target - a) * math.min(1, elapsed * SMOOTH)
		if abs(a - target) < 0.01 then a = target end
		Art.Slice:SetAlpha(a)
		Art.Pointer:SetAlpha(a)
	end

	-- aparición
	if self.fade and self.fade < 1 then
		self.fade = math.min(1, self.fade + elapsed * 6)
		Art:SetAlpha(self.fade)
	end
end

Menu:HookScript('OnShow', function(self)
	self.fade, self.curRot, self.targetRot = 0, nil, nil
	Art:SetAlpha(0)
	Art.Slice:SetAlpha(0)
	Art.Pointer:SetAlpha(0)
	for _, button in ipairs(self.Buttons) do
		if button:IsShown() then button:UpdateDisplay() end
	end
	PlaySound('igMainMenuOpen')
	self:SetScript('OnUpdate', self.OnUpdate)
end)

Menu:HookScript('OnHide', function(self)
	self:SetScript('OnUpdate', nil)
	if self.focus then self.focus:SetFocus(false) end
	self.focus, self.lastFocus = nil, nil
end)

---------------------------------------------------------------
-- Integración con ConsolePort (lista de atajos y barra)
---------------------------------------------------------------
local BINDING = 'CLICK ConsolePortRadialMenu:LeftButton'
local ICON    = [[Interface\Icons\INV_Misc_Gear_01]]

local function HookCustomBindings()
	if not ConsolePort or not ConsolePort.GetCustomBindings or ConsolePort.__radialMenuHooked then return end
	local original = ConsolePort.GetCustomBindings
	ConsolePort.GetCustomBindings = function(self, ...)
		local list = original(self, ...)
		tinsert(list, { name = L.CATEGORY })
		tinsert(list, { name = L.BINDING, binding = BINDING })
		return list
	end
	ConsolePort.__radialMenuHooked = true
end

local function RegisterBarIcon()
	local manifest = ConsolePortBarManifest
	if type(manifest) == 'table' and type(manifest.BindingIcons) == 'table' then
		manifest.BindingIcons[BINDING] = manifest.BindingIcons[BINDING] or ICON
	end
end

---------------------------------------------------------------
-- Eventos
---------------------------------------------------------------
local Events = CreateFrame('Frame')
Events:RegisterEvent('ADDON_LOADED')
Events:RegisterEvent('PLAYER_LOGIN')
Events:RegisterEvent('PLAYER_REGEN_ENABLED')
Events:RegisterEvent('UNIT_PORTRAIT_UPDATE')
Events:SetScript('OnEvent', function(self, event, arg1)
	if event == 'ADDON_LOADED' and arg1 == addOnName then
		ConsolePortRadialMenuDB = ConsolePortRadialMenuDB or { scale = 1 }
		HookCustomBindings()
	elseif event == 'PLAYER_LOGIN' then
		HookCustomBindings()
		RegisterBarIcon()
		Menu:Initialize()
	elseif event == 'PLAYER_REGEN_ENABLED' then
		if not Menu.initialized then
			Menu:Initialize()
		elseif Menu.pendingRefresh then
			Menu:Refresh()
		end
	elseif event == 'UNIT_PORTRAIT_UPDATE' and arg1 == 'player' then
		if Menu:IsShown() then
			for _, button in ipairs(Menu.Buttons) do
				if button.key == 'CHARACTER' then button:UpdateDisplay() end
			end
		end
	end
end)

---------------------------------------------------------------
-- Comando: /cprm scale 0.9 | /cprm reset
---------------------------------------------------------------
SLASH_CPRADIALMENU1 = '/cprm'
SlashCmdList.CPRADIALMENU = function(msg)
	local cmd, arg = strsplit(' ', (msg or ''):lower(), 2)
	if cmd == 'scale' and tonumber(arg) then
		ConsolePortRadialMenuDB.scale = math.max(0.5, math.min(1.5, tonumber(arg)))
		if not InCombatLockdown() then Menu:SetScale(ConsolePortRadialMenuDB.scale) end
	elseif cmd == 'reset' then
		ConsolePortRadialMenuDB = { scale = 1 }
		Menu:Refresh()
	else
		print('|cff69ccf0ConsolePort|r ' .. L.TITLE .. ': /cprm scale <0.5-1.5>, /cprm reset')
	end
end
