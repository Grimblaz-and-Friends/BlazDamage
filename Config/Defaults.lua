local _addonName, BD = ...
BD = BD or {}  -- guard: BD is nil when loaded by standalone Lua/busted

BD.defaults = {
    metric = "avg",   -- default display metric: "avg", "dps", "dpsc", "dpm"
    showOverlays = true,
    showTooltips = true,
}
