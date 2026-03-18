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
        cooldown     = spellStats.cooldown,
    }
    local result = BD.Calculator.computeMetrics(parsed, stats)
    if not result then return end

    local totals = result.totals
    local healOnly = BD.Calculator.isHealOnly(result.components)

    local lines = {}

    if BD.config.tooltipShowAvg ~= false then
        lines[#lines + 1] = "  Avg: " .. BD.Calculator.formatNumber(totals.avg)
    end
    if BD.config.tooltipShowDps ~= false and totals.dps then
        local dpsLabel = healOnly and "HPS" or "DPS"
        lines[#lines + 1] = "  " .. dpsLabel .. ": " .. BD.Calculator.formatNumber(totals.dps)
    end
    if BD.config.tooltipShowDpsc ~= false and totals.dpsc and totals.dps then
        local dpscLabel = healOnly and "HPSC" or "DPSC"
        lines[#lines + 1] = "  " .. dpscLabel .. ": " .. BD.Calculator.formatNumber(totals.dpsc)
    end
    -- Unlike dpsc, no totals.dps cross-check: dpscd is nil whenever cooldown is absent or 0.
    if BD.config.tooltipShowDpscd ~= false and totals.dpscd then
        local dpscdLabel = healOnly and "HPSCD" or "DPSCD"
        lines[#lines + 1] = "  " .. dpscdLabel .. ": " .. BD.Calculator.formatNumber(totals.dpscd)
    end
    if BD.config.tooltipShowCrit ~= false then
        lines[#lines + 1] = "  Crit: " .. string.format("%.1f%%", playerStats.critChance * 100)
    end
    local label = BD.Calculator.resourceLabel(spellStats.resourceType)
    if BD.config.tooltipShowDpm ~= false and label and totals.dpm then
        local displayLabel = healOnly and (string.gsub(label, "^D", "H")) or label
        lines[#lines + 1] = "  " .. displayLabel .. ": " .. BD.Calculator.formatNumber(totals.dpm)
    end

    if #lines > 0 then
        tooltip:AddLine("|cFFFFFF00BlazDamage:|r")
        for _, line in ipairs(lines) do
            tooltip:AddLine(line)
        end
        tooltip:Show()
    end
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, enrichCallback)

BD.TooltipEnricher = TooltipEnricher
