-- 한국어
local _, ns = ...
if ns.LOCALE ~= "koKR" then
    return
end
local L = ns.L

-- Chat
L["settings reset to the defaults."] = "설정을 기본값으로 초기화했습니다."
L["/vrsz - open the options"] = "/vrsz - 설정 열기"
L["/vrsz reset - restore the default settings"] = "/vrsz reset - 기본 설정으로 되돌리기"
L["open the game menu, then Options > AddOns > Vanilla Ranged Swing Zone."] = "게임 메뉴를 연 다음 설정 > 애드온 > Vanilla Ranged Swing Zone으로 이동하세요."

-- Options
L["%s only fires while you stand still."] = "%s 기술은 가만히 서 있을 때만 발사됩니다."
L["In the last moments before each shot, the fill of the \"%s\" bar changes color: stop moving then."] = "매 사격 직전 마지막 순간에 '%s' 바의 채움 색이 바뀝니다. 그때 이동을 멈추세요."
L["Seconds before the shot"] = "사격 전 시간"
L["How long before each shot the fill changes color. %s aims for the last half second; raise it a little if your shots still wait after you stop."] = "매 사격 몇 초 전에 채움 색이 바뀔지 정합니다. %s 기술은 마지막 0.5초 동안 조준합니다. 멈춘 뒤에도 사격이 늦어지면 값을 조금 올리세요."
L["%.2f s"] = "%.2f초"
L["Fill color"] = "채움 색"
L["Color the zone"] = "구역 색칠"
L["Tints the end of the bar, where the fill changes color, so you see the moment coming before it arrives."] = "채움 색이 바뀌는 바의 끝부분을 미리 칠해, 그 순간이 다가오는 것을 볼 수 있게 합니다."
L["Zone opacity"] = "구역 불투명도"
L["%d%%"] = "%d%%"
