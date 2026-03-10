-- Engine/StatFormulas.lua
-- Pure Lua 5.1 — zero WoW API calls. Testable with busted.

local StatFormulas = {}

-- Dual-load support: works via require() in busted AND via BD namespace in WoW.
local _, BD = ...
if type(BD) ~= "table" then BD = {} end -- luacheck: ignore 331

--- Returns the global cooldown duration (in seconds) after applying haste.
-- @param hastePercent  numeric haste percentage (e.g. 50 for 50%)
-- @return GCD clamped to a minimum of 0.75 seconds
-- Edge: hastePercent = -100 would produce math.huge (denominator reaches zero).
function StatFormulas.computeGcd(hastePercent)
    return math.max(0.75, 1.5 / (1 + hastePercent / 100))
end

--- Converts a crit percentage into a decimal fraction.
-- @param critPercent  numeric crit percentage (e.g. 25 for 25%)
-- @return fraction in [0, 1]
function StatFormulas.critToFraction(critPercent)
    return critPercent / 100
end

BD.StatFormulas = StatFormulas
return StatFormulas
