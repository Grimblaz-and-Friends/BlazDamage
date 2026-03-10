# Next Steps

## Completed: Issue #6 — UI Foundation

The UI Foundation layer is now fully implemented:

- `UI/StatCollector.lua` — collects crit, haste, mastery, versatility, spell power from WoW API
- `UI/EventHandler.lua` — registers and routes `UNIT_AURA`, `PLAYER_EQUIPMENT_CHANGED`, and related events
- `Engine/StatFormulas.lua` — pure Lua stat math (average, effective crit multiplier)

See [Issue #6](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/6) for full details.

## Immediate Next Actions

With the Engine and UI Foundation in place, the remaining v1 features can now be built:

1. **[Issue #7 — Actionbar Overlays](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/7)**
   - Overlay renderer attached to actionbar buttons
   - Reads `StatCollector` + `Calculator` to display damage metrics per slot

2. **[Issue #8 — Tooltip Enrichment](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/8)**
   - Hook `GameTooltip` to append calculated DPS/avg/DPSC lines
   - Works in spellbook and on actionbar buttons

## Blocked By

- Issue #7 and #8 have no remaining blockers
