# Technical Architecture

## Overview

BlazDamage is a pure Lua addon with a strict two-layer architecture: a calculation Engine that is fully independent of the WoW API, and a UI layer that mediates between WoW's runtime and the Engine.

## Layer Architecture

```text
┌─────────────────────────────────────────────────┐
│                      UI/                         │
│    WoW frames, hooks, events, overlays,         │
│    tooltips, options panel, actionbar discovery  │
├─────────────────────────────────────────────────┤
│                   Engine/                        │
│    Pure Lua calculation logic — stat math,      │
│    damage formulas, metric computation          │
├─────────────────────────────────────────────────┤
│                   Config/                        │
│    Pure Lua constants and saved variable defaults│
├─────────────────────────────────────────────────┤
│                    Data/                         │
│    Static lookup tables (override data if needed)│
└─────────────────────────────────────────────────┘
```

**The Portability Test**: *"Would this code run unmodified in a standalone Lua 5.1 interpreter with no WoW API?"*

- YES → `Engine/` or `Config/`
- NO → `UI/`

See `.github/architecture-rules.md` for the complete layer rules, forbidden patterns, and placement checklist.

## Data Flow

```text
WoW API
  │
  ├── C_Spell.GetSpellDescription(spellID)
  │       │
  │       └──► UI/StatCollector.lua ──► Engine/DescriptionParser.lua
  │                                             │
  ├── GetSpellCritChance()                      │ (min, max values)
  ├── GetHaste()                                │
  ├── GetMasteryEffect()          ──────────────►
  └── GetVersatilityBonus()               Engine/Calculator.lua
                                                 │
                                          (avg, dps, dpsc, dpm)
                                                 │
                                    UI/OverlayRenderer.lua
                                    UI/TooltipEnricher.lua
```

## Calculation Pipeline

1. **Spell discovery** — `UI/ActionbarDiscovery.lua` detects which spells are on actionbar slots via `GetActionInfo(slot)`
2. **Description fetch** — `UI/StatCollector.lua` calls `C_Spell.GetSpellDescription(spellID)` for each spell
3. **Description parse** — `Engine/DescriptionParser.lua` extracts numeric values (min/max damage, healing amounts) from the description string
4. **Stat collection** — `UI/StatCollector.lua` reads player stats: `GetSpellCritChance()`, `GetHaste()`, `GetMasteryEffect()`, `GetVersatilityBonus()`
5. **Metric computation** — `Engine/Calculator.lua` computes the configured metric (avg, dps, dpsc) from parsed values × stat multipliers
6. **Display** — `UI/OverlayRenderer.lua` renders the computed metric as a `FontString` on each button frame

## Event Model

| Event | Handler | Effect |
| --- | --- | --- |
| `ADDON_LOADED` | Core.lua | Initialize SavedVariables; register events |
| `PLAYER_ENTERING_WORLD` | UI/EventHandler.lua | Full overlay refresh on login/reload/zone |
| `PLAYER_EQUIPMENT_CHANGED` | UI/EventHandler.lua | Full refresh (gear swap changes stats) |
| `UNIT_AURA` (unit=player) | UI/EventHandler.lua | Full refresh (buff/debuff changes haste/mastery) |
| `ACTIONBAR_SLOT_CHANGED` | UI/EventHandler.lua | Refresh single slot (spell assigned/cleared) |

## Key Decisions

See `Documents/Decisions/` for the full Architecture Decision Records:

- [API-First Approach](../Decisions/2026-03-02-api-first-no-manual-spell-data.md) — why we use `C_Spell.GetSpellDescription()` instead of manual spell tables
- [Addon-Agnostic Discovery](../Decisions/2026-03-02-addon-agnostic-actionbar-discovery.md) — why we hook `ActionButton_Update` generically (superseded)
- [Switchable Discovery Modes](../Decisions/2026-03-10-switchable-actionbar-discovery.md) — primary `auto` mode hooks `ActionBarButtonEventsFrame:RegisterFrame()`; `ActionButton_Update` is the `update`-mode fallback
- [Class-Agnostic Engine](../Decisions/2026-03-02-class-agnostic-calculation-engine.md) — why the Engine makes no class-specific assumptions
