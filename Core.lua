-- Vanilla Ranged Swing Zone: on Blizzard's own swing timer, the ranged bar's
-- fill changes color for the last moments before each shot, when Auto Shot
-- needs you to stand still.
-- Core.lua holds the settings, the shared helpers, the startup and the slash
-- commands.
local ADDON_NAME, ns = ...
local L = ns.L

-- WoW Forever runs the Midnight addon API, where some results are "secret":
-- using one in a condition, or even comparing it with nil, raises an error.
-- Anything that might be secret goes through Plain() before it is looked at.
local issecretvalue = issecretvalue or function() return false end
ns.IsSecret = issecretvalue

function ns.Plain(value)
    if issecretvalue(value) then
        return nil
    end
    return value
end

function ns.Print(message)
    print("|cffabd473Vanilla Ranged Swing Zone|r: " .. message)
end

-- RegisterEvent raises for an event this client does not have, which would
-- abort the rest of the file, so every registration is wrapped.
function ns.RegisterEvents(frame, ...)
    for i = 1, select("#", ...) do
        pcall(frame.RegisterEvent, frame, (select(i, ...)))
    end
end

-- Settings -----------------------------------------------------------------

ns.DEFAULTS = {
    version = 1,
    windup = 0.5,           -- seconds before each shot when the fill changes color
    r = 1, g = 0.15, b = 0.1, -- the color it takes then
    zone = true,            -- the end of the bar shows that stretch, in the same color
    zoneAlpha = 0.4,        -- how opaque that zone is
}

-- Minimum, maximum and step of the numeric settings. Auto Shot aims for the
-- last half second of the ranged swing in vanilla.
ns.LIMITS = {
    windup = { 0.1, 1.5, 0.05 },
    zoneAlpha = { 0.1, 1, 0.05 },
}

local COLOR_KEYS = { r = true, g = true, b = true }

local function Clamp(value, low, high)
    return math.min(math.max(value, low), high)
end

-- Rounds value to the nearest step inside [low, high].
function ns.Snap(value, low, high, step)
    value = low + math.floor((value - low) / step + 0.5) * step
    return Clamp(math.floor(value * 100 + 0.5) / 100, low, high)
end

local function IsNumber(value)
    -- NaN is the one number not equal to itself.
    return type(value) == "number" and value == value
end

-- Replaces missing or invalid values with the defaults. Runs on the saved
-- settings.
function ns.Sanitize(db)
    for key, default in pairs(ns.DEFAULTS) do
        local value, limits = db[key], ns.LIMITS[key]
        if type(default) == "boolean" then
            if type(value) ~= "boolean" then
                db[key] = default
            end
        elseif not IsNumber(value) then
            db[key] = default
        elseif limits then
            db[key] = ns.Snap(value, limits[1], limits[2], limits[3])
        elseif COLOR_KEYS[key] then
            db[key] = Clamp(value, 0, 1)
        end
    end
    db.version = ns.DEFAULTS.version
end

-- Every settings change ends here.
function ns.SettingsChanged()
    ns.Zone.ApplySettings()
end

function ns.ResetSettings()
    wipe(ns.db)
    for key, value in pairs(ns.DEFAULTS) do
        ns.db[key] = value
    end
    ns.SettingsChanged()
    ns.Options.Refresh()
end

-- Startup ------------------------------------------------------------------

local events = CreateFrame("Frame")
ns.RegisterEvents(events, "ADDON_LOADED", "PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == ADDON_NAME then
        self:UnregisterEvent("ADDON_LOADED")
        if type(VanillaRangedSwingZoneDB) ~= "table" then
            VanillaRangedSwingZoneDB = {}
        end
        ns.Sanitize(VanillaRangedSwingZoneDB)
        ns.db = VanillaRangedSwingZoneDB
    elseif event == "PLAYER_LOGIN" then
        -- Each part starts on its own, so a failure in one (reported as a normal
        -- Lua error) does not stop the other.
        for _, init in ipairs({ ns.Zone.Init, ns.Options.Init }) do
            xpcall(init, geterrorhandler())
        end
    end
end)

-- Slash commands -------------------------------------------------------------

SLASH_VANILLARANGEDSWINGZONE1 = "/vrsz"
SLASH_VANILLARANGEDSWINGZONE2 = "/vanillarangedswingzone"
SlashCmdList.VANILLARANGEDSWINGZONE = function(message)
    local command = strtrim(message or ""):lower()
    if command == "" or command == "options" then
        ns.Options.Open()
    elseif command == "reset" then
        ns.ResetSettings()
        ns.Print(L["settings reset to the defaults."])
    else
        ns.Print(L["/vrsz - open the options"])
        ns.Print(L["/vrsz reset - restore the default settings"])
    end
end
