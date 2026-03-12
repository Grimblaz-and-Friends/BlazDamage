# Next Steps

## Completed: Issue #6 — UI Foundation

The UI Foundation layer is now fully implemented:

- `UI/StatCollector.lua` — collects `critChance`, `haste`, and computed `gcd` from the WoW API; `critMult` is a 2.0 constant; mastery, versatility, and spell power are not gathered from the API
- `UI/EventHandler.lua` — registers and routes `UNIT_AURA`, `PLAYER_EQUIPMENT_CHANGED`, and related events
- `Engine/StatFormulas.lua` — pure Lua stat math (`computeGcd`, `critToFraction`)

See [Issue #6](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/6) for full details.

## Completed: Issue #7 — Actionbar Overlays

- `UI/OverlayRenderer.lua` — attaches FontString overlays to actionbar buttons, refreshes via throttled stat cycle or immediate slot update
- `UI/ActionbarDiscovery.lua` — discovers buttons via `ActionBarButtonEventsFrame_RegisterFrame` (auto mode) or `ActionButton_Update` (update mode), with `scanDefaultButtons()` at init
- `BD.config.discoveryMode` SavedVariable controls discovery strategy (`"auto"` default)

See [Issue #7](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/7) and the [Actionbar Overlays design doc](../../Documents/Design/actionbar-overlays.md) for full details.

## Immediate Next Actions

With overlays in place, the remaining v1 feature is:

1. **[Issue #8 — Tooltip Enrichment](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/8)**
   - Hook `GameTooltip` to append calculated DPS/avg/DPSC lines
   - Works in spellbook and on actionbar buttons

## Blocked By

- Issue #8 has no remaining blockers
