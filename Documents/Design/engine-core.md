# Engine Core Design

The two `Engine/` modules — `DescriptionParser` and `Calculator` — form the calculation backbone of BlazDamage. Both are pure Lua 5.1 with zero WoW API calls, testable directly with busted.

## Module Overview

| Module              | Responsibility                                                          |
| ------------------- | ----------------------------------------------------------------------- |
| `DescriptionParser` | Parses a spell description string into structured numeric components    |
| `Calculator`        | Computes averaged and time-normalised metrics from those components     |

## Data Contract

`DescriptionParser.parse(description)` returns either `nil` (unparseable) or an array of component tables:

```lua
-- component shape:
{ min = number, max = number, type = "direct"|"dot"|"channel"|"heal", duration = number? }
```

This array passes directly into `Calculator.computeMetrics(parsedComponents, stats)`. No transformation is needed between the two modules.

## DescriptionParser

### Responsibilities

- Strips WoW markup (`|cAARRGGBB...|r` color codes and `|T...|t` texture tags) before pattern matching.
- Splits descriptions on `", then "` to handle mixed direct + DoT spells.
- Applies regex patterns in priority order: channel → range-DoT → DoT → range direct → direct → heal.

### Pattern Table

Patterns are declared as a single table at the top of the file, making locale extension straightforward:

```lua
local PATTERNS = {
    strip_color   = "|c%x%x%x%x%x%x%x%x(.-)%|r",
    strip_texture = "|T.-|t",
    channel       = "[Cc]hannels? ([%d,]+)[%a%s]*damage over (%d+) sec",
    range_dot     = "([%d,]+) to ([%d,]+)[%a%s]*damage over (%d+) sec",
    dot           = "([%d,]+)[%a%s]*damage over (%d+) sec",
    range         = "([%d,]+) to ([%d,]+)[%a%s]*damage",
    direct        = "([%d,]+)[%a%s]*damage",
    heal          = "[Hh]eals? for ([%d,]+)",
}
```

v1 ships English-only patterns. Adding a locale is a single table entry — no code path changes.

### Return Contract

- Returns `nil` for nil/empty input, after markup stripping leaves only whitespace, or if no patterns match.
- Otherwise returns an array of component tables (one per spell segment).
- Heal components carry `type = "heal"` and only `avg` is summed (no HPS metric).

## Calculator

### Inputs

```lua
-- stats shape:
{ critChance = number, critMult = number, castTime = number, gcd = number, resourceCost = number? }
```

`critMult` is the **full multiplier** — `2.0` means 200% (a 100% crit bonus). This matches how WoW reports it.

### Core Formula

Crit averaging is the only stat adjustment applied here. `C_Spell.GetSpellDescription()` pre-bakes versatility, mastery, and spell power into description values, so those are handled implicitly.

```text
avg = (min + max) / 2 × (1 + critChance × (critMult − 1))
```

### Time-Normalised Metrics

`timeOnTarget = max(castTime, gcd)` — the window the player is "occupied" casting or waiting on the GCD.

| Metric | Formula              | Nil guard                           |
| ------ | -------------------- | ----------------------------------- |
| `dps`  | `avg / timeOnTarget` | nil when `timeOnTarget == 0`        |
| `dpsc` | `avg / castTime`     | nil when `castTime == 0`            |
| `dpm`  | `avg / resourceCost` | nil when `resourceCost` is nil or 0 |

All nil guards are defensive: returning `nil` instead of `0` prevents the UI from displaying misleading zeroes.

For DoT and channel components `dotDps = avg / duration` (nil when `duration == 0`).

### Heal Components

Heal components produce `avg` only. HPS is not computed in v1; see GitHub issue #18 for the planned design. Heal `avg` is included in `totalAvg`, so `totals.dpsc` and `totals.dpm` reflect heal contributions when those totals are non-nil.

### Output Shape

```lua
{
    components = {
        { avg = number, type = string, dps = number?, dpsc = number?, dpm = number?, dotDps = number? }
    },
    totals = { avg = number, dps = number?, dpsc = number?, dpm = number? }
}
```

`totals.dps` is nil when no component contributed a non-nil dps value.
`totals.dpsc` is nil when `stats.castTime` is 0.
`totals.dpm` is nil when `stats.resourceCost` is nil or 0.

Per-component `dpsc` and `dpm` are populated for `direct` components only; they are `nil` for `dot`, `channel`, and `heal` components. `totals.dpsc` and `totals.dpm` aggregate all component types via `totalAvg`.

## Dual-Load Module Pattern

Both Engine modules must work in two runtimes:

| Runtime | How loaded    | Second vararg               |
| ------- | ------------- | --------------------------- |
| WoW     | TOC file list | shared `BD` namespace table |
| busted  | `require()`   | filename string             |

The guard that handles both:

```lua
local _, BD = ...
if type(BD) ~= "table" then BD = {} end
```

A simple `BD = BD or {}` would fail in busted because the second vararg is a non-nil filename string, so `or {}` never fires.

Each module also ends with `return Module` so busted's `require()` receives the module table directly.

## Testing

```bash
busted Tests/
```

Tests live in `Tests/Calculator_spec.lua` and `Tests/DescriptionParser_spec.lua`. Run them without WoW or any mocks — the modules are pure Lua.

## Acceptance Criteria

- [ ] `DescriptionParser.parse()` returns `nil` for unrecognised descriptions (no errors)
- [ ] Parsed components include `type`, `min`, `max`, and optional `duration`
- [ ] Heal components carry `type = "heal"`; `avg` is computed; no HPS metric
- [ ] `Calculator.computeMetrics()` returns `nil` when given nil or empty components
- [ ] All time-normalised metrics (`dps`, `dpsc`, `dpm`) are `nil` (not `0`) when their divisor is zero
- [ ] Both modules load via `require()` in busted without errors
- [ ] `luacheck .` passes with zero warnings on both modules
