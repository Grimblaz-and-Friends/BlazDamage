-- Tests/Defaults_spec.lua
-- Contract test: BD.defaults contains all expected default values.
-- Guards against accidental removal or change of default config keys.

local Defaults

describe("BD.defaults contract", function()
    setup(function()
        Defaults = require("Config.Defaults")
    end)

    it("metric defaults to 'avg'", function()
        assert.are.equal("avg", Defaults.defaults.metric)
    end)

    it("showOverlays defaults to true", function()
        assert.is_true(Defaults.defaults.showOverlays)
    end)

    it("showTooltips defaults to true", function()
        assert.is_true(Defaults.defaults.showTooltips)
    end)

    it("critMult defaults to 2.0", function()
        assert.are.equal(2.0, Defaults.defaults.critMult)
    end)

    it("discoveryMode defaults to 'auto'", function()
        assert.are.equal("auto", Defaults.defaults.discoveryMode)
    end)

    it("showPerf defaults to false", function()
        assert.is_false(Defaults.defaults.showPerf)
    end)

    it("overlayFontSize defaults to 10", function()
        assert.are.equal(10, Defaults.defaults.overlayFontSize)
    end)

    it("overlayPosition defaults to 'BOTTOMRIGHT'", function()
        assert.are.equal("BOTTOMRIGHT", Defaults.defaults.overlayPosition)
    end)

    it("tooltipShowAvg defaults to true", function()
        assert.is_true(Defaults.defaults.tooltipShowAvg)
    end)

    it("tooltipShowDps defaults to true", function()
        assert.is_true(Defaults.defaults.tooltipShowDps)
    end)

    it("tooltipShowDpsc defaults to true", function()
        assert.is_true(Defaults.defaults.tooltipShowDpsc)
    end)

    it("tooltipShowCrit defaults to true", function()
        assert.is_true(Defaults.defaults.tooltipShowCrit)
    end)

    it("tooltipShowDpm defaults to true", function()
        assert.is_true(Defaults.defaults.tooltipShowDpm)
    end)
end)
