-- Deutsch
local _, ns = ...
if ns.LOCALE ~= "deDE" then
    return
end
local L = ns.L

-- Chat
L["settings reset to the defaults."] = "Einstellungen auf die Standardwerte zurückgesetzt."
L["/vrsz - open the options"] = "/vrsz - Optionen öffnen"
L["/vrsz reset - restore the default settings"] = "/vrsz reset - die Standardeinstellungen wiederherstellen"
L["open the game menu, then Options > AddOns > Vanilla Ranged Swing Zone."] = "öffne das Spielmenü, dann Optionen > Addons > Vanilla Ranged Swing Zone."

-- Options
L["%s only fires while you stand still."] = "%s schießt nur, solange du stillstehst."
L["In the last moments before each shot, the fill of the \"%s\" bar changes color: stop moving then."] = "In den letzten Augenblicken vor jedem Schuss ändert die Füllung der Leiste „%s“ ihre Farbe: Bleib dann stehen."
L["Seconds before the shot"] = "Sekunden vor dem Schuss"
L["How long before each shot the fill changes color. %s aims for the last half second; raise it a little if your shots still wait after you stop."] = "Wie lange vor jedem Schuss die Füllung ihre Farbe ändert. %s zielt in der letzten halben Sekunde; erhöhe den Wert etwas, wenn deine Schüsse nach dem Anhalten noch warten."
L["%.2f s"] = "%.2f s"
L["Fill color"] = "Füllfarbe"
L["Color the zone"] = "Zone einfärben"
L["Tints the end of the bar, where the fill changes color, so you see the moment coming before it arrives."] = "Färbt das Ende der Leiste, wo die Füllung ihre Farbe ändert, damit du den Moment kommen siehst, bevor er da ist."
L["Zone opacity"] = "Deckkraft der Zone"
L["%d%%"] = "%d %%"
