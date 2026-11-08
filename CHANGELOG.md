# Changelog

## 0.1.1 - Bug fix

- Fixed a Lua error that could show up when a ranged swing ended: "Zone.lua:82: attempt to perform arithmetic on upvalue 'endTime' (a nil value)". It left nothing broken, but it should not have shown up at all.

## 0.1.0 - First release

- **The ranged bar turns red before each shot**: on Blizzard's own Swing Timer, the fill of the Ranged bar changes color for the last half second before each shot, while Auto Shot aims and you have to stand still.
- **The zone shows it coming**: the end of the bar, where the fill will change color, is tinted in the same color, under the fill, so you see the moment approach.
- **Options**: how long before the shot it changes color (0.1 to 1.5 seconds), the color, and whether to tint the zone and how strongly. `/vrsz` opens them.
- **Translated into every client language**: English, German, Spanish, French, Italian, Korean, Portuguese, Russian and Chinese.
