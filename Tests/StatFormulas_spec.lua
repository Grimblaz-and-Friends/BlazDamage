-- Tests/StatFormulas_spec.lua

local StatFormulas

describe("StatFormulas", function()
    setup(function()
        StatFormulas = require("Engine.StatFormulas")
    end)

    -- -----------------------------------------------------------------
    -- computeGcd
    -- -----------------------------------------------------------------
    describe("computeGcd", function()
        it("returns base GCD of 1.5 with zero haste", function()
            assert.are.equal(1.5, StatFormulas.computeGcd(0))
        end)

        it("returns 1.0 at 50% haste (1.5 / 1.5)", function()
            assert.are.equal(1.0, StatFormulas.computeGcd(50))
        end)

        it("clamps to 0.75 floor at 100% haste", function()
            assert.are.equal(0.75, StatFormulas.computeGcd(100))
        end)

        it("stays at 0.75 floor with extreme haste", function()
            assert.are.equal(0.75, StatFormulas.computeGcd(200))
        end)

        it("returns a value greater than 1.5 with negative haste (slower than base)", function()
            assert.is_true(StatFormulas.computeGcd(-50) > 1.5)
        end)
    end)

    -- -----------------------------------------------------------------
    -- critToFraction
    -- -----------------------------------------------------------------
    describe("critToFraction", function()
        it("converts 25% crit to 0.25 fraction", function()
            assert.are.equal(0.25, StatFormulas.critToFraction(25))
        end)

        it("converts 0% crit to 0", function()
            assert.are.equal(0, StatFormulas.critToFraction(0))
        end)

        it("converts 100% crit to 1.0 fraction", function()
            assert.are.equal(1.0, StatFormulas.critToFraction(100))
        end)

        it("clamps to 1.0 at exactly 100 (boundary)", function()
            assert.are.equal(1.0, StatFormulas.critToFraction(100))
        end)

        it("clamps to 1.0 for input above 100", function()
            assert.are.equal(1.0, StatFormulas.critToFraction(150))
        end)
    end)
end)
