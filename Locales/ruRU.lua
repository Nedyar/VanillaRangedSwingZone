-- Русский
local _, ns = ...
if ns.LOCALE ~= "ruRU" then
    return
end
local L = ns.L

-- Chat
L["settings reset to the defaults."] = "настройки сброшены на значения по умолчанию."
L["/vrsz - open the options"] = "/vrsz - открыть настройки"
L["/vrsz reset - restore the default settings"] = "/vrsz reset - восстановить настройки по умолчанию"
L["open the game menu, then Options > AddOns > Vanilla Ranged Swing Zone."] = "откройте главное меню, затем Параметры > Модификации > Vanilla Ranged Swing Zone."

-- Options
L["%s only fires while you stand still."] = "Способность «%s» срабатывает, только пока вы стоите на месте."
L["In the last moments before each shot, the fill of the \"%s\" bar changes color: stop moving then."] = "В последние мгновения перед каждым выстрелом заполнение полосы «%s» меняет цвет: в этот момент остановитесь."
L["Seconds before the shot"] = "Секунд до выстрела"
L["How long before each shot the fill changes color. %s aims for the last half second; raise it a little if your shots still wait after you stop."] = "За сколько секунд до каждого выстрела заполнение меняет цвет. «%s» прицеливается последние полсекунды; немного увеличьте значение, если выстрелы всё ещё задерживаются после остановки."
L["%.2f s"] = "%.2f с"
L["Fill color"] = "Цвет заполнения"
L["Color the zone"] = "Окрашивать зону"
L["Tints the end of the bar, where the fill changes color, so you see the moment coming before it arrives."] = "Подкрашивает конец полосы, где заполнение меняет цвет, чтобы вы заранее видели приближение этого момента."
L["Zone opacity"] = "Непрозрачность зоны"
L["%d%%"] = "%d%%"
