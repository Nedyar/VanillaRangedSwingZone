-- 繁體中文
local _, ns = ...
if ns.LOCALE ~= "zhTW" then
    return
end
local L = ns.L

-- Chat
L["settings reset to the defaults."] = "設定已恢復為預設值。"
L["/vrsz - open the options"] = "/vrsz - 開啟選項"
L["/vrsz reset - restore the default settings"] = "/vrsz reset - 恢復預設設定"
L["open the game menu, then Options > AddOns > Vanilla Ranged Swing Zone."] = "開啟遊戲選項，然後選擇 選項 > 插件 > Vanilla Ranged Swing Zone。"

-- Options
L["%s only fires while you stand still."] = "%s只有在你站著不動時才會射出。"
L["In the last moments before each shot, the fill of the \"%s\" bar changes color: stop moving then."] = "在每次射擊前的最後時刻，「%s」計時條的填充會變色：這時請停止移動。"
L["Seconds before the shot"] = "射擊前的秒數"
L["How long before each shot the fill changes color. %s aims for the last half second; raise it a little if your shots still wait after you stop."] = "每次射擊前多久讓填充變色。%s會在最後半秒瞄準；如果你停下後射擊仍然延遲，就稍微調高一點。"
L["%.2f s"] = "%.2f秒"
L["Fill color"] = "填充顏色"
L["Color the zone"] = "為區域著色"
L["Tints the end of the bar, where the fill changes color, so you see the moment coming before it arrives."] = "為計時條末端（填充變色的位置）著色，讓你在那一刻到來之前就能看到它。"
L["Zone opacity"] = "區域不透明度"
L["%d%%"] = "%d%%"
