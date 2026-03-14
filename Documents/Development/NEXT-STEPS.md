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

## Completed: Issue #8 — Tooltip Enrichment

The tooltip enrichment layer is now fully implemented:

- `UI/TooltipEnricher.lua` — hooks `TooltipDataProcessor.AddTooltipPostCall` to append Avg / DPS / DPSC / Crit / resource-efficiency lines to spell tooltips
- `Engine/Calculator.resourceLabel()` — pure Lua power-type-to-label mapping (testable with busted)
- `showTooltips` config toggle — disables enrichment when set to `false`

See [Issue #8](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/8) and the [Tooltip Enrichment design doc](../../Documents/Design/tooltip-enrichment.md) for full details.

## Completed: Issue #9 — Slash Command System

- `Core.lua` slash handler extended with `metric`, `overlay`, `tooltip`, `help`, and `discovery` subcommands
- `Config/Defaults.lua` — `BD.VALID_METRICS` constant added as single source of truth for valid metric names
- All settings persist via SavedVariables (`BlazDamageDB`)
- Live refresh: `OverlayRenderer.refreshAll()` called automatically after metric or overlay changes

See [Issue #9](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/9) for full details.

## Immediate Next Actions

All v1 features are now complete. Remaining work:

1. **Manual in-game verification** — install the addon and verify tooltip lines appear on direct-damage, DoT, and heal spells; confirm unparseable spells produce no extra lines; exercise slash commands in-game
2. **Issue #18 — Heal HPS metric** — extend `Calculator.computeMetrics` to compute HPS for heal components; update `TooltipEnricher` to display it
3. See the [Roadmap](ROADMAP.md) for post-v1 milestones

## Blocked By

- No remaining blockers for v1 feature completeness
