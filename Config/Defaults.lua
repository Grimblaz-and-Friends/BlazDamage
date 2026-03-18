local _, BD = ...
if type(BD) ~= "table" then BD = {} end -- luacheck: ignore 331

BD.defaults = {
    metric = "avg",   -- Display metric: "avg", "dps", "dpsc", "dpscd", or "dpm"
    showOverlays = true,
    showTooltips = true,
    critMult = 2.0,   -- crit damage multiplier; 2.0 = 200% (full crit). See issue #22 for improvement.
    discoveryMode = "auto",
    showPerf = false,
    overlayFontSize = 10,
    overlayPosition = "BOTTOMRIGHT",
    tooltipShowAvg = true,
    tooltipShowDps = true,
    tooltipShowDpsc = true,
    tooltipShowCrit = true,
    tooltipShowDpm = true,
    tooltipShowDpscd = true,
}

-- Valid display metrics (must match Calculator.computeMetrics() totals keys)
BD.VALID_METRICS = {"avg", "dps", "dpsc", "dpscd", "dpm"}

BD.PREFIX = "|cFFFFFF00BlazDamage:|r"

return BD
