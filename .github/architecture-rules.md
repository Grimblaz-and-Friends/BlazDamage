# Architecture Rules

This document defines the architectural constraints for BlazDamage. All agents and developers must follow these rules.

## Core Principle — The Portability Test

> *"Would this code run unmodified in a standalone Lua 5.1 interpreter with no WoW API?"*
>
> - **YES** → it belongs in `Engine/` or `Config/`
> - **NO** → it belongs in `UI/`

This single question resolves most placement debates.

## Layer Architecture

### Layer Definitions

| Layer | Directory | Responsibility | Allowed Dependencies |
| --- | --- | --- | --- |
| **Engine** | `Engine/` | Pure Lua calculation logic — stat math, damage formulas, metric computation, description parsing | Config, Data, Lua standard library |
| **UI** | `UI/` | WoW frames, hooks, events, overlays, tooltips, options panel, actionbar discovery | Engine, Config, Data, WoW API |
| **Config** | `Config/` | Pure Lua constants and saved variable defaults | None |
| **Data** | `Data/` | Static lookup tables (override data if needed) | None |
| **Tests** | `Tests/` | busted unit tests for Engine layer | Engine, Config, Data, busted |

### Layer Diagram

```text
         ┌─────────────┐
         │     UI/     │  ← WoW API lives here
         └──────┬──────┘
                │ calls
         ┌──────▼──────┐
         │   Engine/   │  ← Pure Lua, no WoW API
         └──────┬──────┘
                │ reads
    ┌───────────┼───────────┐
    │           │           │
┌───▼───┐  ┌───▼───┐  ┌───▼───┐
│Config/│  │ Data/ │  │Tests/ │
└───────┘  └───────┘  └───────┘
```

## Dependency Rules

### Allowed

```lua
-- UI → Engine (UI calls Engine for calculations)
-- UI/OverlayManager.lua
local Calculator = BD.Calculator
local avg = Calculator.calculateAverage(baseValue, critChance, critMult, vers)  -- ✅ OK

-- UI → WoW API (UI wraps WoW API and passes plain values to Engine)
-- UI/StatCollector.lua
local critChance = GetSpellCritChance()  -- ✅ OK — WoW API in UI layer
local haste = GetHaste()                 -- ✅ OK

-- Engine → Config (Engine reads constants)
-- Engine/Calculator.lua
local Defaults = BD.defaults
local metric = Defaults.defaultMetric  -- ✅ OK

-- Engine → pure Lua standard library
local formatted = string.format("%.1f", value)  -- ✅ OK
local clamped = math.max(0, math.min(1, ratio)) -- ✅ OK
```

### Prohibited

```lua
-- Engine → WoW API (VIOLATION — Engine must be pure Lua)
-- Engine/Calculator.lua
local sp = GetSpellBonusDamage(2)  -- ❌ WoW API call in Engine
local desc = C_Spell.GetSpellDescription(spellID)  -- ❌ WoW API call in Engine

-- Engine → Frame manipulation (VIOLATION)
-- Engine/Calculator.lua
local frame = CreateFrame("Frame")  -- ❌ Frame creation in Engine
GameTooltip:AddLine("text")         -- ❌ Tooltip manipulation in Engine

-- Engine → Event registration (VIOLATION)
-- Engine/Calculator.lua
frame:RegisterEvent("UNIT_STATS")   -- ❌ Event system in Engine
hooksecurefunc("ActionButton_Update", fn)  -- ❌ Hook in Engine

-- UI → Inline calculations (VIOLATION — duplicate Engine logic)
-- UI/OverlayManager.lua
local avg = baseValue * (1 + critChance * critMult) * (1 + vers)  -- ❌ Formula in UI
-- Should call: Calculator.calculateAverage(baseValue, critChance, critMult, vers)

-- Global namespace pollution (VIOLATION — always use local)
MyFunction = function() end  -- ❌ Global function
SOME_VALUE = 42              -- ❌ Global variable
```

## Engine Layer — Forbidden Patterns

The following patterns must **never** appear in `Engine/**/*.lua`:

### WoW API Calls

- `C_Spell.*`, `C_UnitAuras.*`, `C_TooltipInfo.*`, `C_ClassTalents.*`, `C_Traits.*`
- `GetSpellBonusDamage`, `GetSpellBonusHealing`, `GetSpellCritChance`
- `GetHaste`, `GetMeleeHaste`, `GetMasteryEffect`, `GetVersatilityBonus`
- `UnitAttackPower`, `UnitDamage`, `UnitStat`, `UnitLevel`
- `GetActionInfo`, `HasAction`, `IsUsableAction`

### Frame & UI

- `CreateFrame`, `UIParent`, `GameTooltip`, `InterfaceOptionsFrame`
- `FontString`, `SetText`, `SetPoint`, `SetFont`
- `hooksecurefunc`

### Event System

- `RegisterEvent`, `UnregisterEvent`, `SetScript`
- `ADDON_LOADED`, `PLAYER_ENTERING_WORLD`, `UNIT_STATS` (as string refs in registration)

### Global State

- `SlashCmdList`, `SLASH_*`
- Direct writes to `_G`

## File & Naming Conventions

### File Naming

```text
Engine/
├── Calculator.lua          # PascalCase — module name matches file name
├── DescriptionParser.lua   # One module per file
└── MetricFormatter.lua

UI/
├── OverlayManager.lua      # PascalCase
├── StatCollector.lua
├── TooltipEnricher.lua
└── ActionbarDiscovery.lua

Config/
└── Defaults.lua            # PascalCase

Tests/
├── Calculator_spec.lua     # *_spec.lua — busted convention
├── DescriptionParser_spec.lua
└── MetricFormatter_spec.lua
```

### Module Pattern

Every file uses the addon namespace pattern:

```lua
local addonName, BD = ...

local Calculator = {}
BD.Calculator = Calculator

function Calculator.calculateAverage(base, critChance, critMult, vers)
    return base * (1 + critChance * critMult) * (1 + vers)
end
```

### Test File Pattern

```lua
-- Tests/Calculator_spec.lua
describe("Calculator", function()
    local Calculator

    setup(function()
        -- Load the module under test
        Calculator = require("Engine.Calculator")
    end)

    describe("calculateAverage", function()
        it("should return base value with zero crit and zero vers", function()
            local result = Calculator.calculateAverage(100, 0, 0, 0)
            assert.are.equal(100, result)
        end)

        it("should apply crit multiplier correctly", function()
            local result = Calculator.calculateAverage(100, 0.25, 1.0, 0)
            assert.are.near(125, result, 0.01)
        end)
    end)
end)
```

## Placement Checklist

When adding a new file, run through this checklist:

1. Does it call any WoW API function? → `UI/`
2. Does it create or manipulate frames? → `UI/`
3. Does it register events or hooks? → `UI/`
4. Does it reference `_G`, `SlashCmdList`, or other WoW globals? → `UI/`
5. Is it a pure Lua function taking numbers/strings/tables? → `Engine/`
6. Is it a constant or default value? → `Config/`
7. Is it a static lookup table? → `Data/`
8. Is it a busted test? → `Tests/`

## Testing Requirements

### Engine Layer

- All Engine modules must have corresponding `*_spec.lua` tests in `Tests/`
- Tests run via `busted Tests/` in standalone Lua 5.1 (not in WoW)
- Engine tests must not require any WoW API stubs — if they do, the code under test is in the wrong layer

### UI Layer

- UI layer is verified via manual in-game testing
- No automated unit tests for UI (WoW runtime cannot be mocked easily)

## Architecture Validation

Run the architecture validation script to catch Engine layer violations:

```bash
pwsh .github/scripts/validate-architecture.ps1
```

This script scans `Engine/**/*.lua` for forbidden WoW API patterns and exits non-zero on any violation.
