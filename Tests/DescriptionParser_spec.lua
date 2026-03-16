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

            it("parses range damage with a school label correctly", function()
                local result = DescriptionParser.parse("1,000 to 2,000 Fire damage")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("direct", result[1].type)
                assert.are.equal(1000, result[1].min)
                assert.are.equal(2000, result[1].max)
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

            it("handles a school-labeled channel description", function()
                local result = DescriptionParser.parse("Channels 3,000 Fire damage over 4 sec")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("channel", result[1].type)
                assert.are.equal(3000, result[1].min)
                assert.are.equal(3000, result[1].max)
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
        -- Healing with intermediate text
        -- -----------------------------------------------------------------
        describe("healing with intermediate text", function()
            it("parses heal when text before 'for' contains only letters and spaces", function()
                local result = DescriptionParser.parse("healing all party or raid members within 40 yards for 1,029")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("heal", result[1].type)
                assert.are.equal(1029, result[1].min)
                assert.are.equal(1029, result[1].max)
            end)

            it("parses heal when intermediate text contains digits (e.g. yards)", function()
                local result = DescriptionParser.parse("heals an injured party or raid member within 40 yards for 1,029 every 2 sec")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("heal", result[1].type)
                assert.are.equal(1029, result[1].min)
                assert.are.equal(1029, result[1].max)
            end)

            it("does not attach a duration for a flat heal despite trailing 'every N sec' text", function()
                local result = DescriptionParser.parse("heals an injured party or raid member within 40 yards for 1,029 every 2 sec")
                assert.is_not_nil(result)
                assert.is_nil(result[1].duration)
            end)

            it("parses heal in the first segment after ', then ' split", function()
                local result = DescriptionParser.parse("Heals a friendly target for 12,345, then jumps to the most injured nearby party or raid member")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("heal", result[1].type)
                assert.are.equal(12345, result[1].min)
                assert.are.equal(12345, result[1].max)
            end)

            it("captures the first heal value when multiple numbers follow 'for'", function()
                local result = DescriptionParser.parse("heals the target for 5,000 and an additional 2,500 over 8 sec")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("heal", result[1].type)
                assert.are.equal(5000, result[1].min)
                assert.are.equal(5000, result[1].max)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Range heal (min != max)
        -- -----------------------------------------------------------------
        describe("range heal", function()
            it("returns one heal component for a min-to-max heal description", function()
                local result = DescriptionParser.parse("Heals a friendly target for 1,000 to 2,000")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("heal", result[1].type)
            end)

            it("preserves distinct min and max for a range heal", function()
                local result = DescriptionParser.parse("Heals a friendly target for 1,000 to 2,000")
                assert.are.equal(1000, result[1].min)
                assert.are.equal(2000, result[1].max)
            end)

            it("does not attach a duration to a range heal component", function()
                local result = DescriptionParser.parse("Heals a friendly target for 1,000 to 2,000")
                assert.is_nil(result[1].duration)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Restore pattern ("restores N of...health")
        -- -----------------------------------------------------------------
        describe("restore pattern", function()
            it("parses 'restores N of...health' as a heal component", function()
                local result = DescriptionParser.parse("restores 15,432 of a friendly target's health")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("heal", result[1].type)
                assert.are.equal(15432, result[1].min)
                assert.are.equal(15432, result[1].max)
            end)

            it("parses capitalised Restores as a heal component", function()
                local result = DescriptionParser.parse("Restores 18,750 of a friendly target's health")
                assert.is_not_nil(result)
                assert.are.equal("heal", result[1].type)
                assert.are.equal(18750, result[1].min)
                assert.are.equal(18750, result[1].max)
            end)

            it("parses full Healing Surge text as a heal component", function()
                local result = DescriptionParser.parse(
                    [[A quick surge of healing energy that restores 15,432 of a friendly target's health]]
                )
                assert.is_not_nil(result)
                assert.are.equal("heal", result[1].type)
                assert.are.equal(15432, result[1].min)
                assert.are.equal(15432, result[1].max)
            end)

            it("does not attach a duration to a restore component", function()
                local result = DescriptionParser.parse("restores 15,432 of a friendly target's health")
                assert.is_not_nil(result)
                assert.is_nil(result[1].duration)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Range restore ("restores N to M of...health")
        -- -----------------------------------------------------------------
        describe("range restore", function()
            it("returns one heal component for a range restore description", function()
                local result = DescriptionParser.parse("restores 1,500 to 2,500 of a friendly target's health")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("heal", result[1].type)
            end)

            it("preserves distinct min and max for a range restore", function()
                local result = DescriptionParser.parse("restores 1,500 to 2,500 of a friendly target's health")
                assert.are.equal(1500, result[1].min)
                assert.are.equal(2500, result[1].max)
            end)
        end)

        -- -----------------------------------------------------------------
        -- Restore negative tests (non-health resources must not match)
        -- -----------------------------------------------------------------
        describe("restore negative tests", function()
            it("returns nil for 'Restores 100 Mana' (no health anchor)", function()
                local result = DescriptionParser.parse("Restores 100 Mana")
                assert.is_nil(result)
            end)

            it("returns nil for 'Restores 5 charges' (no health anchor)", function()
                local result = DescriptionParser.parse("Restores 5 charges")
                assert.is_nil(result)
            end)

            it("returns nil for energy restore without health anchor", function()
                local result = DescriptionParser.parse("Restores 3,000 energy over 10 sec")
                assert.is_nil(result)
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
        -- filters components with nil min/max
        -- -----------------------------------------------------------------
        describe("filters components with nil min/max", function()
            it("returns nil for a description where the only number capture is commas-only", function()
                -- ",,," matches [%d,]+ but tonumber("") -> nil; component is filtered; no valid components -> nil
                local result = DescriptionParser.parse(",,, damage")
                assert.is_nil(result)
            end)

            it("returns nil for a range description where the min capture is commas-only", function()
                -- ",,, to 2,000 damage": range pattern matches; min parseNumber->nil; component filtered
                local result = DescriptionParser.parse(",,, to 2,000 damage")
                assert.is_nil(result)
            end)

            it("returns only the valid component when mixed with an invalid segment", function()
                -- "1,000 damage, then ,,, damage over 8 sec"
                -- Segment 1: valid direct {min=1000, max=1000}
                -- Segment 2: dot pattern matches ",,,"; min=nil -> component filtered
                -- Result: 1 valid component only
                local result = DescriptionParser.parse("1,000 damage, then ,,, damage over 8 sec")
                assert.is_not_nil(result)
                assert.are.equal(1, #result)
                assert.are.equal("direct", result[1].type)
                assert.are.equal(1000, result[1].min)
                assert.are.equal(1000, result[1].max)
            end)

            it("returns nil for a range description where the max capture is commas-only", function()
                -- "1,000 to ,,, damage": range pattern matches; max parseNumber->nil; component filtered
                local result = DescriptionParser.parse("1,000 to ,,, damage")
                assert.is_nil(result)
            end)

            it("returns nil for a range-dot description where the min capture is commas-only", function()
                -- ",,, to 2,000 damage over 8 sec": range_dot pattern matches; min parseNumber->nil; component filtered
                local result = DescriptionParser.parse(",,, to 2,000 damage over 8 sec")
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
                "restores 15,432 health",
                "Heals a friendly target for 1,000 to 2,000",
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
                    "restores 15,432 health",
                    "Heals a friendly target for 1,000 to 2,000",
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
                    { desc = "Deals 5,000 damage over 12 sec",   has_duration = true },
                    { desc = "Channels 3,000 damage over 4 sec", has_duration = true },
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
end)     -- describe("DescriptionParser")
