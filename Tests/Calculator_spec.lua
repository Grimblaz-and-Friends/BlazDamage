-- Tests/Calculator_spec.lua

local Calculator

describe("Calculator", function()
    setup(function()
        Calculator = require("Engine.Calculator")
    end)

    describe("computeMetrics", function()
        -- stdStats: critChance=0.25, critMult=2.0 → multiplier = 1.25
        --           castTime=2.0 > gcd=1.5 → timeOnTarget = 2.0
        --           resourceCost=100
        local stdStats = {
            critChance   = 0.25,
            critMult     = 2.0,
            castTime     = 2.0,
            gcd          = 1.5,
            resourceCost = 100,
        }

        -- -----------------------------------------------------------------
        -- Average damage calculation
        -- -----------------------------------------------------------------
        describe("average damage calculation", function()
            it("applies the crit-averaged multiplier: avg = baseValue * (1 + critChance * (critMult - 1))", function()
                -- baseValue = (100+100)/2 = 100; multiplier = 1 + 0.25*1.0 = 1.25 → avg = 125
                local result = Calculator.computeMetrics({ { min = 100, max = 100, type = "direct" } }, stdStats)
                assert.are.equal(125, result.components[1].avg)
            end)

            it("returns baseValue unchanged when critChance is zero", function()
                local stats = { critChance = 0, critMult = 2.0, castTime = 1.5, gcd = 1.5, resourceCost = 50 }
                local result = Calculator.computeMetrics({ { min = 200, max = 200, type = "direct" } }, stats)
                assert.are.equal(200, result.components[1].avg)
            end)

            it("uses the midpoint of min and max as baseValue for a ranged component", function()
                -- baseValue = (100+200)/2 = 150; critChance=0 → avg = 150
                local stats = { critChance = 0, critMult = 2.0, castTime = 1.5, gcd = 1.5, resourceCost = 0 }
                local result = Calculator.computeMetrics({ { min = 100, max = 200, type = "direct" } }, stats)
                assert.are.equal(150, result.components[1].avg)
            end)

            it("returns zero avg when both min and max are zero", function()
                local result = Calculator.computeMetrics({ { min = 0, max = 0, type = "direct" } }, stdStats)
                assert.are.equal(0, result.components[1].avg)
            end)

            it("avg field is a number even when base damage is zero", function()
                local result = Calculator.computeMetrics({ { min = 0, max = 0, type = "direct" } }, stdStats)
                assert.is_number(result.components[1].avg)
            end)
        end)

        -- -----------------------------------------------------------------
        -- DPS — cast time longer than GCD
        -- -----------------------------------------------------------------
        describe("DPS when castTime exceeds gcd", function()
            it("uses castTime as the divisor when castTime is longer than gcd", function()
                -- avg=125, castTime=2.0 → dps = 125 / 2.0 = 62.5
                local result = Calculator.computeMetrics({ { min = 100, max = 100, type = "direct" } }, stdStats)
                assert.are.equal(62.5, result.components[1].dps)
            end)
        end)

        -- -----------------------------------------------------------------
        -- DPS — GCD floor for instant spells
        -- -----------------------------------------------------------------
        describe("DPS with GCD floor for instant spells", function()
            it("uses gcd as the divisor when castTime is zero", function()
                -- avg=150 (critChance=0), gcd=1.5 → dps = 150 / 1.5 = 100
                local stats = { critChance = 0, critMult = 2.0, castTime = 0, gcd = 1.5, resourceCost = 0 }
                local result = Calculator.computeMetrics({ { min = 150, max = 150, type = "direct" } }, stats)
                assert.are.equal(100, result.components[1].dps)
            end)
        end)

        -- -----------------------------------------------------------------
        -- DPS — nil when time-on-target is zero
        -- -----------------------------------------------------------------
        describe("DPS returns nil when time-on-target is zero", function()
            it("returns nil dps when both castTime and gcd are zero", function()
                local stats = { critChance = 0.25, critMult = 2.0, castTime = 0, gcd = 0, resourceCost = 100 }
                local result = Calculator.computeMetrics({ { min = 100, max = 100, type = "direct" } }, stats)
                assert.is_nil(result.components[1].dps)
            end)
        end)

        -- -----------------------------------------------------------------
        -- DPSC (damage per cast second)
        -- -----------------------------------------------------------------
        describe("DPSC", function()
            it("computes dpsc as avg divided by castTime", function()
                -- avg=125, castTime=2.0 → dpsc = 62.5
                local result = Calculator.computeMetrics({ { min = 100, max = 100, type = "direct" } }, stdStats)
                assert.are.equal(62.5, result.components[1].dpsc)
            end)

            it("returns nil dpsc when castTime is zero", function()
                local stats = { critChance = 0.25, critMult = 2.0, castTime = 0, gcd = 1.5, resourceCost = 100 }
                local result = Calculator.computeMetrics({ { min = 100, max = 100, type = "direct" } }, stats)
                assert.is_nil(result.components[1].dpsc)
            end)
        end)

        -- -----------------------------------------------------------------
        -- DPM (damage per resource)
        -- -----------------------------------------------------------------
        describe("DPM", function()
            it("computes dpm as avg divided by resourceCost", function()
                -- avg=125, resourceCost=100 → dpm = 1.25
                local result = Calculator.computeMetrics({ { min = 100, max = 100, type = "direct" } }, stdStats)
                assert.are.equal(1.25, result.components[1].dpm)
            end)

            it("returns nil dpm when resourceCost is zero", function()
                local stats = { critChance = 0.25, critMult = 2.0, castTime = 2.0, gcd = 1.5, resourceCost = 0 }
                local result = Calculator.computeMetrics({ { min = 100, max = 100, type = "direct" } }, stats)
                assert.is_nil(result.components[1].dpm)
            end)
        end)

        -- -----------------------------------------------------------------
        -- DoT component dotDps
        -- -----------------------------------------------------------------
        describe("DoT component dotDps", function()
            it("computes dotDps as avg divided by duration", function()
                -- avg=600 (critChance=0), duration=6 → dotDps = 100
                local stats = { critChance = 0, critMult = 2.0, castTime = 1.5, gcd = 1.5, resourceCost = 0 }
                local result = Calculator.computeMetrics(
                    { { min = 600, max = 600, type = "dot", duration = 6 } }, stats)
                assert.are.equal(100, result.components[1].dotDps)
            end)

            it("returns nil dotDps when duration is zero", function()
                local stats = { critChance = 0, critMult = 2.0, castTime = 1.5, gcd = 1.5, resourceCost = 0 }
                local result = Calculator.computeMetrics(
                    { { min = 600, max = 600, type = "dot", duration = 0 } }, stats)
                assert.is_nil(result.components[1].dotDps)
            end)

            it("returns nil dotDps when duration field is absent", function()
                local stats = { critChance = 0, critMult = 2.0, castTime = 1.5, gcd = 1.5, resourceCost = 0 }
                local result = Calculator.computeMetrics({ { min = 600, max = 600, type = "dot" } }, stats)
                assert.is_nil(result.components[1].dotDps)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Channel component dotDps
        -- -----------------------------------------------------------------
        describe("channel component dotDps", function()
            it("computes dotDps as avg divided by duration for a channel type", function()
                -- avg=400 (critChance=0), duration=4 → dotDps = 100
                local stats = { critChance = 0, critMult = 2.0, castTime = 0, gcd = 1.5, resourceCost = 0 }
                local result = Calculator.computeMetrics({ { min = 400, max = 400, type = "channel", duration = 4 } },
                    stats)
                assert.are.equal(100, result.components[1].dotDps)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Multi-component totals (direct + DoT)
        --   direct:  {min=100, max=100, type="direct"} + stdStats → avg=125, dps=62.5
        --   dot:     {min=600, max=600, type="dot", duration=6} + stdStats
        --            avg = 600 * 1.25 = 750, dotDps = 750 / 6 = 125
        --   totals:  avg=875, dps = 62.5 + 125 = 187.5
        -- -----------------------------------------------------------------
        describe("multi-component totals", function()
            local mixedComponents = {
                { min = 100, max = 100, type = "direct" },
                { min = 600, max = 600, type = "dot", duration = 6 },
            }

            it("totals.avg is the sum of all component avg values", function()
                local result = Calculator.computeMetrics(mixedComponents, stdStats)
                assert.are.equal(875, result.totals.avg)
            end)

            it("totals.dps combines direct dps and dot dotDps values", function()
                local result = Calculator.computeMetrics(mixedComponents, stdStats)
                assert.are.equal(187.5, result.totals.dps)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Edge cases
        -- -----------------------------------------------------------------
        describe("edge cases", function()
            it("returns nil when parsedComponents is nil", function()
                local result = Calculator.computeMetrics(nil, stdStats)
                assert.is_nil(result)
            end)

            it("returns nil when parsedComponents is an empty table", function()
                local result = Calculator.computeMetrics({}, stdStats)
                assert.is_nil(result)
            end)

            it("returns nil when stats is nil", function()
                local result = Calculator.computeMetrics({ { min = 100, max = 100, type = "direct" } }, nil)
                assert.is_nil(result)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Return structure invariants
        -- -----------------------------------------------------------------
        describe("return structure invariants", function()
            local singleDirect = { { min = 100, max = 100, type = "direct" } }

            it("returns a non-nil result for valid input", function()
                local result = Calculator.computeMetrics(singleDirect, stdStats)
                assert.is_not_nil(result)
            end)

            it("result.components is a table", function()
                local result = Calculator.computeMetrics(singleDirect, stdStats)
                assert.is_table(result.components)
            end)

            it("result.totals is a table", function()
                local result = Calculator.computeMetrics(singleDirect, stdStats)
                assert.is_table(result.totals)
            end)

            it("each output component has a numeric avg field", function()
                local result = Calculator.computeMetrics(singleDirect, stdStats)
                for _, comp in ipairs(result.components) do
                    assert.is_number(comp.avg)
                end
            end)

            it("each output component has a string type field", function()
                local result = Calculator.computeMetrics(singleDirect, stdStats)
                for _, comp in ipairs(result.components) do
                    assert.is_string(comp.type)
                end
            end)

            it("totals.avg equals the sum of all component avg values", function()
                -- critChance=0 → avg equals baseValue exactly
                local stats = { critChance = 0, critMult = 2.0, castTime = 1.5, gcd = 1.5, resourceCost = 0 }
                local multi = {
                    { min = 100, max = 100, type = "direct" },
                    { min = 200, max = 200, type = "direct" },
                }
                local result = Calculator.computeMetrics(multi, stats)
                assert.are.equal(300, result.totals.avg)
            end)
        end)
    end)

    -- -----------------------------------------------------------------
    -- parser-calculator contract
    -- -----------------------------------------------------------------
    describe("parser-calculator contract", function()
        local DescriptionParser
        local Calc
        setup(function()
            DescriptionParser = require("Engine.DescriptionParser")
            Calc = require("Engine.Calculator")
        end)

        local stats = { critChance = 0.25, critMult = 2.0, castTime = 2.0, gcd = 1.5, resourceCost = 100 }

        it("single-hit description produces one direct component with positive avg", function()
            -- ARRANGE
            local components = DescriptionParser.parse("Deals 1,000 damage")
            -- ACT
            local result = Calc.computeMetrics(components, stats)
            -- ASSERT
            assert.is_not_nil(result)
            assert.are.equal(1, #result.components)
            assert.is_true(result.totals.avg > 0)
        end)

        it("DoT description produces one dot component with positive avg", function()
            -- ARRANGE
            local components = DescriptionParser.parse("Deals 5,000 damage over 12 sec")
            -- ACT
            local result = Calc.computeMetrics(components, stats)
            -- ASSERT
            assert.is_not_nil(result)
            assert.are.equal(1, #result.components)
            assert.are.equal("dot", result.components[1].type)
            assert.is_true(result.totals.avg > 0)
        end)

        it("mixed direct+DoT description produces two components", function()
            -- ARRANGE
            local components = DescriptionParser.parse("Deals 1,000 damage, then 3,000 damage over 8 sec")
            -- ACT
            local result = Calc.computeMetrics(components, stats)
            -- ASSERT
            assert.is_not_nil(result)
            assert.are.equal(2, #result.components)
        end)
    end)
end)

-- =============================================================================
-- formatNumber
-- =============================================================================
describe("formatNumber", function()
    setup(function()
        Calculator = require("Engine.Calculator")
    end)

    -- Table-driven boundary cases
    local cases = {
        { input = 0,       expected = "0" },
        { input = 999,     expected = "999" },
        { input = 1000,    expected = "1.0k" },
        { input = 1500,    expected = "1.5k" },
        { input = 14523,   expected = "14.5k" },
        { input = 999949,  expected = "999.9k" },
        { input = 999950,  expected = "1.0M" },
        { input = 1000000, expected = "1.0M" },
        { input = 1500000, expected = "1.5M" },
        { input = -1500,   expected = "-1.5k" },
    }

    for _, case in ipairs(cases) do
        local input, expected = case.input, case.expected
        it("formats " .. tostring(input) .. " as '" .. expected .. "'", function()
            assert.are.equal(expected, Calculator.formatNumber(input))
        end)
    end
end)

-- =============================================================================
-- resolveMetric
-- =============================================================================
describe("resolveMetric", function()
    setup(function()
        Calculator = require("Engine.Calculator")
    end)

    it("returns nil when result is nil", function()
        assert.is_nil(Calculator.resolveMetric(nil, "avg"))
    end)

    it("returns the value at the named key in result.totals", function()
        -- ARRANGE
        local result = { totals = { avg = 500 } }
        -- ACT / ASSERT
        assert.are.equal(500, Calculator.resolveMetric(result, "avg"))
    end)

    it("returns a float dps value from result.totals", function()
        -- ARRANGE
        local result = { totals = { dps = 1234.5 } }
        -- ACT / ASSERT
        assert.are.equal(1234.5, Calculator.resolveMetric(result, "dps"))
    end)

    it("returns nil when the requested metric key is absent from totals", function()
        -- ARRANGE
        local result = { totals = { avg = 500 } }
        -- ACT / ASSERT
        assert.is_nil(Calculator.resolveMetric(result, "dps"))
    end)

    it("returns nil when metricName is nil", function()
        -- ARRANGE
        local result = { totals = { avg = 500 } }
        -- ACT / ASSERT
        assert.is_nil(Calculator.resolveMetric(result, nil))
    end)
end)
