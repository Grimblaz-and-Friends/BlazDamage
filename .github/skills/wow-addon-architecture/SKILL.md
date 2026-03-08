---
name: wow-addon-architecture
description: WoW addon architecture patterns for BlazDamage — Engine/UI layer split, secure frame restrictions, event-driven updates, TOC metadata, SavedVariables, and common Lua pitfalls. Use when writing or reviewing any WoW addon code.
---

# WoW Addon Architecture Skill

## Overview

This skill covers WoW addon architecture patterns specific to BlazDamage. It translates the abstract layer rules in `.github/architecture-rules.md` into concrete WoW Lua patterns.

## The Portability Test

> *"Would this code run unmodified in a standalone Lua 5.1 interpreter with no WoW API?"*
>
> - **YES** → `Engine/` or `Config/`
> - **NO** → `UI/`

This single question resolves all placement debates. When in doubt, run the code mentally without WoW and see if it breaks.

## Engine / UI Layer Split

| Layer | What goes here | What's forbidden |
|---|---|---|
| `Engine/` | Damage formulas, stat math, description parsing, metric computation | Any WoW API: `C_Spell.*`, `GetHaste()`, `CreateFrame()`, etc. |
| `UI/` | Frames, hooks, events, overlays, tooltips, actionbar discovery | Inline damage formulas — must call Engine functions |
| `Config/` | Constants, saved variable defaults | WoW API, frame references |
| `Data/` | Static lookup tables (override data) | WoW API, Engine logic |

**Engine functions take plain Lua values** (numbers, strings, tables) as input. The UI layer calls WoW APIs, converts the results to plain values, then passes them to Engine.

```lua
-- ✅ Correct pattern
-- UI/StatCollector.lua
local crit = GetSpellCritChance()    -- WoW API in UI layer
local avg = BD.Calculator.calculateAverage(base, crit, critMult, vers)  -- plain values to Engine

-- ❌ Wrong pattern
-- Engine/Calculator.lua
local crit = GetSpellCritChance()   -- WoW API call in Engine — VIOLATION
```

For the full list of forbidden patterns, see `.github/architecture-rules.md`.

## Secure Frame Restrictions & Taint

WoW uses a "taint" system to prevent addons from interfering with protected (combat-relevant) actions.

**Key rules:**
- Protected functions cannot be called from tainted code (code not originating from Blizzard)
- `hooksecurefunc` attaches a callback to a protected function — the callback runs in a tainted context
- `BlazDamage` is read-only (overlay display, tooltip enrichment) — it never calls protected actions, so taint is not a major concern for v1
- Avoid modifying secure frames or calling `:Click()`, `:UseAction()`, etc.
- `ActionButton_Update` and `ActionButton_OnEvent` are safe functions to hook via `hooksecurefunc`

**Discovery pattern** (safe for blaze): hook `ActionBarButtonMixin.OnLoad` or `hooksecurefunc("ActionButton_Update", ...)` to discover button frames and attach overlays.

## Event-Driven Update Patterns

Register events on a dedicated frame, not on action button frames:

```lua
-- UI/EventHandler.lua
local addonName, BD = ...

local EventHandler = {}
BD.EventHandler = EventHandler

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        BD.UIManager.refreshAll()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        BD.UIManager.refreshAll()
    elseif event == "UNIT_AURA" then
        local unitToken = ...
        if unitToken == "player" then
            BD.UIManager.refreshAll()
        end
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        local slot = ...
        BD.UIManager.refreshSlot(slot)
    end
end)
```

**Key events for BlazDamage:**

| Event | When it fires | What to do |
|---|---|---|
| `PLAYER_ENTERING_WORLD` | Login, zone change, reload | Full overlay refresh |
| `PLAYER_EQUIPMENT_CHANGED` | Gear swap | Full refresh (stats changed) |
| `UNIT_AURA` (unit=player) | Buff/debuff change | Full refresh (haste, mastery may change) |
| `ACTIONBAR_SLOT_CHANGED` | Slot assigned/cleared | Refresh that slot only |
| `COMBAT_LOG_EVENT_UNFILTERED` | Every combat event | Not needed for v1 (post-hit) |

## TOC Metadata & File Load Order

The `.toc` file controls which Lua files are loaded and in what order. Files are loaded top-to-bottom.

```
## Interface: 120001       ← WoW client version (Midnight = 120001)
## Title: BlazDamage
## Notes: Description shown in the AddOns list
## Version: 0.1.0
## Author: Grimblaz-and-Friends

## SavedVariables: BlazDamageDB   ← Must match the global name in Lua

Config/Defaults.lua    ← Load Config FIRST — Engine and UI read from it
Core.lua               ← Entry point last (or at least after its dependencies)
```

**Rules:**
- Dependencies must be listed before dependents
- The `## Interface` version must match the current WoW client or the addon shows as "out of date"
- `SavedVariables` is the name of the **global Lua table** that WoW preserves between sessions
- Do not list `Engine/`, `UI/`, `Data/` directories — list individual files as you add them

## SavedVariables Pattern

WoW provides an empty table (or the previously-saved table) in the global `BlazDamageDB` on `ADDON_LOADED`. The canonical pattern for merging defaults:

```lua
-- In Core.lua ADDON_LOADED handler
local function initSavedVars()
    BlazDamageDB = BlazDamageDB or {}
    -- Merge defaults into saved vars (nil-fill: only fills missing keys, one level)
    for k, v in pairs(BD.defaults) do
        if BlazDamageDB[k] == nil then
            BlazDamageDB[k] = v
        end
    end
    BD.config = BlazDamageDB
end
```

This keeps user preferences across sessions while adding new defaults for new features.

## Common WoW Lua Pitfalls

### Global Taint
Always use `local addonName, BD = ...` and store everything on `BD`. Never assign to `_G` directly or create globals without `local`. Globals pollute the shared namespace and can taint Blizzard code.

### OnUpdate Abuse
`OnUpdate` fires every frame (~60/sec). Never do heavy work there:

```lua
-- ❌ Wrong — runs every frame
frame:SetScript("OnUpdate", function()
    refreshAllOverlays()  -- expensive!
end)

-- ✅ Correct — throttle to at most once per second
local THROTTLE = 1.0
local elapsed = 0
frame:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed >= THROTTLE then
        elapsed = elapsed - THROTTLE
        refreshAllOverlays()
    end
end)
```

For BlazDamage, overlays should update via events, not OnUpdate at all.

### Number Formatting
WoW uses `string.format` for locale-safe number display. Never concatenate numbers directly into display strings: use `string.format("%.1fk", value / 1000)`.

### String Interning
Lua interns short strings — equality checks on spell names or event strings are fast. No special handling needed.

### Nil-Safety
WoW API functions may return `nil` (e.g., `GetSpellBonusDamage(schoolID)` returns `nil` for invalid schools). Always guard: `local sp = GetSpellBonusDamage(4) or 0`.

## See Also

- `.github/architecture-rules.md` — formal layer rules, forbidden pattern list, placement checklist
- `BlazDamage.toc` — TOC format example
- `Config/Defaults.lua` — defaults table example
- `Core.lua` — ADDON_LOADED handler and slash command example
