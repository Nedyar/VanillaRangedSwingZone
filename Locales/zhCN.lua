-- 简体中文
local _, ns = ...
if ns.LOCALE ~= "zhCN" then
    return
end
local L = ns.L

-- Chat
L["settings reset to the defaults."] = "设置已恢复为默认值。"
L["/vrsz - open the options"] = "/vrsz - 打开设置"
L["/vrsz reset - restore the default settings"] = "/vrsz reset - 恢复默认设置"
L["open the game menu, then Options > AddOns > Vanilla Ranged Swing Zone."] = "打开游戏菜单，然后选择 设置选项 > 插件 > Vanilla Ranged Swing Zone。"

-- Options
L["%s only fires while you stand still."] = "%s只有在你站着不动时才会射出。"
L["In the last moments before each shot, the fill of the \"%s\" bar changes color: stop moving then."] = "在每次射击前的最后时刻，“%s”计时条的填充会变色：这时请停止移动。"
L["Seconds before the shot"] = "射击前的秒数"
L["How long before each shot the fill changes color. %s aims for the last half second; raise it a little if your shots still wait after you stop."] = "每次射击前多久让填充变色。%s会在最后半秒瞄准；如果你停下后射击仍然延迟，就稍微调高一点。"
L["%.2f s"] = "%.2f秒"
L["Fill color"] = "填充颜色"
L["Color the zone"] = "为区域着色"
L["Tints the end of the bar, where the fill changes color, so you see the moment coming before it arrives."] = "给计时条末端（填充变色的位置）着色，让你在那一刻到来之前就能看到它。"
L["Zone opacity"] = "区域不透明度"
L["%d%%"] = "%d%%"
