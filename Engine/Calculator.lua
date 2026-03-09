-- Engine/Calculator.lua
-- Pure Lua 5.1 — zero WoW API calls. Testable with busted.

local Calculator = {}

-- Dual-load support: works via require() in busted AND via BD namespace in WoW.
local _, BD = ...
if type(BD) ~= "table" then BD = {} end -- luacheck: ignore 331

-- NOTE: C_Spell.GetSpellDescription() pre-computes spell power, versatility,
-- and mastery into the returned description values. Only crit averaging is
-- applied by this module. critMult is the full multiplier (e.g. 2.0 for 200%).

-- Computes per-component and aggregate metrics from parsed spell components.
--
-- parsedComponents: array of {min, max, type, duration?}  (nil/empty → returns nil)
-- stats:            {critChance, critMult, castTime, gcd, resourceCost}
--
-- Returns { components = {...}, totals = { avg, dps } }
function Calculator.computeMetrics(parsedComponents, stats)
    if not parsedComponents or #parsedComponents == 0 then
        return nil
    end
    if not stats then return nil end

    local timeOnTarget = math.max(stats.castTime, stats.gcd)
    local outputComponents = {}
    local totalAvg = 0
    local totalDps

    for _, component in ipairs(parsedComponents) do
        local baseValue = (component.min + component.max) / 2
        local avg = baseValue * (1 + stats.critChance * (stats.critMult - 1))

        local comp = { avg = avg, type = component.type }

        if component.type == "direct" then
            local dps = (timeOnTarget > 0) and (avg / timeOnTarget) or nil
            comp.dps  = dps
            comp.dpsc = (stats.castTime > 0) and (avg / stats.castTime) or nil
            comp.dpm  = (stats.resourceCost > 0) and (avg / stats.resourceCost) or nil
            if dps then
                totalDps = (totalDps or 0) + dps
            end
        else
            -- dot or channel: time-on-target = duration
            local dotDps = ((component.duration or 0) > 0)
                           and (avg / component.duration) or nil
            comp.dotDps = dotDps
            if dotDps then
                totalDps = (totalDps or 0) + dotDps
            end
        end

        totalAvg = totalAvg + avg
        outputComponents[#outputComponents + 1] = comp
    end

    return {
        components = outputComponents,
        totals = {
            avg = totalAvg,
            dps = totalDps,
        },
    }
end

BD.Calculator = Calculator
return Calculator
