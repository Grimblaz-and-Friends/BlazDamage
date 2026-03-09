-- Tests/DescriptionParser_spec.lua

local DescriptionParser

describe("DescriptionParser", function()
    setup(function()
        DescriptionParser = require("Engine.DescriptionParser")
    end)

    describe("parse", function()

        -- -----------------------------------------------------------------
        -- Single-hit direct damage
        -- -----------------------------------------------------------------
        describe("single-hit direct damage", function()
            it("returns one direct component for a simple damage description", function()
                local result = DescriptionParser.parse("Deals 1,234 Fire damage")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("direct", result[1].type)
            end)

            it("parses comma-separated number correctly", function()
                local result = DescriptionParser.parse("Deals 1,234 Fire damage")
                assert.are.equal(1234, result[1].min)
                assert.are.equal(1234, result[1].max)
            end)

            it("sets min equal to max for a non-range spell", function()
                local result = DescriptionParser.parse("Deals 1,234 Fire damage")
                assert.are.equal(result[1].min, result[1].max)
            end)

            it("does not attach a duration to a direct component", function()
                local result = DescriptionParser.parse("Deals 1,234 Fire damage")
                assert.is_nil(result[1].duration)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Range damage (min != max)
        -- -----------------------------------------------------------------
        describe("range damage", function()
            it("returns one direct component for a min-to-max description", function()
                local result = DescriptionParser.parse("1,000 to 2,000 damage")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("direct", result[1].type)
            end)

            it("preserves distinct min and max for range spells", function()
                local result = DescriptionParser.parse("1,000 to 2,000 damage")
                assert.are.equal(1000, result[1].min)
                assert.are.equal(2000, result[1].max)
            end)

            it("does not attach a duration to a range direct component", function()
                local result = DescriptionParser.parse("1,000 to 2,000 damage")
                assert.is_nil(result[1].duration)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Damage over time (DoT)
        -- -----------------------------------------------------------------
        describe("damage over time", function()
            it("returns one dot component for an over-time description", function()
                local result = DescriptionParser.parse("Deals 5,000 damage over 12 sec")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("dot", result[1].type)
            end)

            it("parses the DoT damage value correctly", function()
                local result = DescriptionParser.parse("Deals 5,000 damage over 12 sec")
                assert.are.equal(5000, result[1].min)
                assert.are.equal(5000, result[1].max)
            end)

            it("captures the duration in seconds", function()
                local result = DescriptionParser.parse("Deals 5,000 damage over 12 sec")
                assert.are.equal(12, result[1].duration)
            end)

            it("sets min equal to max for a DoT component", function()
                local result = DescriptionParser.parse("Deals 5,000 damage over 12 sec")
                assert.are.equal(result[1].min, result[1].max)
            end)

            it("classifies a school-labeled DoT as dot, not direct", function()
                local result = DescriptionParser.parse("Deals 1,234 Shadow damage over 8 sec")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("dot", result[1].type)
                assert.are.equal(1234, result[1].min)
                assert.are.equal(8, result[1].duration)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Range damage over time
        -- -----------------------------------------------------------------
        describe("range damage over time", function()
            it("returns one dot component for a range DoT description", function()
                local result = DescriptionParser.parse("1,000 to 2,000 damage over 12 sec")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("dot", result[1].type)
            end)

            it("preserves distinct min and max for a range DoT", function()
                local result = DescriptionParser.parse("1,000 to 2,000 damage over 12 sec")
                assert.are.equal(1000, result[1].min)
                assert.are.equal(2000, result[1].max)
            end)

            it("captures the duration for a range DoT", function()
                local result = DescriptionParser.parse("1,000 to 2,000 damage over 12 sec")
                assert.are.equal(12, result[1].duration)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Channel
        -- -----------------------------------------------------------------
        describe("channel", function()
            it("returns one channel component for a channel description", function()
                local result = DescriptionParser.parse("Channels 3,000 damage over 4 sec")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("channel", result[1].type)
            end)

            it("parses the channel damage value correctly", function()
                local result = DescriptionParser.parse("Channels 3,000 damage over 4 sec")
                assert.are.equal(3000, result[1].min)
                assert.are.equal(3000, result[1].max)
            end)

            it("captures the channel duration in seconds", function()
                local result = DescriptionParser.parse("Channels 3,000 damage over 4 sec")
                assert.are.equal(4, result[1].duration)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Healing
        -- -----------------------------------------------------------------
        describe("healing", function()
            it("returns one heal component for a healing description", function()
                local result = DescriptionParser.parse("Heals for 2,500")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("heal", result[1].type)
            end)

            it("parses the healing value correctly", function()
                local result = DescriptionParser.parse("Heals for 2,500")
                assert.are.equal(2500, result[1].min)
                assert.are.equal(2500, result[1].max)
            end)

            it("does not attach a duration to a heal component", function()
                local result = DescriptionParser.parse("Heals for 2,500")
                assert.is_nil(result[1].duration)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Mixed: direct hit followed by DoT
        -- -----------------------------------------------------------------
        describe("mixed direct + DoT", function()
            it("returns two components for a direct-then-dot description", function()
                local result = DescriptionParser.parse("Deals 1,000 damage, then 3,000 damage over 8 sec")
                assert.is_not_nil(result)
                assert.are.equal(2, #result)
            end)

            it("first component is direct with the correct damage value", function()
                local result = DescriptionParser.parse("Deals 1,000 damage, then 3,000 damage over 8 sec")
                assert.are.equal("direct", result[1].type)
                assert.are.equal(1000, result[1].min)
                assert.are.equal(1000, result[1].max)
            end)

            it("second component is dot with correct damage and duration", function()
                local result = DescriptionParser.parse("Deals 1,000 damage, then 3,000 damage over 8 sec")
                assert.are.equal("dot", result[2].type)
                assert.are.equal(3000, result[2].min)
                assert.are.equal(3000, result[2].max)
                assert.are.equal(8, result[2].duration)
            end)

            it("first component has no duration", function()
                local result = DescriptionParser.parse("Deals 1,000 damage, then 3,000 damage over 8 sec")
                assert.is_nil(result[1].duration)
            end)
        end)

        -- -----------------------------------------------------------------
        -- WoW markup stripping
        -- -----------------------------------------------------------------
        describe("WoW markup stripping", function()
            it("strips color markup before parsing the damage value", function()
                local result = DescriptionParser.parse("|cFFFFD100Deals 1,000 damage|r")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("direct", result[1].type)
                assert.are.equal(1000, result[1].min)
            end)

            it("strips texture markup before parsing the damage value", function()
                local result = DescriptionParser.parse("|T134735:12|tDeals 500 damage")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("direct", result[1].type)
                assert.are.equal(500, result[1].min)
            end)

            it("returns nil when nothing parseable remains after stripping markup", function()
                local result = DescriptionParser.parse("|cFFFFD100|r")
                assert.is_nil(result)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Returns nil for unparseable input
        -- -----------------------------------------------------------------
        describe("returns nil for unparseable input", function()
            it("returns nil for nil input", function()
                local result = DescriptionParser.parse(nil)
                assert.is_nil(result)
            end)

            it("returns nil for an empty string", function()
                local result = DescriptionParser.parse("")
                assert.is_nil(result)
            end)

            it("returns nil when a number appears without a damage or heal context", function()
                local result = DescriptionParser.parse("12 sec cooldown")
                assert.is_nil(result)
            end)

            it("returns nil for a percent-only description", function()
                local result = DescriptionParser.parse("Increases damage by 15%")
                assert.is_nil(result)
            end)

            it("returns nil when there is no numeric value at all", function()
                local result = DescriptionParser.parse("Cannot be used in combat")
                assert.is_nil(result)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Component structure invariants
        -- -----------------------------------------------------------------
        describe("component structure invariants", function()
            local parseable = {
                "Deals 1,234 Fire damage",
                "1,000 to 2,000 damage",
                "Deals 5,000 damage over 12 sec",
                "Channels 3,000 damage over 4 sec",
                "Heals for 2,500",
            }

            it("every parsed component has a numeric min field", function()
                for _, desc in ipairs(parseable) do
                    local result = DescriptionParser.parse(desc)
                    assert.is_not_nil(result, "expected result for: " .. desc)
                    for _, component in ipairs(result) do
                        assert.is_number(component.min)
                    end
                end
            end)

            it("every parsed component has a numeric max field", function()
                for _, desc in ipairs(parseable) do
                    local result = DescriptionParser.parse(desc)
                    assert.is_not_nil(result, "expected result for: " .. desc)
                    for _, component in ipairs(result) do
                        assert.is_number(component.max)
                    end
                end
            end)

            it("every parsed component type is one of: direct, dot, channel, heal", function()
                local all_descs = {
                    "Deals 1,234 Fire damage",
                    "1,000 to 2,000 damage",
                    "Deals 5,000 damage over 12 sec",
                    "Channels 3,000 damage over 4 sec",
                    "Heals for 2,500",
                    "Deals 1,000 damage, then 3,000 damage over 8 sec",
                }
                local valid = { direct = true, dot = true, channel = true, heal = true }
                for _, desc in ipairs(all_descs) do
                    local result = DescriptionParser.parse(desc)
                    assert.is_not_nil(result, "expected result for: " .. desc)
                    for _, component in ipairs(result) do
                        assert.is_true(
                            valid[component.type] == true,
                            "invalid type '" .. tostring(component.type) .. "' for: " .. desc
                        )
                    end
                end
            end)

            it("duration is present only on dot and channel components", function()
                local cases = {
                    { desc = "Deals 1,234 Fire damage",          has_duration = false },
                    { desc = "1,000 to 2,000 damage",            has_duration = false },
                    { desc = "Heals for 2,500",                  has_duration = false },
                    { desc = "Deals 5,000 damage over 12 sec",   has_duration = true  },
                    { desc = "Channels 3,000 damage over 4 sec", has_duration = true  },
                }
                for _, case in ipairs(cases) do
                    local result = DescriptionParser.parse(case.desc)
                    assert.is_not_nil(result, "expected result for: " .. case.desc)
                    local component = result[1]
                    if case.has_duration then
                        assert.is_number(component.duration)
                    else
                        assert.is_nil(component.duration)
                    end
                end
            end)

            it("min is always less than or equal to max", function()
                for _, desc in ipairs(parseable) do
                    local result = DescriptionParser.parse(desc)
                    assert.is_not_nil(result, "expected result for: " .. desc)
                    for _, component in ipairs(result) do
                        assert.is_true(
                            component.min <= component.max,
                            "min exceeds max for: " .. desc
                        )
                    end
                end
            end)
        end)

    end) -- describe("parse")
end) -- describe("DescriptionParser")
