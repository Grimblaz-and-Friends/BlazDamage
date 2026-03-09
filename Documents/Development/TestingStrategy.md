# Testing Strategy

## Philosophy

**Test the Engine exhaustively. Verify the UI manually.**

The Engine layer (`Engine/`) is pure Lua — no WoW API, no frames, no state. It takes numbers in and returns numbers out. This makes it fully testable with busted (Lua 5.4.6 CI runtime; WoW target is Lua 5.1 — Engine code must remain 5.1-compatible), without WoW running.

The UI layer (`UI/`) is deeply integrated with WoW's runtime (frames, events, hooks). Mocking the WoW API for automated tests is costly and brittle. Manual in-game verification is more reliable and faster for this layer in v1.

## Testing Layers

### Engine Layer — busted (automated)

Tests live in `Tests/` and follow busted BDD conventions:

- Test file naming: `{ModuleName}_spec.lua` (e.g., `Calculator_spec.lua`)
- Require Engine modules directly: `local Calculator = require("Engine.Calculator")`
- Test behavior, not implementation: "returns correct average" not "calls math.max"
- Cover edge cases: zero base value, 100% crit, missing values (nil inputs)

### Engine Module Contract for busted Compatibility

Engine modules must satisfy two requirements to be `require()`-able in standalone busted:

1. **`return` the module table** — busted's `require()` uses the return value; modules that only assign to `BD.ModuleName` and return nothing yield `nil` from `require()`.
2. **Guard the `BD` namespace** — busted passes `("Engine.ModuleName", nil)` as varargs, so `local addonName, BD = ...` gives `BD = nil`. The `BD = BD or {}` guard in the module handles this — no test-side shim is needed.

**Recommended patterns**:

Engine module (`Engine/Calculator.lua`):

```lua
local _addonName, BD = ...
if type(BD) ~= "table" then BD = {} end  -- busted passes filename string as 2nd vararg; WoW passes the BD table

local Calculator = {}

function Calculator.computeMetrics(parsedComponents, stats)
    -- ... pure math, no WoW API ...
    -- returns { components = {...}, totals = { avg = ..., dps = ... } }
end

BD.Calculator = Calculator
return Calculator  -- required for busted require() to work
```

Test file (`Tests/Calculator_spec.lua`):

```lua
local Calculator = require("Engine.Calculator")

describe("Calculator", function()
    -- ...
end)
```

Example:

```lua
-- Tests/Calculator_spec.lua
describe("Calculator", function()
    local Calculator
    local DescriptionParser

    setup(function()
        Calculator = require("Engine.Calculator")
        DescriptionParser = require("Engine.DescriptionParser")
    end)

    describe("computeMetrics", function()
        it("returns nil when given no components", function()
            local result = Calculator.computeMetrics(nil, { critChance = 0, critMult = 2.0, castTime = 0, gcd = 1.5, resourceCost = 0 })
            assert.is_nil(result)
        end)

        it("applies the crit multiplier", function()
            local parsed = DescriptionParser.parse("Deals 1,000 damage over 8 sec")
            local result = Calculator.computeMetrics(parsed, {
                critChance = 0.25, critMult = 2.0,
                castTime = 0, gcd = 1.5, resourceCost = 100
            })
            assert.are.equal(1250, result.totals.avg)
        end)
    end)
end)
```

Run with: `busted Tests/`

### UI Layer — manual in-game verification

The UI layer is verified manually in WoW:

1. Install the addon (symlink or copy to AddOns folder)
2. `/reload` to reload the UI
3. Verify overlays appear on action buttons
4. Verify overlay values match expected approximations
5. Test event triggers: swap gear, gain/lose a buff, change action slots

**Before v1 release**: verify correct overlay values with at least 3 diverse specs (see ADR: Class-Agnostic Engine).

## Running Tests

```bash
busted Tests/
```

Requires Lua 5.1 and busted installed via luarocks. Tests run without WoW — pure Lua only.

## Coverage

No formal coverage threshold for v1. Coverage is assessed manually by ensuring each public Engine function has test cases for:

- Normal operation (typical inputs)
- Boundary conditions (zero, nil, max values)
- Error conditions (invalid inputs should degrade gracefully, not error)

## Why Not E2E Tests

WoW's Lua environment is sandboxed and not scriptable from outside the game. There is no headless WoW runner, no DOM to inspect, no REST API.
Automated E2E tests would require a full WoW client instance plus a way to inject commands and capture output —
feasible in theory (addon testing frameworks exist) but far beyond v1 scope. Manual verification is the pragmatic choice.
