-- Options.lua: the settings page under Options > AddOns > Vanilla Ranged Swing Zone.
local _, ns = ...
local L = ns.L

local Options = {}
ns.Options = Options

local AUTO_SHOT = 75   -- the spell, for its name in the client's language

local refreshers = {}   -- functions that copy the settings into the widgets
local category

function Options.Refresh()
    for _, refresh in ipairs(refreshers) do
        refresh()
    end
end

local function SetTooltip(widget, title, text)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        if text then
            GameTooltip:AddLine(text, 1, 0.82, 0, true)
        end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function AutoShotName()
    local name = C_Spell and C_Spell.GetSpellName and ns.Plain(C_Spell.GetSpellName(AUTO_SHOT))
    return type(name) == "string" and name ~= "" and name or "Auto Shot"
end

-- Widgets ---------------------------------------------------------------------

local function Seconds(value)
    return L["%.2f s"]:format(value)
end

local function Percent(value)
    return L["%d%%"]:format(math.floor(value * 100 + 0.5))
end

-- A checkbox bound to a boolean setting.
local function CreateOption(page, x, y, key, label, tooltip)
    local box = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
    box:SetSize(24, 24)
    box:SetPoint("TOPLEFT", x, y)
    box.Text:SetFontObject("GameFontHighlight")
    box.Text:SetText(label)
    -- Clicking the label toggles the box too.
    box:SetHitRectInsets(0, -(box.Text:GetStringWidth() + 4), 0, 0)
    box:SetScript("OnClick", function(self)
        ns.db[key] = self:GetChecked() and true or false
        ns.SettingsChanged()
    end)
    SetTooltip(box, label, tooltip)
    refreshers[#refreshers + 1] = function()
        box:SetChecked(ns.db[key])
    end
end

-- A slider bound to a numeric setting; format writes its values.
local function CreateSlider(page, x, y, width, key, label, tooltip, format)
    local low, high, step = unpack(ns.LIMITS[key])
    local slider = CreateFrame("Slider", nil, page, "UISliderTemplateWithLabels")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetSize(width, 17)
    slider:SetMinMaxValues(low, high)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.Low:SetText(format(low))
    slider.High:SetText(format(high))
    local function ShowValue(value)
        slider.Text:SetText(("%s: |cffffffff%s|r"):format(label, format(value)))
    end
    local function Set(value)
        ns.db[key] = value
        ns.SettingsChanged()
    end
    slider:SetScript("OnValueChanged", function(_, value, userInput)
        value = ns.Snap(value, low, high, step)
        ShowValue(value)
        if userInput and value ~= ns.db[key] then
            Set(value)
        end
    end)
    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function(self, delta)
        local value = ns.Snap(ns.db[key] + delta * step, low, high, step)
        if value ~= ns.db[key] then
            self:SetValue(value)
            Set(value)
        end
    end)
    SetTooltip(slider, label, tooltip)
    refreshers[#refreshers + 1] = function()
        slider:SetValue(ns.db[key])
        ShowValue(ns.db[key])
    end
end

-- A square of the fill color; clicking it opens Blizzard's color picker.
local function CreateColorSwatch(page, x, y, label)
    local button = CreateFrame("Button", nil, page)
    button:SetSize(22, 22)
    button:SetPoint("TOPLEFT", x, y)
    local border = button:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(1, 1, 1, 0.8)
    local swatch = button:CreateTexture(nil, "ARTWORK")
    swatch:SetPoint("TOPLEFT", 2, -2)
    swatch:SetPoint("BOTTOMRIGHT", -2, 2)
    local text = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("LEFT", button, "RIGHT", 8, 0)
    text:SetText(label)
    -- Clicking the label opens the picker too.
    button:SetHitRectInsets(0, -(text:GetStringWidth() + 8), 0, 0)

    local function Refresh()
        swatch:SetColorTexture(ns.db.r, ns.db.g, ns.db.b)
    end
    local function Set(r, g, b)
        ns.db.r, ns.db.g, ns.db.b = r, g, b
        ns.SettingsChanged()
        Refresh()
    end
    button:SetScript("OnClick", function()
        if not ColorPickerFrame then
            return
        end
        ColorPickerFrame:SetupColorPickerAndShow({
            r = ns.db.r, g = ns.db.g, b = ns.db.b,
            hasOpacity = false,
            -- Called as the color is picked, so the bar follows it live.
            swatchFunc = function()
                Set(ColorPickerFrame:GetColorRGB())
            end,
            cancelFunc = function(previous)
                Set(previous.r, previous.g, previous.b)
            end,
        })
    end)
    refreshers[#refreshers + 1] = Refresh
end

-- The page ------------------------------------------------------------------

local function CreatePage()
    local page = CreateFrame("Frame")
    page:Hide()

    local heading = page:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 16, -16)
    heading:SetText("Vanilla Ranged Swing Zone")
    local autoShot = AutoShotName()
    local intro = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -8)
    intro:SetWidth(620)
    intro:SetJustifyH("LEFT")
    intro:SetText(L["%s only fires while you stand still."]:format(autoShot) .. " "
        .. L["In the last moments before each shot, the fill of the \"%s\" bar changes color: stop moving then."]
            :format(SWING_TIMER_RANGED or "Ranged"))

    -- Blizzard's own words for a swing timer turned off, and where to turn it on.
    local disabled = page:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    disabled:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -10)
    disabled:SetWidth(620)
    disabled:SetJustifyH("LEFT")
    disabled:SetTextColor(1, 0.2, 0.2)
    disabled:SetText(HUD_EDIT_MODE_SWING_TIMER_DISABLED_TOOLTIP or "")
    refreshers[#refreshers + 1] = function()
        local on = C_CVar and C_CVar.GetCVarBool and C_CVar.GetCVarBool("showSwingTimer")
        disabled:SetShown(on == false and HUD_EDIT_MODE_SWING_TIMER_DISABLED_TOOLTIP ~= nil)
    end

    CreateSlider(page, 24, -140, 260, "windup", L["Seconds before the shot"],
        L["How long before each shot the fill changes color. %s aims for the last half second; raise it a little if your shots still wait after you stop."]:format(autoShot),
        Seconds)
    CreateColorSwatch(page, 20, -186, L["Fill color"])
    CreateOption(page, 16, -220, "zone", L["Color the zone"],
        L["Tints the end of the bar, where the fill changes color, so you see the moment coming before it arrives."])
    CreateSlider(page, 24, -270, 260, "zoneAlpha", L["Zone opacity"], nil, Percent)

    local defaults = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    defaults:SetHeight(22)
    defaults:SetText(DEFAULTS or "Defaults")
    defaults:SetWidth(math.max(120, math.ceil(defaults:GetFontString():GetStringWidth()) + 24))
    defaults:SetPoint("TOPLEFT", 20, -312)
    defaults:SetScript("OnClick", function()
        ns.ResetSettings()
    end)

    -- Called by the settings panel whenever it shows the page.
    function page:OnRefresh()
        Options.Refresh()
    end
    return page
end

-- Setup -----------------------------------------------------------------------

function Options.Init()
    category = Settings.RegisterCanvasLayoutCategory(CreatePage(), "Vanilla Ranged Swing Zone")
    Settings.RegisterAddOnCategory(category)
    Options.Refresh()
end

function Options.Open()
    -- Settings.OpenToCategory goes through a restricted call on this client, and
    -- the panel opens from an event, so success is checked a moment later.
    local ok = category and pcall(Settings.OpenToCategory, category:GetID())
    C_Timer.After(0.3, function()
        if not ok or not SettingsPanel:IsShown() then
            ns.Print(L["open the game menu, then Options > AddOns > Vanilla Ranged Swing Zone."])
        end
    end)
end
