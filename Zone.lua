-- Zone.lua: marks the end of the ranged swing bar, where you have to stand
-- still for the shot, and changes the color of the fill once it gets there.
--
-- The bar is Blizzard's own (Blizzard_SwingTimer, WoW Forever only):
-- SwingTimerRangedFrame, a StatusBar that fills from 0 to 1 between one shot
-- and the next. Blizzard starts it with ResetSwingTimer(duration) when a shot
-- goes off and empties it with ClearSwingTimer() when the time is up, the
-- weapon changes or the bar hides. The addon follows both with post-hooks,
-- which leave Blizzard's code untouched, and times the same swing itself.
--
-- The zone is a band at the right end of the bar, as wide as the windup is
-- of the swing, drawn under the fill: the fill covers it as it advances.
local _, ns = ...

local Zone = {}
ns.Zone = Zone

local BAR_ADDON = "Blizzard_SwingTimer"
local LAYERS = { "BACKGROUND", "BORDER", "ARTWORK", "OVERLAY" }

local bar           -- SwingTimerRangedFrame, once Blizzard_SwingTimer has loaded
local zone          -- the band at the end of the bar
local endTime       -- when the bar's current swing ends (GetTime), nil while it is empty
local swingDuration -- that swing's length, when it could be read
local tinted = false

-- Runs every frame while a swing is in progress, and only then.
local ticker = CreateFrame("Frame")
ticker:Hide()

local function StatusBar()
    return bar:GetStatusBar()
end

-- The fill keeps its own texture, without its colors, tinted with the setting.
-- Blizzard never colors it, so plain white puts it back as it was.
local function Paint()
    local fill = StatusBar():GetStatusBarTexture()
    if tinted then
        fill:SetDesaturated(true)
        fill:SetVertexColor(ns.db.r, ns.db.g, ns.db.b)
    else
        fill:SetDesaturated(false)
        fill:SetVertexColor(1, 1, 1)
    end
end

local function SetTinted(on)
    if tinted ~= on then
        tinted = on
        Paint()
    end
end

-- The ranged weapon's current speed, for the zone while no swing runs.
local function RangedSpeed()
    local _, _, speed = UnitAttackSpeed("player")
    speed = ns.Plain(speed)
    if type(speed) == "number" and speed > 0 then
        return speed
    end
end

-- Sizes and colors the zone for the running swing, or for the weapon's speed
-- while the bar is empty; hides it when either is unknown.
local function LayoutZone()
    if not zone then
        return
    end
    local duration = swingDuration or RangedSpeed()
    local width = ns.Plain(StatusBar():GetWidth())
    if not ns.db.zone or not duration or type(width) ~= "number" or width <= 0 then
        zone:Hide()
        return
    end
    zone:SetWidth(width * math.min(1, ns.db.windup / duration))
    zone:SetColorTexture(ns.db.r, ns.db.g, ns.db.b, ns.db.zoneAlpha)
    zone:Show()
end

local function Update()
    SetTinted(endTime - GetTime() <= ns.db.windup)
end
ticker:SetScript("OnUpdate", Update)

local function Stop()
    endTime, swingDuration = nil, nil
    ticker:Hide()
    SetTinted(false)
    LayoutZone()
end

local function Start(swingEnd, duration)
    endTime, swingDuration = swingEnd, duration
    ticker:Show()
    Update()
    LayoutZone()
end

-- Blizzard's ResetSwingTimer ignores a missing or non-positive duration, and
-- the bar goes on as it was; so does the addon. A duration it cannot read
-- (secret) leaves it unable to time the swing, so it stops coloring.
local function OnReset(_, duration)
    if ns.IsSecret(duration) then
        Stop()
    elseif type(duration) == "number" and duration > 0 then
        Start(GetTime() + duration, duration)
    end
end

-- The layer just under the fill's, so the fill covers the zone.
local function LayerBelow(texture)
    local layer, sublevel = texture:GetDrawLayer()
    sublevel = sublevel or 0
    if sublevel > -8 then
        return layer, sublevel - 1
    end
    for i = 2, #LAYERS do
        if LAYERS[i] == layer then
            return LAYERS[i - 1], 7
        end
    end
    return layer, sublevel
end

local function CreateZone()
    local statusBar = StatusBar()
    local layer, sublevel = LayerBelow(statusBar:GetStatusBarTexture())
    zone = statusBar:CreateTexture(nil, layer, nil, sublevel)
    zone:SetPoint("TOPRIGHT")
    zone:SetPoint("BOTTOMRIGHT")
    zone:Hide()
    -- Edit Mode resizes the bar; the speed may change while it is empty.
    statusBar:HookScript("OnSizeChanged", LayoutZone)
    bar:HookScript("OnShow", LayoutZone)
    local events = CreateFrame("Frame")
    for _, event in ipairs({ "UNIT_ATTACK_SPEED", "UNIT_INVENTORY_CHANGED" }) do
        pcall(events.RegisterUnitEvent, events, event, "player")
    end
    events:SetScript("OnEvent", LayoutZone)
end

-- Returns whether the bar was found.
local function Attach()
    if bar then
        return true
    end
    if not SwingTimerRangedFrame then
        return false
    end
    bar = SwingTimerRangedFrame
    hooksecurefunc(bar, "ResetSwingTimer", OnReset)
    hooksecurefunc(bar, "ClearSwingTimer", Stop)
    CreateZone()
    -- A swing already under way, should the bar have loaded first.
    local swingEnd, duration = ns.Plain(bar.swingEndTime), ns.Plain(bar.swingDuration)
    if type(swingEnd) == "number" then
        Start(swingEnd, type(duration) == "number" and duration or nil)
    else
        LayoutZone()
    end
    return true
end

function Zone.Init()
    if Attach() then
        return
    end
    -- Blizzard_SwingTimer loads with the interface on Forever; this covers it
    -- loading later.
    local loader = CreateFrame("Frame")
    ns.RegisterEvents(loader, "ADDON_LOADED")
    loader:SetScript("OnEvent", function(self, _, name)
        if name == BAR_ADDON and Attach() then
            self:UnregisterAllEvents()
        end
    end)
end

-- The windup, the color or the zone changed.
function Zone.ApplySettings()
    if not bar then
        return
    end
    if endTime then
        Update()
    end
    if tinted then
        Paint()
    end
    LayoutZone()
end
