-- UI/StatCollector.lua
-- WoW stat API wrapper. UI layer — TOC-loaded only.
--
-- Secret-value taint boundary. Since patch 12.0.5 the player-stat APIs return secret values
-- whenever auras are secret (combat, encounters, Mythic+, PvP). A secret may be stored,
-- concatenated and formatted, but never used in arithmetic or comparison, indexed, or used as a
-- table key. Engine/ is pure Lua with no way to detect one, so every WoW API return **this file
-- reads** is guarded at read time — before any arithmetic, unit conversion, or Engine-function
-- argument. The `spellID` parameter is not covered: it originates from `GetActionInfo` and from
-- tooltip data, neither of which carries a secret annotation today, and it is compared and used
-- as a table key below.
-- See Documents/Decisions/2026-08-15-secret-value-taint-boundary.md.

local _, BD = ...

local StatCollector = {}
BD.StatCollector = StatCollector

local playerStats     = nil    -- cached player stats (cleared by refresh)
local statsUnreadable = false  -- per-cycle "the read already failed" sentinel (cleared by refresh)
local spellCache      = {}     -- per-cycle spell cache
local inCombat        = false  -- seeded on PLAYER_ENTERING_WORLD, then driven by PLAYER_REGEN_*

--- True when the WoW API handed back a secret value.
-- Asked first and unconditionally everywhere below: any other test — a comparison, an index, a
-- type check — is itself illegal on a secret, so nothing may run ahead of this one.
local function isSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

--- Read-time guard for a WoW API return this file will compute on.
-- Callers fall into two groups and the return means different things to each. Where `fallback` is
-- supplied (the spell path, which has documented defaults), an absent value degrades to it and
-- only nil means "skip". Where it is omitted (the player-stat path, which has no safe default),
-- every failure — secret, absent, or not a number — collapses to nil, and nil means "skip".
-- @return the number when readable; `fallback` when the API returned nothing; nil to skip.
local function readNumber(value, fallback)
    if isSecret(value) then return nil end
    if value == nil then return fallback end
    if type(value) ~= "number" then return nil end
    return value
end

--- Returns cached player stats, or nil when they cannot be computed.
-- All-or-nothing by contract: a partial table reaches Engine/Calculator with a nil field and
-- throws there, so callers must nil-check rather than index blind. nil has three causes and the
-- caller cannot distinguish them, by design — restrictions are live, the API returned nothing, or
-- the API returned a non-number. All three mean "do not display a number".
-- In combat this never populates a cold cache: see refresh() for why.
function StatCollector.getPlayerStats()
    if playerStats then return playerStats end
    if statsUnreadable then return nil end
    if inCombat then return nil end

    local critPercent = readNumber((GetSpellCritChance()))
    if critPercent == nil then
        statsUnreadable = true
        return nil
    end
    local haste = readNumber((GetHaste()))
    if haste == nil then
        statsUnreadable = true
        return nil
    end

    playerStats = {
        critChance = BD.StatFormulas.critToFraction(critPercent),
        critMult   = BD.config.critMult,
        haste      = haste,
        gcd        = BD.StatFormulas.computeGcd(haste),
    }
    return playerStats
end

--- Returns cached per-spell stats, or nil.
-- nil means "skip this spell" and has four causes: an absent spellID, a cached miss, a cold cache
-- in combat (see refresh()), or an unreadable WoW API return.
function StatCollector.getSpellStats(spellID)
    if spellID == nil then return nil end
    local cached = spellCache[spellID]
    if cached ~= nil then
        -- false = cached nil result (invalid spellID); return nil
        return cached ~= false and cached or nil
    end

    -- Cold cache in combat: skip rather than read. A description read live during combat carries
    -- current interpolated stats, and getPlayerStats() is frozen at its last out-of-combat value,
    -- so populating here would pair a live base with frozen multipliers — a mixed number, which is
    -- the state the freeze exists to prevent. Skipping also keeps the negative cache below from
    -- pinning a transient miss for the whole fight.
    if inCombat then return nil end

    local description = C_Spell.GetSpellDescription(spellID)
    -- A restricted read is not a permanent property of the spell, so it is never negative-cached;
    -- only a genuinely absent description is. One consequence: a nil entry in spellCache means
    -- either "never looked up" or "looked up and transiently unreadable", and the two are not
    -- distinguishable.
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

--- Records combat state.
-- Seeded from InCombatLockdown() on PLAYER_ENTERING_WORLD, then driven by PLAYER_REGEN_DISABLED /
-- PLAYER_REGEN_ENABLED in EventHandler. The seed is what makes the flag correct after a /reload
-- taken mid-fight, and what reconciles it if a PLAYER_REGEN_ENABLED is ever missed across a
-- loading screen — without it this is a latch with no path back to the truth.
function StatCollector.setCombat(state)
    inCombat = state and true or false
end

--- Clears both caches — no-op in combat.
-- The gate lives here rather than at the event layer because the slash commands, the options
-- panel and ACTIONBAR_SLOT_CHANGED all reach the renderer without passing through EventHandler's
-- throttle. Both caches freeze together, and the two accessors above additionally refuse to
-- populate a cold entry while frozen: player stats are secret while restrictions are live, and
-- spell descriptions keep interpolating live stats, so a value computed mid-combat would pair a
-- live base with frozen crit and haste — a mixed number, not last known good.
function StatCollector.refresh()
    if inCombat then return end
    playerStats = nil
    statsUnreadable = false
    spellCache = {}
end
