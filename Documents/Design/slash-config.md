# Slash Command Configuration Design

`Core.lua` registers `/bd` (alias `/blazdamage`) as the single entry point for in-game configuration of BlazDamage settings.

## Overview

The slash handler parses a `cmd` / `arg` pair from the raw message string and dispatches to one of several command branches. All mutating commands guard against `BD.config` being nil (addon-load race). `/bd help` is explicitly exempt from this guard so it works at any time.

## Commands

| Command | Effect |
| --- | --- |
| `/bd` | Show version, metric, overlay status, tooltip status, discovery mode, perf status |
| `/bd metric` | Show current metric and the list of valid options |
| `/bd metric <name>` | Set display metric; validates against `BD.VALID_METRICS`; calls `refreshAll()` |
| `/bd overlay` | Toggle `BD.config.showOverlays`; calls `refreshAll()` |
| `/bd tooltip` | Toggle `BD.config.showTooltips` |
| `/bd perf` | Toggle `BD.config.showPerf`; enables/disables performance timing output |
| `/bd discovery` | Show current discovery mode |
| `/bd discovery auto\|update` | Set discovery mode (reload required to apply) |
| `/bd help` | Print full command list |

Unknown commands print: `Unknown command: <cmd>. Type /bd help for commands.`

### Refresh Behaviour

- **`metric` / `overlay`**: call `BD.OverlayRenderer.refreshAll()` immediately (nil-guarded) so the change is visible without a reload.
- **`tooltip`**: no refresh; enrichment is re-evaluated on the next tooltip hover.
- **`discovery`**: requires `/reload`; `ActionbarDiscovery.init()` runs once per session on `PLAYER_ENTERING_WORLD`.
- **`perf`**: no refresh needed — instrumentation only; the toggle takes effect immediately on the next refresh cycle.

## Config Keys

All settings live on `BD.config` (= `BlazDamageDB` after `ADDON_LOADED`). New keys are nil-filled from `BD.defaults` on each load.

| Key | Default | Type | Description |
| --- | --- | --- | --- |
| `metric` | `"avg"` | string | Active display metric; must be a member of `BD.VALID_METRICS` |
| `showOverlays` | `true` | boolean | Whether actionbar overlays are rendered |
| `showTooltips` | `true` | boolean | Whether tooltip enrichment lines are appended |
| `discoveryMode` | `"auto"` | string | Actionbar discovery strategy (`"auto"` or `"update"`) |
| `showPerf` | `false` | boolean | Whether performance timing output is printed on each overlay refresh |
| `critMult` | `2.0` | number | Crit damage multiplier (not slash-configurable; placeholder for Issue #22) |

## Namespace Constants

Defined in `Config/Defaults.lua`, available on the `BD` namespace as soon as `Defaults.lua` loads:

**`BD.VALID_METRICS`** `= {"avg", "dps", "dpsc", "dpm"}`
The ordered list of valid metric names. Must stay in sync with the keys returned in `Calculator.computeMetrics().totals`. A contract test in `Tests/ValidMetrics_spec.lua` guards against drift.

**`BD.PREFIX`** `= "|cFFFFFF00BlazDamage:|r"`
Shared gold-colored chat prefix. Used by `Core.lua`, `ActionbarDiscovery.lua`, and `OverlayRenderer.lua` for all in-game print output. Captured into a module-local `local PREFIX = BD.PREFIX` in `Core.lua` at file-load time.

## Implementation Notes

**Slash registration** — Two aliases are registered:

```lua
SLASH_BLAZDAMAGE1 = "/blazdamage"
SLASH_BLAZDAMAGE2 = "/bd"
SlashCmdList["BLAZDAMAGE"] = function(msg) ... end
```

**Message parsing** — The raw `msg` string is lowercased then split into `cmd` and `arg` with:

```lua
local cmd, arg = string.match(msg, "^(%S+)%s*(.-)%s*$")
```

An empty message (`""`) is handled as its own branch before the split, printing current settings.

**Not-ready guard** — All commands except `help` check `BD.config` on entry:

```lua
if cmd ~= "help" and not BD.config then
    print(PREFIX .. " Not ready yet.")
    return
end
```

**`refreshAll` nil-guard** — `BD.OverlayRenderer` may not yet be loaded when the slash handler runs:

```lua
if BD.OverlayRenderer then BD.OverlayRenderer.refreshAll() end
```

**Persistence** — `BD.config = BlazDamageDB`, so all assignments to `BD.config.*` are automatically persisted by WoW's SavedVariables mechanism between sessions.

## Design Decisions

**`/bd help` works before `ADDON_LOADED`**
Help text requires only `BD.VALID_METRICS` and `BD.PREFIX`, both set at file-load time. Exempting it from the config guard avoids confusion if a user types `/bd help` during the brief window between UI load and `ADDON_LOADED`.

**`VALID_METRICS` in `Config/Defaults.lua`, not `Engine/`**
The list is a configuration constant (user-visible metric names) that belongs with other defaults. It is not Engine logic. `Engine/Calculator.lua` does not reference `VALID_METRICS`; instead, the contract test enforces their alignment.

**Metric change is live; discovery change requires reload**
`OverlayRenderer.refreshAll()` is safe to call at any time and instantly updates all overlays. `ActionbarDiscovery.init()` is designed to run once per session (idempotent at startup, not re-entrant), so a reload is the correct mechanism for changing discovery mode.

**No separate config UI for v1**
The slash command interface covers all configurable settings without requiring an AceConfig or options panel. A GUI options panel is tracked on the roadmap but deferred until the core engine is stable.
