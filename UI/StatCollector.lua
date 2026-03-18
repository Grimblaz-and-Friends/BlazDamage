-- UI/StatCollector.lua
-- WoW stat API wrapper. UI layer — TOC-loaded only.

local _, BD = ...

local StatCollector = {}
BD.StatCollector = StatCollector

local playerStats = nil   -- cached player stats (cleared by refresh)
local spellCache = {}     -- per-cycle spell cache

function StatCollector.getPlayerStats()
    if playerStats then return playerStats end
    local haste = GetHaste()
    playerStats = {
        critChance = BD.StatFormulas.critToFraction(GetSpellCritChance()),
        critMult   = BD.config.critMult,
        haste      = haste,
        gcd        = BD.StatFormulas.computeGcd(haste),
    }
    return playerStats
end

function StatCollector.getSpellStats(spellID)
    if spellID == nil then return nil end
    local cached = spellCache[spellID]
    if cached ~= nil then
        -- false = cached nil result (invalid spellID); return nil
        return cached ~= false and cached or nil
    end
    local description = C_Spell.GetSpellDescription(spellID)
    if not description then
        spellCache[spellID] = false  -- cache the miss
        return nil
    end
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local costs = C_Spell.GetSpellPowerCost(spellID)
    local stats = {
        castTime     = (spellInfo and spellInfo.castTime or 0) / 1000,
        resourceCost = (costs and costs[1] and costs[1].cost) or 0,
        resourceType = costs and costs[1] and costs[1].type,
        cooldown     = (GetSpellBaseCooldown(spellID) or 0) / 1000,
        description  = description,
    }
    spellCache[spellID] = stats
    return stats
end

function StatCollector.refresh()
    playerStats = nil
    spellCache = {}
end
