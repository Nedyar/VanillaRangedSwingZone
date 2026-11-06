-- Behavioral tests for Vanilla Ranged Swing Zone. run.lua runs them in Lua
-- 5.1, the game's Lua, against mock.lua, a strict stand-in for the WoW
-- Forever API that includes Blizzard's ranged swing bar.
--
-- Each session starts a fresh game (NewSession: the mock and the addon's
-- files, loaded in the order of its TOC), logs in and plays a scenario: shots
-- going off, the bar emptying, settings changed through the options page and
-- the slash commands.
local failures, passes = 0, 0
local ns
local function check(cond, message)
    if cond then
        passes = passes + 1
    else
        failures = failures + 1
        print_real("FAIL: " .. message)
    end
end
local function eq(actual, expected, message)
    check(actual == expected, message .. " (expected " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
end

-- The addon's files run with this environment: they read the globals as
-- usual, and any global they set other than ADDON_GLOBALS is a leak.
local ADDON_GLOBALS = {
    VanillaRangedSwingZoneDB = true,
    SLASH_VANILLARANGEDSWINGZONE1 = true, SLASH_VANILLARANGEDSWINGZONE2 = true,
}
local leaks, leaked = {}, {}
local ADDON_ENV = setmetatable({}, {
    __index = _G,
    __newindex = function(_, key, value)
        if not ADDON_GLOBALS[key] and not leaked[key] then
            leaked[key] = true
            leaks[#leaks + 1] = tostring(key)
        end
        _G[key] = value
    end,
})

-- opts: saved (the saved settings the client loads), locale, lateBar (the
-- swing bar loads after login), before (runs after the mock, before the addon),
-- fillLayer and fillSublevel (where Blizzard's fill is drawn).
local function NewSession(opts)
    opts = opts or {}
    assert(loadstring(SOURCES["mock.lua"], "@mock.lua"))()
    VanillaRangedSwingZoneDB = opts.saved
    M.locale = opts.locale
    M.fillLayer, M.fillSublevel = opts.fillLayer, opts.fillSublevel
    if not opts.lateBar then
        M.LoadSwingTimer()
    end
    if opts.before then
        opts.before()
    end
    local addon = {}
    for _, file in ipairs(FILES) do
        local chunk = assert(loadstring(SOURCES[file], "@" .. file))
        setfenv(chunk, ADDON_ENV)
        chunk("VanillaRangedSwingZone", addon)
    end
    M.Fire("ADDON_LOADED", "VanillaRangedSwingZone")
    M.Fire("PLAYER_LOGIN")
    return addon
end

local function Slash(text)
    SlashCmdList.VANILLARANGEDSWINGZONE(text)
end

local function NoErrors(context)
    eq(#M.errors, 0, context .. ": no Lua errors" .. (M.errors[1] and (" (" .. M.errors[1] .. ")") or ""))
end

-- The frames of a kind, or of a kind and template.
local function Frames(kind, template)
    local list = {}
    for _, f in ipairs(M.allFrames) do
        if f.kind == kind and (not template or f.template == template) then
            list[#list + 1] = f
        end
    end
    return list
end

-- Whether the addon runs something every frame.
local function Ticking()
    for _, f in ipairs(M.allFrames) do
        if f ~= M.bar and f.scripts.OnUpdate and M.Visible(f) then
            return true
        end
    end
    return false
end

local RED = "1,0.15,0.1"

-- Settings ----------------------------------------------------------------------

ns = NewSession()
eq(ns.db.windup, 0.5, "default windup: Auto Shot's half second")
eq(ns.db.r .. "," .. ns.db.g .. "," .. ns.db.b, RED, "default color: red")
eq(ns.db.zone, true, "the zone is colored by default")
eq(ns.db.zoneAlpha, 0.4, "default zone opacity")
eq(ns.db.version, 1, "settings version")
eq(VanillaRangedSwingZoneDB, ns.db, "the settings are the saved variable")
NoErrors("first login")

ns = NewSession({ saved = { windup = "slow", r = 5, g = -1, b = 0 / 0, zone = "yes", zoneAlpha = true, extra = true } })
eq(ns.db.windup, 0.5, "a windup that is not a number goes back to the default")
eq(ns.db.r, 1, "a color above 1 is clamped")
eq(ns.db.g, 0, "a color below 0 is clamped")
eq(ns.db.b, 0.1, "a NaN color goes back to the default")
eq(ns.db.zone, true, "a zone setting that is not a boolean goes back to the default")
eq(ns.db.zoneAlpha, 0.4, "a zone opacity that is not a number goes back to the default")

ns = NewSession({ saved = { zone = false, zoneAlpha = 0.72 } })
eq(ns.db.zone, false, "a zone turned off stays off")
eq(ns.db.zoneAlpha, 0.7, "the zone opacity snaps to the slider")

for _, case in ipairs({ { 0.73, 0.75 }, { 3, 1.5 }, { 0.01, 0.1 }, { 0.62, 0.6 } }) do
    ns = NewSession({ saved = { windup = case[1] } })
    eq(ns.db.windup, case[2], "a saved windup of " .. case[1] .. " snaps to the slider")
end
for _, case in ipairs({ { 5, 1 }, { 0, 0.1 }, { 0.43, 0.45 } }) do
    ns = NewSession({ saved = { zoneAlpha = case[1] } })
    eq(ns.db.zoneAlpha, case[2], "a saved zone opacity of " .. case[1] .. " snaps to the slider")
end

-- Coloring the fill ---------------------------------------------------------

ns = NewSession()
eq(M.FillLook(), "plain", "the fill keeps its colors before any shot")
check(not Ticking(), "nothing runs every frame while the bar is empty")

M.Shoot(3)
eq(M.FillLook(), "plain", "a new swing starts with the fill's own colors")
check(Ticking(), "the swing is timed while it runs")
M.Advance(2.4)
eq(M.FillLook(), "plain", "0.6 s before the shot the fill is plain")
M.Advance(0.12)
eq(M.FillLook(), RED, "under 0.5 s before the shot the fill is red")
check(M.bar.swingDuration ~= nil, "the bar is still running")
M.Advance(0.5)
eq(M.bar.swingDuration, nil, "Blizzard emptied the bar when the time was up")
eq(M.FillLook(), "plain", "the empty bar goes back to plain")
check(not Ticking(), "the timing stops with the bar")

-- A shot that comes in while the fill is red starts plain again.
M.Shoot(2.8)
M.Advance(2.4)
eq(M.FillLook(), RED, "red near the end of a 2.8 s swing")
M.Shoot(2.8)
eq(M.FillLook(), "plain", "the next shot's swing starts plain")
M.Advance(2.25)
eq(M.FillLook(), "plain", "0.55 s before the next shot: plain")
M.Advance(0.1)
eq(M.FillLook(), RED, "0.45 s before the next shot: red")

-- Blizzard ignores a missing or non-positive duration, and so does the addon.
M.Shoot(3)
M.Advance(1)
M.Shoot(0)
M.Shoot(nil)
M.Shoot(-1)
eq(M.bar.swingDuration, 3, "Blizzard kept its swing")
M.Advance(1.55)
eq(M.FillLook(), RED, "the swing still turns red on time after ignored durations")

-- Hiding the bar empties it.
M.bar:Hide()
eq(M.FillLook(), "plain", "a bar that hides goes back to plain")
check(not Ticking(), "and the timing stops")
M.bar:Show()

-- A swing shorter than the windup is red all along.
ns.db.windup = 1.5
ns.SettingsChanged()
M.Shoot(1.2)
eq(M.FillLook(), RED, "a swing shorter than the windup is red from the start")
ns.db.windup = 0.5
ns.SettingsChanged()
eq(M.FillLook(), "plain", "with the windup back to 0.5, 1.2 s before the shot is plain")
M.Advance(0.75)
eq(M.FillLook(), RED, "and turns red 0.45 s before it")
M.Advance(1)

-- A duration the addon may not read leaves the fill plain.
M.Shoot(3)
M.Advance(2.7)
eq(M.FillLook(), RED, "red before a secret swing")
M.Shoot(SECRET)
eq(M.FillLook(), "plain", "a secret duration leaves the fill plain")
check(not Ticking(), "and nothing is timed")
M.Advance(3)
eq(M.FillLook(), "plain", "still plain later")
NoErrors("secret duration")

-- The zone ------------------------------------------------------------------
-- The bar is 200 px wide and the ranged weapon's speed 3 s, unless changed.

local ZONE = " " .. RED .. " 0.4"
ns = NewSession()
eq(M.ZoneLook(), "33.3" .. ZONE, "at login the zone is the windup's share of the weapon's speed")
local zone = M.bar.StatusBar.regions[1]
local fillLayer, fillSublevel = M.bar.StatusBar.fill:GetDrawLayer()
eq(zone.layer .. " " .. zone.sublevel, fillLayer .. " " .. (fillSublevel - 1), "the zone is drawn just under the fill")
check(zone.points[1][1] == "TOPRIGHT" and zone.points[2][1] == "BOTTOMRIGHT" and #zone.points == 2,
    "the zone sits at the right end of the bar, its full height")
check(not Ticking(), "the zone alone runs nothing every frame")

M.Shoot(2)
eq(M.ZoneLook(), "50.0" .. ZONE, "during a 2 s swing the zone is a quarter of the bar")
M.speeds[3] = 2.5
M.Fire("UNIT_ATTACK_SPEED", "player")
eq(M.ZoneLook(), "50.0" .. ZONE, "a new speed leaves the running swing's zone alone, as Blizzard's bar")
M.Advance(2.1)
eq(M.ZoneLook(), "40.0" .. ZONE, "once the bar empties, the zone follows the new speed")
M.speeds[3] = 2
M.Fire("UNIT_ATTACK_SPEED", "player")
eq(M.ZoneLook(), "50.0" .. ZONE, "a new speed while the bar is empty resizes the zone")

M.ResizeBar(300)
eq(M.ZoneLook(), "75.0" .. ZONE, "Edit Mode's width resizes the zone")
M.Shoot(3)
eq(M.ZoneLook(), "50.0" .. ZONE, "a 3 s swing on the wider bar")
M.Advance(3.1)

ns.db.windup = 1.5
ns.SettingsChanged()
M.Shoot(1.2)
eq(M.ZoneLook(), "300.0" .. ZONE, "a swing shorter than the windup is all zone")
ns.db.windup = 0.5
ns.SettingsChanged()
eq(M.ZoneLook(), "125.0" .. ZONE, "a shorter windup narrows the zone at once")
M.Advance(2)

-- The bar shows again (in combat, in Edit Mode): the zone is laid out anew.
M.bar:Hide()
M.speeds[3] = 1.5
M.bar:Show()
eq(M.ZoneLook(), "100.0" .. ZONE, "a bar that shows again gets a zone for the current speed")

-- Without a ranged weapon there is no speed, and no zone.
M.speeds[3] = 0
M.Fire("UNIT_INVENTORY_CHANGED", "player")
eq(M.ZoneLook(), "hidden", "no ranged weapon: no zone")
M.speeds[3] = 3
M.Fire("UNIT_INVENTORY_CHANGED", "player")
eq(M.ZoneLook(), "50.0" .. ZONE, "a ranged weapon again: the zone is back")

-- What the addon may not read.
M.speeds[3] = SECRET
M.Fire("UNIT_ATTACK_SPEED", "player")
eq(M.ZoneLook(), "hidden", "a secret speed: no zone while the bar is empty")
M.Shoot(2)
eq(M.ZoneLook(), "75.0" .. ZONE, "a readable swing shows it all the same")
M.Shoot(SECRET)
eq(M.ZoneLook(), "hidden", "a secret swing with a secret speed: no zone")
M.Advance(3)
M.speeds[3] = 3
M.bar.StatusBar.w = SECRET
M.Fire("UNIT_ATTACK_SPEED", "player")
eq(M.ZoneLook(), "hidden", "a secret width: no zone")
M.ResizeBar(200)
eq(M.ZoneLook(), "33.3" .. ZONE, "a readable width again: the zone is back")
NoErrors("zone")

-- The zone goes under the fill wherever Blizzard draws it.
ns = NewSession({ fillLayer = "ARTWORK", fillSublevel = -8 })
zone = M.bar.StatusBar.regions[1]
eq(zone.layer .. " " .. zone.sublevel, "BORDER 7", "under a fill at the bottom of its layer, the zone takes the layer below")
ns = NewSession({ fillLayer = "BACKGROUND", fillSublevel = -8 })
zone = M.bar.StatusBar.regions[1]
eq(zone.layer .. " " .. zone.sublevel, "BACKGROUND -8", "nothing is below the lowest layer: the zone shares it")
NoErrors("fill layers")

-- The bar loads after login --------------------------------------------------

ns = NewSession({ lateBar = true })
NoErrors("login without the swing bar")
M.LoadSwingTimer(true)
eq(M.ZoneLook(), "33.3 " .. RED .. " 0.4", "a bar that loads after login gets its zone")
M.Shoot(3)
M.Advance(2.55)
eq(M.FillLook(), RED, "a bar that loads after login is colored too")
M.Fire("ADDON_LOADED", "Blizzard_SwingTimer")
M.Advance(1)
eq(M.FillLook(), "plain", "a second ADDON_LOADED does not hook the bar twice")
NoErrors("late bar")

-- A swing already running when the bar is found is followed.
ns = NewSession({ lateBar = true })
M.LoadSwingTimer()
M.Shoot(3)
M.Fire("ADDON_LOADED", "Blizzard_SwingTimer")
M.Advance(2.4)
eq(M.FillLook(), "plain", "a swing under way: plain 0.6 s before the shot")
M.Advance(0.15)
eq(M.FillLook(), RED, "and red 0.45 s before it")
M.Advance(1)
eq(M.FillLook(), "plain", "and plain once the bar empties")

-- A secret swing under way is left alone.
ns = NewSession({ before = function() M.Shoot(SECRET) end })
eq(M.FillLook(), "plain", "a secret swing under way at login is left plain")
check(not Ticking(), "and not timed")
NoErrors("secret swing at login")

-- The options page ----------------------------------------------------------

ns = NewSession()
eq(M.registered and M.registered.name, "Vanilla Ranged Swing Zone", "the page is under Options > AddOns")
local page = M.category.frame

-- The page's font string whose text holds the given text.
local function PageText(text)
    for _, region in ipairs(page.regions) do
        if region.kind == "FontString" and region.textValue and region.textValue:find(text, 1, true) then
            return region
        end
    end
end
eq(PageText("Vanilla Ranged Swing Zone") and PageText("Vanilla Ranged Swing Zone").textValue,
    "Vanilla Ranged Swing Zone", "the page's heading")
check(PageText("Auto Shot only fires while you stand still.") ~= nil, "the intro names Auto Shot")
check(PageText("the fill of the \"Ranged\" bar changes color") ~= nil, "the intro names Blizzard's Ranged bar")

-- Blizzard's own text for a swing timer turned off shows only while it is off.
local warning = PageText(HUD_EDIT_MODE_SWING_TIMER_DISABLED_TOOLTIP)
check(warning ~= nil, "the page holds Blizzard's warning")
check(not warning.shown, "no warning while the swing timer is on")
M.cvars.showSwingTimer = false
page:OnRefresh()
check(warning.shown, "the warning shows when the page opens with the swing timer off")
M.cvars.showSwingTimer = nil
page:OnRefresh()
check(not warning.shown, "no warning when the client has no such setting")
M.cvars.showSwingTimer = true
page:OnRefresh()
check(not warning.shown, "the warning goes when the swing timer is back on")

-- The slider and its labels.
local slider = Frames("Slider", "UISliderTemplateWithLabels")[1]
check(slider ~= nil, "a slider for the windup")
eq(slider.value, 0.5, "the slider shows the setting")
eq(slider.Text.textValue, "Seconds before the shot: |cffffffff0.50 s|r", "the slider's label")
eq(slider.Low.textValue, "0.10 s", "the slider's low end")
eq(slider.High.textValue, "1.50 s", "the slider's high end")
slider.scripts.OnEnter(slider)
check(GameTooltip.lines[2]:find("Auto Shot aims for the last half second", 1, true) ~= nil,
    "the slider's tooltip names Auto Shot")
slider.scripts.OnLeave(slider)
check(not GameTooltip.shown, "the tooltip hides")

slider:SetValue(0.8, true)
eq(ns.db.windup, 0.8, "dragging the slider sets the windup")
slider:SetValue(0.83, true)
eq(ns.db.windup, 0.85, "the slider snaps to 0.05 s")
slider.scripts.OnMouseWheel(slider, -1)
eq(ns.db.windup, 0.8, "the mouse wheel steps it down")
slider.scripts.OnMouseWheel(slider, 1)
slider.scripts.OnMouseWheel(slider, 1)
eq(ns.db.windup, 0.9, "and up")
for _ = 1, 20 do slider.scripts.OnMouseWheel(slider, 1) end
eq(ns.db.windup, 1.5, "not past the top")

-- The windup changes in the middle of a swing.
slider:SetValue(0.5, true)
M.Shoot(3)
M.Advance(2.2)
eq(M.FillLook(), "plain", "0.8 s before the shot with a 0.5 s windup: plain")
slider:SetValue(1, true)
eq(M.FillLook(), RED, "raising the windup to 1 s turns it red at once")
slider:SetValue(0.5, true)
eq(M.FillLook(), "plain", "lowering it back turns it plain at once")

-- The color swatch and Blizzard's color picker.
local swatchButton
for _, f in ipairs(Frames("Button")) do
    if f.parent == page and not f.template then
        swatchButton = f
    end
end
check(swatchButton ~= nil, "a color swatch")
M.Advance(0.4)
eq(M.FillLook(), RED, "red again near the shot")
swatchButton:Click()
check(ColorPickerFrame.shown, "the swatch opens the color picker")
eq(table.concat(ColorPickerFrame.color, ","), RED, "the picker starts on the setting")
M.Pick(0.2, 0.4, 1)
eq(ns.db.r .. "," .. ns.db.g .. "," .. ns.db.b, "0.2,0.4,1", "picking a color sets it")
eq(M.FillLook(), "0.2,0.4,1", "the red fill follows the picked color live")
M.CancelPick()
eq(ns.db.r .. "," .. ns.db.g .. "," .. ns.db.b, RED, "Cancel puts the old color back")
eq(M.FillLook(), RED, "and so does the fill")
M.Advance(1)
eq(M.FillLook(), "plain", "the fill goes plain when the bar empties")

swatchButton:Click()
M.Pick(0, 1, 0)
eq(M.ZoneLook(), "33.3 0,1,0 0.4", "the zone takes the picked color too")
M.Shoot(2)
M.Advance(1.6)
eq(M.FillLook(), "0,1,0", "the next swing turns the picked color")
M.Advance(1)

-- The zone's checkbox and opacity.
local zoneBox = Frames("CheckButton", "UICheckButtonTemplate")[1]
eq(zoneBox.Text.textValue, "Color the zone", "the zone's checkbox")
eq(zoneBox.checked, true, "checked, as the setting")
zoneBox.scripts.OnEnter(zoneBox)
check(GameTooltip.lines[2]:find("so you see the moment coming", 1, true) ~= nil, "the checkbox explains the zone")
zoneBox:Click()
eq(ns.db.zone, false, "unchecking it turns the zone off")
eq(M.ZoneLook(), "hidden", "and hides it")
M.Shoot(2)
M.Advance(1.6)
eq(M.FillLook(), "0,1,0", "without the zone the fill still changes color")
M.Advance(1)
zoneBox:Click()
eq(ns.db.zone, true, "checking it turns the zone on")
eq(M.ZoneLook(), "33.3 0,1,0 0.4", "and shows it")

local opacity = Frames("Slider", "UISliderTemplateWithLabels")[2]
eq(opacity.Text.textValue, "Zone opacity: |cffffffff40%|r", "the opacity slider's label")
eq(opacity.Low.textValue, "10%", "its low end")
eq(opacity.High.textValue, "100%", "its high end")
opacity:SetValue(0.7, true)
eq(ns.db.zoneAlpha, 0.7, "dragging it sets the opacity")
eq(M.ZoneLook(), "33.3 0,1,0 0.7", "and the zone follows")
opacity.scripts.OnMouseWheel(opacity, 1)
eq(ns.db.zoneAlpha, 0.75, "the mouse wheel steps it by 5%")
opacity.scripts.OnEnter(opacity)
eq(#GameTooltip.lines, 1, "the opacity slider's tooltip is its name alone")

-- The Defaults button.
local defaults = Frames("Button", "UIPanelButtonTemplate")[1]
eq(defaults.textValue, "Defaults", "the Defaults button uses Blizzard's word")
slider:SetValue(1.2, true)
zoneBox:Click()
defaults:Click()
eq(ns.db.windup, 0.5, "Defaults puts the windup back")
eq(ns.db.r .. "," .. ns.db.g .. "," .. ns.db.b, RED, "and the color")
eq(ns.db.zone, true, "and the zone")
eq(ns.db.zoneAlpha, 0.4, "and its opacity")
eq(slider.value, 0.5, "and the slider shows it")
eq(zoneBox.checked, true, "and the checkbox")
eq(opacity.value, 0.4, "and the opacity slider")
eq(M.ZoneLook(), "33.3" .. ZONE, "and the zone looks as at first")
NoErrors("options page")

-- Slash commands ------------------------------------------------------------

-- /vrsz opens the page, which shows the warning if the swing timer is off.
ns = NewSession()
M.cvars.showSwingTimer = false
Slash("")
page = M.category.frame
check(SettingsPanel:IsShown(), "/vrsz opens the settings panel")
check(PageText(HUD_EDIT_MODE_SWING_TIMER_DISABLED_TOOLTIP).shown, "opened with the swing timer off, it warns")
M.Advance(0.5)
eq(#M.printed, 0, "and prints nothing when it opened")

ns = NewSession()
M.openBlocked = true
Slash("")
M.Advance(0.5)
eq(M.printed[1], "|cffabd473Vanilla Ranged Swing Zone|r: open the game menu, then Options > AddOns > Vanilla Ranged Swing Zone.",
    "when the panel cannot open, it says where the page is")
M.printed = {}
Slash("help")
eq(#M.printed, 2, "help lists two commands")
eq(M.printed[1], "|cffabd473Vanilla Ranged Swing Zone|r: /vrsz - open the options", "the first command")
M.printed = {}
ns.db.windup = 1
ns.db.r = 0
Slash("  RESET ")
eq(ns.db.windup, 0.5, "/vrsz reset puts the windup back")
eq(ns.db.r, 1, "and the color")
eq(M.printed[1], "|cffabd473Vanilla Ranged Swing Zone|r: settings reset to the defaults.", "and says so")
NoErrors("slash commands")

-- Languages -------------------------------------------------------------------

local LOCALES = { "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }

-- The placeholders of a text, in order.
local function Placeholders(text)
    local list = {}
    for p in text:gmatch("%%[%d%.]*[sdf]") do
        list[#list + 1] = p
    end
    return table.concat(list, " ")
end

for _, locale in ipairs(LOCALES) do
    local file = "Locales/" .. locale .. ".lua"
    check(SOURCES[file] ~= nil, locale .. " is in the TOC")
    -- What the file sets, when the client runs in its language.
    local texts = {}
    local chunk = assert(loadstring(SOURCES[file], "@" .. file))
    chunk("VanillaRangedSwingZone", { LOCALE = locale, L = texts })
    local count = 0
    for key, text in pairs(texts) do
        count = count + 1
        eq(Placeholders(text), Placeholders(key), locale .. ": same placeholders in " .. key)
        check(text ~= "", locale .. ": " .. key .. " is translated")
    end
    for _, key in ipairs(KEYS) do
        check(texts[key] ~= nil, locale .. " translates " .. key)
    end
    eq(count, #KEYS, locale .. " has no text the code does not use")
    -- In another language it sets nothing.
    local other = {}
    chunk("VanillaRangedSwingZone", { LOCALE = "enUS", L = other })
    check(next(other) == nil, locale .. " sets nothing in English")
    check(SOURCES["VanillaRangedSwingZone.toc"]:find("\n## Notes%-" .. locale .. ": ") ~= nil, locale .. " has TOC notes")

    -- The whole addon runs in that language.
    ns = NewSession({ locale = locale })
    Slash("help")
    M.Shoot(3)
    M.Advance(2.6)
    eq(M.FillLook(), RED, locale .. ": the fill turns red")
    local s = Frames("Slider", "UISliderTemplateWithLabels")[1]
    check(s.Text.textValue:find(texts["Seconds before the shot"], 1, true) ~= nil, locale .. ": the slider is translated")
    NoErrors(locale)
end
ns = NewSession({ locale = "enGB" })
eq(ns.LOCALE, "enUS", "enGB uses the English texts")
ns = NewSession({ locale = "ptPT" })
eq(ns.LOCALE, "ptBR", "ptPT uses the Brazilian texts")
eq(ns.L["Fill color"], "Cor do preenchimento", "ptPT reads the Brazilian file")

-- Release files -------------------------------------------------------------

local tocVersion = SOURCES["VanillaRangedSwingZone.toc"]:match("\n## Version: (%S+)")
check(tocVersion ~= nil, "the TOC has a version")
eq(SOURCES["CHANGELOG.md"]:match("\n## ([%d%.]+)"), tocVersion, "the changelog's newest entry matches the TOC version")
eq(SOURCES["VanillaRangedSwingZone.toc"]:match("## SavedVariables: (%S+)"), "VanillaRangedSwingZoneDB", "the saved variable")
eq(SOURCES[".pkgmeta"]:match("package%-as: (%S+)"), "VanillaRangedSwingZone", "packaged under the TOC's folder name")
check(SOURCES[".pkgmeta"]:find("\nignore:\n    %- Tests\n") ~= nil, "the tests are left out of the package")

eq(#leaks, 0, "no leaked globals: " .. table.concat(leaks, ", "))

print_real(("%d passed, %d failed"):format(passes, failures))
return failures
