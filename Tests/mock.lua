-- Strict mock of the WoW Forever (1.60.x / Midnight API) surface the addon uses.
-- Unknown widget methods raise, so typos are caught instead of silently ignored.
-- M holds the simulated world: the clock, the timers, the CVars, Blizzard's
-- ranged swing bar, and what the addon printed.
M = {
    printed = {}, errors = {}, time = 1000, timers = {}, eventFrames = {}, allFrames = {},
    cvars = { showSwingTimer = true },
    autoShot = "Auto Shot",   -- the name C_Spell.GetSpellName gives spell 75
    speeds = { 2.6, nil, 3 }, -- UnitAttackSpeed("player"): main hand, off hand, ranged
}

-- Each session is a new game: the last one's swing bar is gone.
SwingTimerRangedFrame = nil

-- Secret sentinel: any comparison, arithmetic or concatenation raises.
local function secretError() error("attempt to use a secret value", 2) end
SECRET = setmetatable({}, {
    __eq = secretError, __lt = secretError, __le = secretError, __concat = secretError,
    __add = secretError, __sub = secretError, __mul = secretError, __div = secretError,
    __index = secretError,
    __tostring = function() return "SECRET" end,
})
function issecretvalue(v) return rawequal(v, SECRET) end
function GetTime() return M.time end
function GetLocale() return M.locale or "enUS" end
function UnitAttackSpeed(unit)
    assert(unit == "player", "only the player's speed is asked for")
    return M.speeds[1], M.speeds[2], M.speeds[3]
end

function print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
    M.printed[#M.printed + 1] = table.concat(parts, " ")
end
function geterrorhandler() return function(e) M.errors[#M.errors + 1] = tostring(e) end end

function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- Post-hooks, as the game's: the original runs first, then the hook with the
-- same arguments; the original's results are returned.
function hooksecurefunc(t, name, hook)
    if type(t) == "string" then
        t, name, hook = _G, t, name
    end
    local original = rawget(t, name)
    assert(type(original) == "function", "hooksecurefunc on a missing function " .. tostring(name))
    assert(type(hook) == "function", "hooksecurefunc needs a function")
    rawset(t, name, function(...)
        local results = { original(...) }
        hook(...)
        return unpack(results)
    end)
end

-- Blizzard's global strings the addon reads (enUS).
SWING_TIMER_RANGED = "Ranged"
HUD_EDIT_MODE_SWING_TIMER_DISABLED_TOOLTIP = "The Swing Timer is currently disabled. Enable it in the Game Menu in Options > Advanced Options > Swing Timer."
DEFAULTS = "Defaults"

-- Widgets ----------------------------------------------------------------------

local KNOWN_EVENTS = {
    ADDON_LOADED = true, PLAYER_LOGIN = true, UNIT_ATTACK_SPEED = true, UNIT_INVENTORY_CHANGED = true,
}
local DRAW_LAYERS = { BACKGROUND = true, BORDER = true, ARTWORK = true, OVERLAY = true, HIGHLIGHT = true }

-- Widget API methods are PascalCase; reading an unknown one is a typo in the
-- addon. Lowercase keys are plain data fields and may be nil.
local function Strict(class, kind)
    return {
        __index = function(_, k)
            local v = class[k]
            if v == nil and type(k) == "string" and k:match("^%u") then
                error(kind .. " has no method '" .. k .. "'", 2)
            end
            return v
        end,
    }
end

local Region = {}
function Region:SetSize(w, h) self.w, self.h = w, h end
function Region:SetWidth(w) self.w = w end
function Region:SetHeight(h) self.h = h end
function Region:GetWidth() return self.w or 0 end
function Region:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = { ... } end
function Region:ClearAllPoints() self.points = {} end
function Region:SetAllPoints(target) self.points = { { "ALL", target } } end
function Region:Show() self.shown = true end
function Region:Hide() self.shown = false end
function Region:SetShown(s) self.shown = not not s end
function Region:IsShown() return self.shown end
function Region:SetAlpha(a) self.alpha = a end

local FontString = setmetatable({}, { __index = Region })
function FontString:SetText(t) self.textValue = t end
function FontString:GetText() return self.textValue end
function FontString:SetFontObject(o) self.fontObject = o end
function FontString:SetTextColor(r, g, b) self.color = { r, g, b } end
function FontString:SetJustifyH() end
function FontString:GetStringWidth() return #tostring(self.textValue or "") * 6 end

local Texture = setmetatable({}, { __index = Region })
function Texture:SetColorTexture(r, g, b, a)
    for _, v in ipairs({ r, g, b, a or 1 }) do assert(type(v) == "number" and v >= 0 and v <= 1, "bad color") end
    self.color = { r, g, b, a }
end
function Texture:SetDrawLayer(layer, sublevel)
    assert(DRAW_LAYERS[layer], "bad draw layer " .. tostring(layer))
    assert(sublevel == nil or (sublevel >= -8 and sublevel <= 7 and sublevel % 1 == 0), "bad sublevel " .. tostring(sublevel))
    self.layer, self.sublevel = layer, sublevel or 0
end
function Texture:GetDrawLayer() return self.layer or "ARTWORK", self.sublevel or 0 end
M.atlases = { ["ui-swingtimerbar-filling-ranged"] = true }
function Texture:SetAtlas(atlas) assert(M.atlases[atlas], "unknown atlas " .. tostring(atlas)) self.atlas = atlas end
function Texture:SetDesaturated(d) assert(type(d) == "boolean", "SetDesaturated takes a boolean") self.desaturated = d end
function Texture:SetVertexColor(r, g, b, a)
    for _, v in ipairs({ r, g, b }) do assert(type(v) == "number" and v >= 0 and v <= 1, "bad vertex color") end
    assert(a == nil, "the addon leaves the fill's alpha alone")
    self.vertex = { r, g, b }
end

local FontStringMeta, TextureMeta = Strict(FontString, "FontString"), Strict(Texture, "Texture")
local function NewRegion(kind, parent)
    local r = { kind = kind, parent = parent, shown = true }
    return setmetatable(r, kind == "FontString" and FontStringMeta or TextureMeta)
end

local Frame = setmetatable({}, { __index = Region })
function Frame:SetScript(name, fn) self.scripts[name] = fn end
function Frame:GetScript(name) return self.scripts[name] end
-- The hook runs after the frame's own script, if it has one.
function Frame:HookScript(name, fn)
    assert(type(fn) == "function", "HookScript needs a function")
    local own = self.scripts[name]
    self.scripts[name] = function(...)
        if own then own(...) end
        fn(...)
    end
end
-- Showing or hiding a frame runs its OnShow or OnHide when that changes.
function Frame:Show()
    local was = self.shown
    self.shown = true
    if not was and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function Frame:Hide()
    local was = self.shown
    self.shown = false
    if was and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Frame:SetShown(s) if s then self:Show() else self:Hide() end end
function Frame:RegisterUnitEvent(event, ...)
    assert(select("#", ...) >= 1 and select("#", ...) <= 2, "RegisterUnitEvent takes one or two units")
    self:RegisterEvent(event)
    self.unitFilter = self.unitFilter or {}
    self.unitFilter[event] = { ... }
end
function Frame:RegisterEvent(event)
    if not KNOWN_EVENTS[event] then error("Attempt to register unknown event \"" .. event .. "\"") end
    M.eventFrames[self] = M.eventFrames[self] or {}
    M.eventFrames[self][event] = true
end
function Frame:UnregisterEvent(event) if M.eventFrames[self] then M.eventFrames[self][event] = nil end end
function Frame:UnregisterAllEvents() M.eventFrames[self] = nil end
-- A frame keeps its regions, in the order they were made, for the tests.
local function AddRegion(frame, kind)
    local region = NewRegion(kind, frame)
    frame.regions = frame.regions or {}
    frame.regions[#frame.regions + 1] = region
    return region
end
function Frame:CreateFontString() return AddRegion(self, "FontString") end
function Frame:CreateTexture(name, layer, template, sublevel)
    assert(template == nil, "no texture templates")
    local texture = AddRegion(self, "Texture")
    if layer then texture:SetDrawLayer(layer, sublevel) end
    return texture
end
-- CheckButton
function Frame:SetChecked(c) self.checked = not not c end
function Frame:GetChecked() return self.checked end
function Frame:SetHitRectInsets(l, r, t, b) assert(type(r) == "number") end
function Frame:EnableMouseWheel() end
-- A check button flips before its OnClick runs, as in the game.
function Frame:Click()
    if self.kind == "CheckButton" then self.checked = not self.checked end
    local s = self.scripts.OnClick
    if s then s(self, "LeftButton") end
end
function Frame:SetText(t) self.textValue = t end
function Frame:GetText() return self.textValue end
function Frame:GetFontString()
    local text = self.textValue or ""
    return { GetStringWidth = function() return #text * 6 end }
end
-- Slider
function Frame:SetMinMaxValues(a, b) self.min, self.max = a, b end
function Frame:SetValueStep(s) self.step = s end
function Frame:SetObeyStepOnDrag() end
function Frame:SetValue(v, userInput)
    self.value = v
    local s = self.scripts.OnValueChanged
    if s then s(self, v, userInput or false) end
end
function Frame:GetValue() return self.value end
-- StatusBar
-- The fill is not among the bar's regions: it is the StatusBar's own.
function Frame:SetStatusBarTexture(atlas)
    assert(self.kind == "StatusBar")
    if not self.fill then
        self.fill = NewRegion("Texture", self)
        self.fill:SetDrawLayer(M.fillLayer or "ARTWORK", M.fillSublevel or 0)
    end
    self.fill:SetAtlas(atlas)
end
function Frame:GetStatusBarTexture() assert(self.kind == "StatusBar") return self.fill end
local FrameMeta = Strict(Frame, "Frame")

local templates = {
    UICheckButtonTemplate = function(f) f.Text = f:CreateFontString() end,
    UISliderTemplateWithLabels = function(f)
        f.Text, f.Low, f.High = f:CreateFontString(), f:CreateFontString(), f:CreateFontString()
    end,
    UIPanelButtonTemplate = function() end,
}
function CreateFrame(kind, name, parent, template)
    local f = setmetatable({ kind = kind, name = name, parent = parent, template = template, scripts = {}, shown = true }, FrameMeta)
    if name then _G[name] = f end
    if template then
        local init = templates[template]
        assert(init, "unknown template " .. tostring(template))
        init(f)
    end
    M.allFrames[#M.allFrames + 1] = f
    return f
end
UIParent = CreateFrame("Frame", "UIParent")

-- A frame is drawn, and runs OnUpdate, only if it and its parents are shown.
function M.Visible(f)
    while f do
        if not f.shown then return false end
        f = f.parent
    end
    return true
end

-- Frames get an event in the order they were made, like in the game.
function M.Fire(event, ...)
    for _, frame in ipairs(M.allFrames) do
        local registered = M.eventFrames[frame]
        if registered and registered[event] then
            frame.scripts.OnEvent(frame, event, ...)
        end
    end
end

-- Moves the clock on in steps of a frame (1/50 s), running OnUpdate scripts
-- and due timers on the way.
function M.Advance(seconds)
    local target = M.time + seconds
    while M.time < target - 1e-9 do
        local step = math.min(0.02, target - M.time)
        M.time = M.time + step
        for _, frame in ipairs(M.allFrames) do
            local onUpdate = frame.scripts.OnUpdate
            if onUpdate and M.Visible(frame) then
                onUpdate(frame, step)
            end
        end
        local due = {}
        for i = #M.timers, 1, -1 do
            if M.timers[i].at <= M.time + 1e-9 then
                due[#due + 1] = table.remove(M.timers, i)
            end
        end
        for i = #due, 1, -1 do
            due[i].fn()
        end
    end
end

-- Game APIs ------------------------------------------------------------------

C_Timer = {
    After = function(delay, fn) M.timers[#M.timers + 1] = { at = M.time + delay, fn = fn } end,
}
C_CVar = {
    GetCVarBool = function(name) return M.cvars[name] end,
}
C_Spell = {
    GetSpellName = function(spellID)
        assert(spellID == 75, "only Auto Shot's name is asked for")
        return M.autoShot
    end,
}

GameTooltip = {}
function GameTooltip:SetOwner(owner) self.owner = owner end
function GameTooltip:SetText(t) self.lines = { t } end
function GameTooltip:AddLine(t) self.lines[#self.lines + 1] = t end
function GameTooltip:Show() self.shown = true end
function GameTooltip:Hide() self.shown = false end

SlashCmdList = {}

-- The settings panel: a canvas category per addon.
SettingsPanel = CreateFrame("Frame")
SettingsPanel:Hide()
Settings = {
    RegisterCanvasLayoutCategory = function(frame, name)
        assert(not M.category, "one category")
        M.category = { frame = frame, name = name }
        function M.category:GetID() return 77 end
        return M.category
    end,
    RegisterAddOnCategory = function(category) M.registered = category end,
    OpenToCategory = function(id)
        if M.openBlocked then error("ADDON_ACTION_BLOCKED") end
        assert(id == 77, "opens its own category")
        SettingsPanel:Show()
        M.category.frame:Show()
        M.category.frame:OnRefresh()
    end,
}

-- Blizzard's color picker (Mainline ColorPickerFrameMixin), as far as the
-- addon uses it. M.Pick plays the player picking a color, M.CancelPick
-- pressing Cancel.
ColorPickerFrame = { shown = false }
function ColorPickerFrame:SetupColorPickerAndShow(info)
    assert(type(info.swatchFunc) == "function" and type(info.cancelFunc) == "function", "needs swatchFunc and cancelFunc")
    self.info = info
    self.previousValues = { r = info.r, g = info.g, b = info.b, a = info.opacity }
    self.color = { info.r, info.g, info.b }
    self.shown = true
end
function ColorPickerFrame:GetColorRGB() return unpack(self.color) end
function M.Pick(r, g, b)
    ColorPickerFrame.color = { r, g, b }
    ColorPickerFrame.info.swatchFunc()
end
function M.CancelPick()
    ColorPickerFrame.info.cancelFunc(ColorPickerFrame.previousValues)
    ColorPickerFrame.shown = false
end

-- Blizzard's ranged swing bar ------------------------------------------------
-- What Blizzard_SwingTimer.lua does on Forever, cut down to the parts the addon
-- relies on. Blizzard's code is secure: it may use a secret duration, which
-- the mock lets through untouched.

local SwingTimerMixin = {}
function SwingTimerMixin:GetStatusBar() return self.StatusBar end
function SwingTimerMixin:ClearSwingTimer()
    self.swingDuration = nil
    self.swingEndTime = nil
    self:SetScript("OnUpdate", nil)
    self:GetStatusBar():SetValue(0)
end
function SwingTimerMixin:ResetSwingTimer(duration)
    local secret = issecretvalue(duration)
    if not secret and (not duration or duration <= 0) then
        return
    end
    self.swingDuration = duration
    self.swingEndTime = secret and SECRET or GetTime() + duration
    self:SetScript("OnUpdate", self.OnUpdate)
    self:GetStatusBar():SetValue(0)
end
function SwingTimerMixin:OnUpdate()
    if issecretvalue(self.swingEndTime) then
        return
    end
    local remaining = self.swingEndTime - GetTime()
    if remaining <= 0 then
        self:ClearSwingTimer()
        return
    end
    self:GetStatusBar():SetValue((self.swingDuration - remaining) / self.swingDuration)
end
function SwingTimerMixin:OnHide()
    self:ClearSwingTimer()
end

-- Makes SwingTimerRangedFrame, as loading Blizzard_SwingTimer does. With
-- fireEvent, ADDON_LOADED follows, as for an addon loaded after login.
function M.LoadSwingTimer(fireEvent)
    local bar = CreateFrame("Frame", "SwingTimerRangedFrame", UIParent)
    -- The mixin's methods are copied into the frame, as XML mixins are.
    for name, fn in pairs(SwingTimerMixin) do
        rawset(bar, name, fn)
    end
    -- <OnHide method="OnHide"/> in Blizzard's XML.
    bar:SetScript("OnHide", function(self) self:OnHide() end)
    bar.StatusBar = CreateFrame("StatusBar", nil, bar)
    bar.StatusBar:SetSize(200, 12)
    bar.StatusBar:SetStatusBarTexture("ui-swingtimerbar-filling-ranged")
    bar:ClearSwingTimer()
    M.bar = bar
    if fireEvent then
        M.Fire("ADDON_LOADED", "Blizzard_SwingTimer")
    end
    return bar
end

-- PLAYER_SWING for the ranged weapon: a shot went off.
function M.Shoot(duration)
    M.bar:ResetSwingTimer(duration)
end

-- Edit Mode gives the bar another width.
function M.ResizeBar(width)
    local statusBar = M.bar.StatusBar
    statusBar:SetSize(width, statusBar.h)
    local onSizeChanged = statusBar.scripts.OnSizeChanged
    if onSizeChanged then onSizeChanged(statusBar, width, statusBar.h) end
end

-- The zone as drawn now: "hidden", or "<width> <r>,<g>,<b> <alpha>".
function M.ZoneLook()
    local zone = M.bar.StatusBar.regions and M.bar.StatusBar.regions[1]
    if not zone or not zone.shown then
        return "hidden"
    end
    local c = zone.color
    return ("%.1f %g,%g,%g %g"):format(zone.w, c[1], c[2], c[3], c[4])
end

-- The fill as drawn now: "plain" (its own colors) or "r,g,b" (tinted).
function M.FillLook()
    local fill = M.bar:GetStatusBar():GetStatusBarTexture()
    local vertex = fill.vertex or { 1, 1, 1 }
    if not fill.desaturated then
        assert(vertex[1] == 1 and vertex[2] == 1 and vertex[3] == 1, "a colored fill should be desaturated")
        return "plain"
    end
    return ("%g,%g,%g"):format(vertex[1], vertex[2], vertex[3])
end
