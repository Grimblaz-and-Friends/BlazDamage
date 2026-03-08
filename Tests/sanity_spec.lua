-- Tests/sanity_spec.lua
-- Smoke test: validates the busted test harness is installed and operational.
-- Real feature tests begin in Issue #2 (BlazDamage v1 implementation).
describe("BlazDamage", function()
    it("test harness loads", function()
        assert.is_true(true)
    end)
end)
