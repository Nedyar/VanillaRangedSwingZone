-- Français
local _, ns = ...
if ns.LOCALE ~= "frFR" then
    return
end
local L = ns.L

-- Chat
L["settings reset to the defaults."] = "paramètres réinitialisés aux valeurs par défaut."
L["/vrsz - open the options"] = "/vrsz - ouvrir les options"
L["/vrsz reset - restore the default settings"] = "/vrsz reset - rétablir les paramètres par défaut"
L["open the game menu, then Options > AddOns > Vanilla Ranged Swing Zone."] = "ouvrez le menu de jeu, puis Options > Add-ons > Vanilla Ranged Swing Zone."

-- Options
L["%s only fires while you stand still."] = "%s ne tire que lorsque vous êtes immobile."
L["In the last moments before each shot, the fill of the \"%s\" bar changes color: stop moving then."] = "Dans les derniers instants avant chaque tir, le remplissage de la barre « %s » change de couleur : arrêtez-vous alors."
L["Seconds before the shot"] = "Secondes avant le tir"
L["How long before each shot the fill changes color. %s aims for the last half second; raise it a little if your shots still wait after you stop."] = "Combien de temps avant chaque tir le remplissage change de couleur. %s vise pendant la dernière demi-seconde ; augmentez un peu la valeur si vos tirs attendent encore après votre arrêt."
L["%.2f s"] = "%.2f s"
L["Fill color"] = "Couleur du remplissage"
L["Color the zone"] = "Colorer la zone"
L["Tints the end of the bar, where the fill changes color, so you see the moment coming before it arrives."] = "Teinte la fin de la barre, là où le remplissage change de couleur, pour voir venir le moment avant qu'il n'arrive."
L["Zone opacity"] = "Opacité de la zone"
L["%d%%"] = "%d %%"
