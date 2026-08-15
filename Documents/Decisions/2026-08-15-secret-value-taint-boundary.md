# Secret-Value Taint Boundary and the In-Combat Freeze

**Date**: 2026-08-15
**Status**: Approved
**Issues**: [#46](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/46) (primary),
[#48](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/48) (correct in-combat numbers)

## Context

Patch 12.0.5 made most player-stat APIs return **secret values** whenever auras are secret — that
is, in combat, encounters, Mythic+ and PvP. Both stats this addon reads are on that list:
`GetSpellCritChance()` and `GetHaste()` are annotated `SecretWhenUnitStatsRestricted`.

A secret value may be stored, concatenated and passed to `string.format`. It may **not** be used in
arithmetic or comparison, indexed, used as a table key, or measured with `#`. Every one of those is
what `Engine/StatFormulas.lua` does the moment it receives one — `critPercent / 100` at `:25`,
`1 + hastePercent / 100` and `denom <= 0` at `:16-17`.

Two properties of this codebase make that a structural problem rather than a local bug:

1. **`Engine/` is pure Lua and cannot defend itself.** It has no access to `issecretvalue`, and per
   the Portability Test it must not gain any. A secret that crosses into Engine throws, and Engine
   cannot tell why.
2. **Nothing mechanical can catch a regression.** `.github/scripts/validate-architecture.ps1` scans
   Engine for forbidden API *calls*, not for tainted *inputs*. Engine specs construct plain numbers
   by hand, so no busted test can ever observe a secret. A future contributor who adds a
   stat-consuming metric to `Calculator.lua` and a matching read outside the guard takes the suite
   from 189 green to 190 green while the addon errors on every pull.

That second point is why this is an ADR and not a code comment.

An in-game probe on 12.1.0.69299 ([results](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/46#issuecomment-5300237154))
established the two facts this decision turns on: in combat on a target dummy, `GetHaste` and
`GetSpellCritChance` both report SECRET, while `C_Spell.GetSpellDescription` stays plain — **and
keeps interpolating live player stats into its text while restricted**.

## Decisions

### 1. The Taint Boundary Is `UI/StatCollector.lua`, at Read Time

**Choice**: Every WoW API return read in `UI/StatCollector.lua` is guarded immediately after the
call and **before** any arithmetic, unit conversion, or use as an Engine-function argument.
`issecretvalue()` is asked first and unconditionally, ahead of any type check or `nil` comparison,
because those tests are themselves illegal on a secret.

**Rationale**: The obvious placement — guarding the table `getPlayerStats()` returns — is provably
too late. The old `StatCollector.lua:16` and `:19` passed raw API returns straight into
`critToFraction()` and `computeGcd()` inside the table constructor, so the secret reached Engine
before any exit guard could run. The same applies to the spell path's own `/1000` conversions.

**Impact**: `Engine/` continues to receive plain Lua numbers exactly as it does today and is
unmodified by this work. The invariant "no secret reaches Engine" has one enforcement site, and it
is a file the Portability Test already assigns to the UI layer.

### 2. The Guard's Failure Contract Is All-or-Nothing

**Choice**: On any unreadable stat, `getPlayerStats()` returns `nil` — never a partial table. Both
consumers nil-check before indexing: `UI/OverlayRenderer.lua` hides the overlay,
`UI/TooltipEnricher.lua` skips enrichment. A failed read is not cached, so the next refresh
retries.

**Rationale**: A partial table is worse than no table. `Engine/Calculator.lua:30` guards only the
`stats` table itself, not its fields, and `:32`'s `math.max(stats.castTime, stats.gcd)` throws on a
nil `gcd` — inside Engine, which this work may not modify. Degrading at the boundary keeps the
failure in the layer that understands it. Both consumers had to change: `TooltipEnricher` runs on
hover via `TooltipDataProcessor`, so it is not masked by the overlay path and errored independently.

**Impact**: Graceful degradation per the repo convention — a spell whose stats cannot be read is
skipped, not errored on.

### 3. Both Caches Freeze in Combat, Gated Inside `StatCollector`

**Choice**: the freeze has two halves. `StatCollector.refresh()` is a no-op while in combat, so
neither cache is invalidated; **and** `getPlayerStats()` / `getSpellStats()` refuse to populate a
cold entry while in combat, returning nil instead. Combat state is seeded from
`InCombatLockdown()` on `PLAYER_ENTERING_WORLD` and thereafter driven by `PLAYER_REGEN_DISABLED` /
`PLAYER_REGEN_ENABLED`; leaving combat also schedules a recompute through the existing throttle.
Out of combat, `UNIT_AURA` dirties both caches exactly as before.

**Rationale, on why gating invalidation alone is not enough**: this is the correction an adversarial
review made to the first implementation, and it is the whole point of the decision. Stopping
`refresh()` freezes the entries that already exist; it does nothing about a **cache miss**. A spell
first seen mid-fight — hovered in the spellbook, swapped onto a bar, discovered by the actionbar
hook — would take a live description read, and that description carries *current* interpolated
stats while `getPlayerStats()` is frozen at its last out-of-combat values. The result is exactly the
mixed number this decision exists to prevent, cached and pinned for the rest of the fight. "Freeze
the caches" and "stop invalidating the caches" are not the same statement, and only the first one is
correct.

**Rationale, on seeding combat state**: `PLAYER_REGEN_*` are *transition* events. Without a seed, a
`/reload` taken mid-fight leaves the flag reading "out of combat" for the remainder of that fight,
and a `PLAYER_REGEN_ENABLED` missed across a loading screen latches it the other way with no path
back. `InCombatLockdown()` on `PLAYER_ENTERING_WORLD` reconciles both directions at every state
discontinuity.

**Rationale, on placement**: `Core.lua`'s slash commands, `UI/OptionsPanel.lua` and
`ACTIONBAR_SLOT_CHANGED` all reach the renderer without passing through `EventHandler`'s throttle,
so a gate at the event layer — the visually obvious spot — would miss them.

**Rationale, on freezing *both* caches**: this is what the probe changed. Because spell
descriptions keep interpolating live player stats during combat, freezing player stats alone would
render a **live** description base multiplied by **frozen** crit and haste. That is a mixed number,
not a stale one, and it is not something anyone can reason about. Freezing both yields a coherent
snapshot.

**Impact**: In combat, every overlay and tooltip number holds its last out-of-combat value. Not
just `avg` — `Engine/Calculator.lua:40` applies `stats.critChance` to every component and every
total derives from that, while `:32` makes `dps` depend on haste through the GCD, so **no** metric
in the current design is computable under restrictions. Anything *not* already cached shows nothing
rather than a number: a session that begins in combat, and equally any spell first encountered
mid-fight, hides until the first out-of-combat compute.

### 4. `GetSpellBaseCooldown` Is Not Modernized

**Choice**: Keep the bare global `GetSpellBaseCooldown`. Do not migrate it to
`C_Spell.GetSpellCooldown`.

**Rationale**: `C_Spell.GetSpellCooldown` is annotated `SecretWhenCooldownsRestricted`;
`GetSpellBaseCooldown` returns the static unmodified base value and carries no secret annotation.
The tempting modernization would import a restriction the current call does not have.

**Impact**: Recorded here because the call reads like an oversight and will be "fixed" otherwise.

## Consequences

- **The in-combat freeze is a stopgap, not the destination.** Issue #48 owns restoring correct
  in-combat numbers by reading the server-interpolated number out of the description instead of
  multiplying raw stats ourselves, and owns the product decision about what `avg` — the current
  default metric — should do in combat.
- **Frozen numbers do not look frozen.** No staleness cue ships with this change. The tooltip's
  `Crit:` line is the sharpest edge: it prints a labelled one-decimal percentage, which is a claim
  about current character state, and after a proc in combat it reads as confidently and
  specifically wrong.
- **The guard covers value-secrecy, and only that.** `issecretvalue()` answers one question. A
  restriction that returns nothing surfaces as a hidden overlay. A restriction that returns a
  degraded-but-plain value — a `0` where a real number belongs — passes the guard silently, and
  what happens next depends on the field: a `0` `resourceCost` or `cooldown` drops `dpm` and
  `dpscd` (`Engine/Calculator.lua:48`, `:72`, `:73`), which is the benign case, but a `0`
  `castTime` **is not** merely a dropped metric. It drops `dpsc`, and it also reaches
  `Calculator.lua:32`, where `timeOnTarget = math.max(castTime, gcd)` collapses to `gcd`, so `:45`
  still computes and displays a `dps` — inflated by roughly a third at a 1.5s GCD and more at the
  0.75s floor. `avg` displays unaffected. So the `0` fallbacks are safe for two of the three fields
  and produce a silently wrong number for the third. If numbers go missing inside an instance, do
  not conclude the guard worked; if they look plausible but high, suspect this.
- **Only the open-world restriction tier has been observed.** Delves and Mythic+ may restrict a
  wider API set; per `d-accept-instanced-tier-risk-46` this was knowingly left to be discovered in
  the field. If `C_Spell.GetSpellDescription` itself ever returns a secret, that voids this addon's
  core premise and #48's approach both — treat such a report as a design question, not a bug.
- **A future contributor adding a stat read must add it inside the guard.** No test or validator
  will tell them. That is what this record exists to say.

## References

- [GitHub Issue #46](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/46) — Midnight 12.1
  restoration; affirmed scope and approved brief
- [GitHub Issue #48](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/48) — correct
  in-combat numbers via description reading
- [In-game probe results](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/46#issuecomment-5300237154)
  — `GetHaste` / `GetSpellCritChance` secret in combat; description plain and live
- [Secret Values](https://warcraft.wiki.gg/wiki/Secret_Values) — permitted and forbidden
  operations, `issecretvalue`, `C_Secrets`
- [Patch 12.0.5/API changes](https://warcraft.wiki.gg/wiki/Patch_12.0.5/API_changes) — player stats
  become secrets
- [UI Foundation Design](../Design/ui-foundation.md) — `StatCollector` and `EventHandler` contracts
