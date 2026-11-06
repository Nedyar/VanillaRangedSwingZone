-- Español (EU)
local _, ns = ...
if ns.LOCALE ~= "esES" then
    return
end
local L = ns.L

-- Chat
L["settings reset to the defaults."] = "ajustes restablecidos a los valores predeterminados."
L["/vrsz - open the options"] = "/vrsz - abrir las opciones"
L["/vrsz reset - restore the default settings"] = "/vrsz reset - restablecer los ajustes predeterminados"
L["open the game menu, then Options > AddOns > Vanilla Ranged Swing Zone."] = "abre el menú de juego y luego Opciones > Addons > Vanilla Ranged Swing Zone."

-- Options
L["%s only fires while you stand still."] = "%s solo dispara mientras estás quieto."
L["In the last moments before each shot, the fill of the \"%s\" bar changes color: stop moving then."] = "En los últimos instantes antes de cada disparo, el relleno de la barra «%s» cambia de color: deja de moverte entonces."
L["Seconds before the shot"] = "Segundos antes del disparo"
L["How long before each shot the fill changes color. %s aims for the last half second; raise it a little if your shots still wait after you stop."] = "Cuánto antes de cada disparo cambia de color el relleno. %s apunta durante el último medio segundo; súbelo un poco si tus disparos siguen esperando cuando te paras."
L["%.2f s"] = "%.2f s"
L["Fill color"] = "Color del relleno"
L["Color the zone"] = "Colorear la zona"
L["Tints the end of the bar, where the fill changes color, so you see the moment coming before it arrives."] = "Tiñe el final de la barra, donde el relleno cambia de color, para que veas venir el momento antes de que llegue."
L["Zone opacity"] = "Opacidad de la zona"
L["%d%%"] = "%d %%"
