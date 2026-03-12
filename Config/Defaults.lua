local _, BD = ...
if type(BD) ~= "table" then BD = {} end -- luacheck: ignore 331

BD.defaults = {
    metric = "avg",   -- Display metric: "avg", "dps", "dpsc", or "dpm"
    showOverlays = true,
    showTooltips = true,
    critMult = 2.0,   -- crit damage multiplier; 2.0 = 200% (full crit). See issue #22 for improvement.
    discoveryMode = "auto",
}
