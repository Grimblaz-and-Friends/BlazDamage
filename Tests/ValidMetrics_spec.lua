-- Tests/ValidMetrics_spec.lua
-- Contract test: every entry in BD.VALID_METRICS must appear as a non-nil
-- key in Calculator.computeMetrics() totals for a direct spell with full stats.
-- Guards against drift between the metric validation list and Calculator output.

local Defaults
local Calculator

describe("ValidMetrics contract", function()
    setup(function()
        Defaults   = require("Config.Defaults")
        Calculator = require("Engine.Calculator")
    end)

    it("each BD.VALID_METRICS entry is a non-nil key in computeMetrics totals", function()
        -- Arrange: direct component with stats that produce non-nil values for
        -- all four metrics (avg, dps, dpsc, dpm).
        local components = { { min = 100, max = 100, type = "direct" } }
        local stats = {
            critChance   = 0,
            critMult     = 2.0,
            castTime     = 1.5,
            gcd          = 1.5,
            resourceCost = 100,
            cooldown     = 100,
        }

        -- Act
        local result = Calculator.computeMetrics(components, stats)

        -- Assert: result is valid and every listed metric is present
        assert.is_not_nil(result)
        for _, metric in ipairs(Defaults.VALID_METRICS) do
            assert.is_not_nil(
                result.totals[metric],
                "totals." .. metric .. " must not be nil for a direct spell"
            )
        end
    end)

    it("all VALID_METRICS keys resolve to non-nil totals for a heal spell", function()
        -- Arrange: heal component with stats that produce non-nil values for
        -- all four metrics (avg, dps, dpsc, dpm).
        local components = { { min = 100, max = 100, type = "heal" } }
        local stats = {
            critChance   = 0,
            critMult     = 2.0,
            castTime     = 1.5,
            gcd          = 1.5,
            resourceCost = 100,
            cooldown     = 100,
        }

        -- Act
        local result = Calculator.computeMetrics(components, stats)

        -- Assert: result is valid and every listed metric resolves to non-nil
        assert.is_not_nil(result)
        for _, key in ipairs(Defaults.VALID_METRICS) do
            assert.is_not_nil(
                Calculator.resolveMetric(result, key),
                "resolveMetric for '" .. key .. "' must not be nil for a heal spell"
            )
        end
    end)
end)
