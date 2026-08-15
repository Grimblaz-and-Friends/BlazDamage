# UI Foundation Design

The UI Foundation layer connects the WoW runtime to the pure-Lua Engine. It consists of one Engine module (`StatFormulas`) and two UI modules (`StatCollector`, `EventHandler`) that together collect player and spell stats and keep them fresh across events.

## Module Overview

| Module                  | Layer  | Purpose                                                             | Dependencies                         |
| ----------------------- | ------ | ------------------------------------------------------------------- | ------------------------------------ |
| `Engine/StatFormulas.lua` | Engine | Pure Lua GCD and crit conversion formulas                         | none (pure math)                     |
| `UI/StatCollector.lua`  | UI     | WoW stat API wrapper; two-tier player/spell stat collection         | `BD.StatFormulas`, `BD.config`       |
| `UI/EventHandler.lua`   | UI     | WoW event registration + dirty-flag OnUpdate refresh throttle       | `BD.StatCollector`                   |

## StatCollector API

### `StatCollector.getPlayerStats()` → `{critChance, critMult, haste, gcd}` or `nil`

Returns a cached table of player-global stats. Results are cached for the current cycle and cleared by `refresh()`.

Returns `nil` when any stat is unreadable — which since patch 12.0.5 means "restrictions are live and nothing is cached from out of combat". The contract is all-or-nothing: never a partial table, because `Calculator` guards the `stats` table but not its fields and throws on a nil `gcd`. A failed read is not cached, so the next refresh retries. **Callers must nil-check.** See [Secret-Value Taint Boundary](../Decisions/2026-08-15-secret-value-taint-boundary.md).

| Field        | Source                                                           |
| ------------ | ---------------------------------------------------------------- |
| `critChance` | `GetSpellCritChance()` (0–100) converted to 0–1 fraction via `StatFormulas.critToFraction()` |
| `critMult`   | `BD.config.critMult` — default `2.0` (see issue #22)            |
| `haste`      | `GetHaste()` — percentage (e.g., `20` = 20%)                    |
| `gcd`        | `StatFormulas.computeGcd(haste)` — computed base GCD in seconds  |

### `StatCollector.getSpellStats(spellID)` → `{castTime, resourceCost, description}` or `nil`

Returns a cached table of per-spell stats, or `nil` for invalid spellIDs. Results are cached per-cycle by spellID.

| Field          | Source                                                                                     |
| -------------- | ------------------------------------------------------------------------------------------ |
| `castTime`     | `C_Spell.GetSpellInfo(spellID).castTime / 1000` — milliseconds to seconds; `0` for instants or invalid spellIDs |
| `resourceCost` | `C_Spell.GetSpellPowerCost(spellID)[1].cost` — nil-safe; `0` for costless or free spells  |
| `description`  | Raw description text for passing to `DescriptionParser.parse()`; `nil` for invalid spellIDs |

### `StatCollector.refresh()`

Clears the per-cycle spell cache and the player stats cache. Called by `EventHandler` after the throttle window elapses. **No-op in combat** — see Caching Strategy below.

### `StatCollector.setCombat(state)`

Records combat state, driven by `PLAYER_REGEN_DISABLED` / `PLAYER_REGEN_ENABLED` in `EventHandler`. The gate lives here rather than at the event layer because the slash commands, the options panel and `ACTIONBAR_SLOT_CHANGED` all reach the renderer without passing through `EventHandler`'s throttle.

### Caching Strategy

Player stats are cached once per cycle (global across all spells). Spell stats are cached per-cycle by spellID. Both caches are invalidated together on each `refresh()` call.

In combat both caches freeze together: `refresh()` returns without clearing either, so every overlay and tooltip number holds its last out-of-combat value until combat ends. Freezing the spell cache too is not incidental — spell descriptions keep interpolating live player stats while restricted, so freezing player stats alone would render a live description base multiplied by frozen crit and haste.

## Integration Contract

This is the merge pattern downstream callers (issue #7 actionbar overlays, issue #8 tooltip enrichment) must follow to assemble the `stats` table that `Calculator.computeMetrics()` expects.

```lua
-- How to build the Calculator stats table (for issues #7 and #8)
local spellStats   = BD.StatCollector.getSpellStats(spellID)
if not spellStats then return end  -- invalid or empty spellID

local playerStats  = BD.StatCollector.getPlayerStats()
if not playerStats then return end  -- stats unreadable (combat restrictions), nothing cached

-- Assemble Calculator-compatible stats table
local stats = {
    critChance   = playerStats.critChance,
    critMult     = playerStats.critMult,
    castTime     = spellStats.castTime,
    gcd          = playerStats.gcd,
    resourceCost = spellStats.resourceCost,
}

-- Parse description separately
local components = BD.DescriptionParser.parse(spellStats.description)
local result     = BD.Calculator.computeMetrics(components, stats)
```

`description` is passed to `DescriptionParser.parse()`, not directly to `computeMetrics()`. The nil-check guard above (line 3) handles invalid or empty spellIDs — `getSpellStats()` returns `nil` for those cases.

## EventHandler

### Registered Events

Ten events are registered at module load time:

| Event                        | Trigger                                                    |
| ---------------------------- | ---------------------------------------------------------- |
| `PLAYER_ENTERING_WORLD`      | Initial stat load on login/reload                          |
| `ACTIONBAR_SLOT_CHANGED`     | Spell changed on actionbar                                 |
| `PLAYER_EQUIPMENT_CHANGED`   | Gear change (may affect stats)                             |
| `UNIT_AURA`                  | Buff/debuff change (player-only via `RegisterUnitEvent`)   |
| `COMBAT_RATING_UPDATE`       | Stat rating change                                         |
| `PLAYER_TARGET_CHANGED`      | Target change (for future overlay use)                     |
| `PLAYER_TALENT_UPDATE`       | Talent point assignment change                             |
| `ACTIVE_TALENT_GROUP_CHANGED` | Active specialization switched                            |
| `PLAYER_REGEN_DISABLED`      | Entering combat — freezes both caches, no refresh          |
| `PLAYER_REGEN_ENABLED`       | Leaving combat — unfreezes, then refreshes                 |

`UNIT_AURA` is pre-filtered at the API level via `frame:RegisterUnitEvent("UNIT_AURA", "player")`. The `OnEvent` callback receives no `unit` parameter and performs no in-handler unit guard.

### Throttle Mechanism

Events set a boolean dirty flag rather than triggering an immediate refresh. A single `OnUpdate` handler
accumulates elapsed time and fires `BD.StatCollector.refresh()` when `elapsed >= 0.1s`. After refreshing,
the dirty flag is cleared and the OnUpdate script is unregistered — no polling overhead occurs between events.

```text
Event fires → setDirty() → OnUpdate registered
OnUpdate fires each frame → accumulates elapsed
elapsed >= 0.1s and dirty → refresh() → dirty=false → OnUpdate unregistered
```

## Design Decisions

**Two-tier API (not one flat `getStats(spellID)`)**: Player stats are global and cached once per cycle;
spell stats are per-spellID. When multiple spells are evaluated in the same cycle (e.g., scanning an entire
actionbar), player stats are fetched only once. A flat API would call `GetSpellCritChance()` and `GetHaste()`
for every spellID.

**`critMult` from `BD.config`**: Avoids hardcoding in `StatCollector`. The default `2.0` is declared in `Config/Defaults.lua`. Per-spell crit multiplier detection is tracked in issue #22.

**GCD extracted to `Engine/StatFormulas.lua`**: The GCD formula contains no WoW API calls — it is pure math. Placing it in Engine satisfies the Portability Test and makes it directly testable in busted without any WoW mocks.

**0.1s throttle**: Balances responsiveness (numbers update quickly after a gear change) against performance (avoids recalculating on every frame during a burst of rapid events on login or spec swap).

**Dirty flag + self-unregistering OnUpdate**: The frame's `OnUpdate` is only active between an event and the completion of the next refresh cycle. When the player is idle, there is zero per-frame work from this system.

**Combat gate inside `StatCollector`, not `EventHandler`**: `UNIT_AURA` still dirties the caches in combat, and the refresh it schedules still runs — it simply no-ops. Placing the gate at the cache rather than at the event catches the callers that bypass the throttle entirely (slash commands, options panel, `ACTIONBAR_SLOT_CHANGED`).

## Known Limitations

**All metrics freeze in combat**: player stats are secret values under combat restrictions since patch 12.0.5, and every metric in the current design depends on crit chance or haste. Numbers hold their last out-of-combat value; a session that *begins* in combat with nothing cached shows no overlays and no tooltip enrichment until combat ends. Frozen numbers carry no staleness cue. Restoring correct in-combat numbers is tracked in issue #48; the reasoning is recorded in [Secret-Value Taint Boundary](../Decisions/2026-08-15-secret-value-taint-boundary.md).


**`critMult` hardcoded to 2.0**: The WoW API does not reliably expose per-spell crit multipliers. All spells use 200% crit damage. Detection and configuration improvement is tracked in issue #22.

**GCD base assumes 1.5s**: Standard spellcaster GCD. Melee abilities (1.0s base GCD) and GCD-immune abilities are not modeled. Per-class GCD base adjustment is a future improvement.

**No spell school crit**: `GetSpellCritChance()` is called without a school argument, returning the global spell crit chance. Per-school crit differentiation is deferred post-v1.
