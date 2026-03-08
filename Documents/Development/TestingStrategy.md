# Testing Strategy

## Philosophy

**Test the Engine exhaustively. Verify the UI manually.**

The Engine layer (`Engine/`) is pure Lua — no WoW API, no frames, no state. It takes numbers in and returns numbers out. This makes it fully testable with busted in a standard Lua 5.1 environment, without WoW running.

The UI layer (`UI/`) is deeply integrated with WoW's runtime (frames, events, hooks). Mocking the WoW API for automated tests is costly and brittle. Manual in-game verification is more reliable and faster for this layer in v1.

## Testing Layers

### Engine Layer — busted (automated)

Tests live in `Tests/` and follow busted BDD conventions:

- Test file naming: `{ModuleName}_spec.lua` (e.g., `Calculator_spec.lua`)
- Require Engine modules directly: `local Calculator = require("Engine.Calculator")`
- Test behavior, not implementation: "returns correct average" not "calls math.max"
- Cover edge cases: zero base value, 100% crit, missing values (nil inputs)

Example:

```lua
-- Tests/Calculator_spec.lua
describe("Calculator", function()
    local Calculator

    setup(function()
        Calculator = require("Engine.Calculator")
    end)

    describe("calculateAverage", function()
        it("returns base value with zero crit and zero vers", function()
            assert.are.equal(100, Calculator.calculateAverage(100, 0, 0, 0))
        end)

        it("applies crit multiplier", function()
            assert.are.near(125, Calculator.calculateAverage(100, 0.25, 1.0, 0), 0.01)
        end)

        it("applies versatility", function()
            assert.are.near(110, Calculator.calculateAverage(100, 0, 0, 0.10), 0.01)
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
