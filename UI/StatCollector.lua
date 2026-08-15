-- UI/StatCollector.lua
-- WoW stat API wrapper. UI layer — TOC-loaded only.
--
-- Secret-value taint boundary. Since patch 12.0.5 the player-stat APIs return secret values
-- whenever auras are secret (combat, encounters, Mythic+, PvP). A secret may be stored,
-- concatenated and formatted, but never used in arithmetic or comparison, indexed, or used as a
-- table key. Engine/ is pure Lua with no way to detect one, so every WoW API return read here is
-- guarded at read time — before any arithmetic, unit conversion, or Engine-function argument.
-- Nothing unreadable leaves this file.
-- See Documents/Decisions/2026-08-15-secret-value-taint-boundary.md.

local _, BD = ...

local StatCollector = {}
BD.StatCollector = StatCollector

local playerStats = nil    -- cached player stats (cleared by refresh)
local spellCache  = {}     -- per-cycle spell cache
local inCombat    = false  -- driven by PLAYER_REGEN_* via EventHandler; freezes both caches

--- True when the WoW API handed back a secret value.
-- Asked first and unconditionally everywhere below: any other test — a comparison, an index, a
-- type check — is itself illegal on a secret, so nothing may run ahead of this one.
local function isSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

--- Read-time guard for a WoW API return this file will compute on.
-- @return the number when it is readable; `fallback` when the API returned nothing; nil when the
--         value is secret or is not a number, which every caller treats as "skip".
local function readNumber(value, fallback)
    if isSecret(value) then return nil end
    if value == nil then return fallback end
    if type(value) ~= "number" then return nil end
    return value
end

--- Returns cached player stats, or nil when any stat is unreadable.
-- All-or-nothing by contract: a partial table reaches Engine/Calculator with a nil field and
-- throws there, so callers must nil-check rather than index blind. A failed read is not cached —
-- restriction is a transient state, and the next refresh should try again.
function StatCollector.getPlayerStats()
    if playerStats then return playerStats end

    local critPercent = readNumber(GetSpellCritChance())
    if critPercent == nil then return nil end
    local haste = readNumber(GetHaste())
    if haste == nil then return nil end

    playerStats = {
        critChance = BD.StatFormulas.critToFraction(critPercent),
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
    -- A restricted read is not a permanent property of the spell, so it is never negative-cached;
    -- only a genuinely absent description is.
    if isSecret(description) then return nil end
    if type(description) ~= "string" then
        spellCache[spellID] = false  -- cache the miss
        return nil
    end

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local costs     = C_Spell.GetSpellPowerCost(spellID)
    if isSecret(spellInfo) or isSecret(costs) then return nil end
    local cost = costs and costs[1]
    if isSecret(cost) then return nil end

    local castTimeMs = readNumber(spellInfo and spellInfo.castTime, 0)
    local cooldownMs = readNumber(GetSpellBaseCooldown(spellID), 0)  -- 2nd return (gcdMs) discarded
    local resourceCost = readNumber(cost and cost.cost, 0)
    local resourceType = cost and cost.type
    if castTimeMs == nil or cooldownMs == nil or resourceCost == nil or isSecret(resourceType) then
        return nil
    end

    local stats = {
        castTime     = castTimeMs / 1000, -- ms -> s
        resourceCost = resourceCost,
        resourceType = resourceType,
        cooldown     = cooldownMs / 1000, -- ms -> s
        description  = description,
    }
    spellCache[spellID] = stats
    return stats
end

--- Records combat state. Driven by PLAYER_REGEN_DISABLED / PLAYER_REGEN_ENABLED in EventHandler.
function StatCollector.setCombat(state)
    inCombat = state and true or false
end

--- Clears both caches — no-op in combat.
-- The gate lives here rather than at the event layer because the slash commands, the options
-- panel and ACTIONBAR_SLOT_CHANGED all reach the renderer without passing through EventHandler's
-- throttle. Both caches freeze together: player stats are secret while restrictions are live, and
-- spell descriptions keep interpolating live stats, so refreshing only the spell cache would pair
-- a live description base with frozen crit and haste — a mixed number, not last known good.
function StatCollector.refresh()
    if inCombat then return end
    playerStats = nil
    spellCache = {}
end
