-- UI/TooltipEnricher.lua
-- Spell tooltip enrichment via TooltipDataProcessor. UI layer — WoW API permitted.

local _, BD = ...
if type(BD) ~= "table" then BD = {} end

local TooltipEnricher = {}

local function enrichCallback(tooltip, tooltipData)
    -- Guard 1: addon not fully initialised yet (ADDON_LOADED race)
    if not BD.config then return end
    -- Guard 2: feature toggled off
    if BD.config.showTooltips == false then return end

    local spellID = tooltipData and tooltipData.id
    if not spellID then return end

    local spellStats = BD.StatCollector.getSpellStats(spellID)
    if not spellStats or not spellStats.description then return end

    local parsed = BD.DescriptionParser.parse(spellStats.description)
    if not parsed or #parsed == 0 then return end

    local playerStats = BD.StatCollector.getPlayerStats()
    local stats = {
        critChance   = playerStats.critChance,
        critMult     = playerStats.critMult,
        gcd          = playerStats.gcd,
        castTime     = spellStats.castTime,
        resourceCost = spellStats.resourceCost,
    }
    local result = BD.Calculator.computeMetrics(parsed, stats)
    if not result then return end

    local totals = result.totals

    tooltip:AddLine("|cFFFFFF00BlazDamage:|r")
    tooltip:AddLine("  Avg: " .. BD.Calculator.formatNumber(totals.avg))
    if totals.dps then
        tooltip:AddLine("  DPS: " .. BD.Calculator.formatNumber(totals.dps))
    end
    if totals.dpsc and totals.dps then
        tooltip:AddLine("  DPSC: " .. BD.Calculator.formatNumber(totals.dpsc))
    end
    tooltip:AddLine("  Crit: " .. string.format("%.1f%%", playerStats.critChance * 100))
    local label = BD.Calculator.resourceLabel(spellStats.resourceType)
    if label and totals.dpm then
        tooltip:AddLine("  " .. label .. ": " .. BD.Calculator.formatNumber(totals.dpm))
    end

    tooltip:Show()
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, enrichCallback)

BD.TooltipEnricher = TooltipEnricher
