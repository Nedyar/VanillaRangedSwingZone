-- Português (Brasil)
local _, ns = ...
if ns.LOCALE ~= "ptBR" then
    return
end
local L = ns.L

-- Chat
L["settings reset to the defaults."] = "configurações restauradas para os valores padrão."
L["/vrsz - open the options"] = "/vrsz - abrir as opções"
L["/vrsz reset - restore the default settings"] = "/vrsz reset - restaurar as configurações padrão"
L["open the game menu, then Options > AddOns > Vanilla Ranged Swing Zone."] = "abra o Menu do Jogo e depois Opções > AddOns > Vanilla Ranged Swing Zone."

-- Options
L["%s only fires while you stand still."] = "%s só dispara enquanto você está parado."
L["In the last moments before each shot, the fill of the \"%s\" bar changes color: stop moving then."] = "Nos últimos instantes antes de cada disparo, o preenchimento da barra \"%s\" muda de cor: pare de se mover nessa hora."
L["Seconds before the shot"] = "Segundos antes do disparo"
L["How long before each shot the fill changes color. %s aims for the last half second; raise it a little if your shots still wait after you stop."] = "Quanto tempo antes de cada disparo o preenchimento muda de cor. %s mira durante o último meio segundo; aumente um pouco se seus disparos ainda esperarem depois que você parar."
L["%.2f s"] = "%.2f s"
L["Fill color"] = "Cor do preenchimento"
L["Color the zone"] = "Colorir a zona"
L["Tints the end of the bar, where the fill changes color, so you see the moment coming before it arrives."] = "Tinge o fim da barra, onde o preenchimento muda de cor, para você ver o momento chegando antes que ele chegue."
L["Zone opacity"] = "Opacidade da zona"
L["%d%%"] = "%d%%"
