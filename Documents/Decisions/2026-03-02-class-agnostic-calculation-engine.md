# Class-Agnostic Calculation Engine

**Date**: 2026-03-02  
**Issue**: [#1 — Project Bootstrap](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/1)  
**Status**: Approved

## Context

DrDamage's original failure mode was per-class, per-spell manual data — separate Lua files for Warrior, Mage,
Priest, and other classes. Each new class (Monk, Demon Hunter, Evoker) required a full data file authored from
scratch. Each expansion reset those files as spell coefficients changed. The person-hours required grew without
bound and eventually exceeded what the maintainer could sustain.

WoW's modern API returns spell descriptions that are already class-appropriate. The same
`C_Spell.GetSpellDescription(spellID)` call returns the correct values for a Mage's Fireball and a Shaman's Lava
Burst — Blizzard's backend applies all class-specific scaling before delivering the string. The addon receives
already-correct base values.

The core damage calculation — applying crit chance, haste, mastery, and versatility multipliers from stat APIs —
is mathematically identical regardless of class and spec. No class-conditional branching is required. Some
spell-specific mechanics (guaranteed crits, proc interactions, execute-range bonuses) may require edge-case
handling that cannot be fully generalized, but these are exceptions, not the common case.

## Decisions

### 1. Single Engine for All Classes

**Choice**: Implement one `Engine/Calculator.lua` that takes `(baseValue, critChance, critMult, haste, mastery,
versatility)` as plain numeric inputs and returns computed metrics.  
**Rationale**: The WoW API already handles class-specific spell scaling internally — the addon receives
already-correct values. No class identity is needed inside the engine. The same function serves a Frost Mage and
an Assassination Rogue without modification.  
**Impact**: Engine is testable with arbitrary numeric inputs in a standalone Lua 5.1 interpreter, completely
independent of any specific class or spec. Test coverage does not require mocking class data.

### 2. Class-Specific Overrides Only If Needed

**Choice**: If specific spells produce systematically wrong results (e.g., guaranteed-crit spells where the crit
multiplier should always apply at full value), add narrow override entries to `Data/` — not to `Engine/`.  
**Rationale**: Most spells will not need overrides. Adding override logic to `Engine/` would reintroduce the
per-spell maintenance pattern that caused DrDamage's failure. Isolating exceptions in `Data/` keeps the
calculation logic clean and ensures overrides are auditable in one place.  
**Impact**: Minimal initial `Data/` usage. Override entries are added only when a concrete in-game discrepancy is
discovered and verified — not speculatively added upfront.

### 3. Validate with At Least 3 Test Classes

**Choice**: Before v1 release, verify overlay numbers are correct for at least 3 distinct specs across different
damage schools (e.g., a melee class, a ranged physical class, and a spellcaster).  
**Rationale**: A single class might produce correct results accidentally if two bugs cancel each other. Multiple
classes across different damage schools stress the engine more thoroughly and increase confidence that the
calculation is genuinely correct rather than coincidentally accurate.  
**Impact**: A manual in-game verification step is required before v1 is considered complete. Results should be
documented in `Documents/Development/TestingStrategy.md`.

## References

- [GitHub Issue #1](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/1)
- [GitHub Issue #2](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/2) — Engine implementation details
- [Documents/Development/TechnicalArchitecture.md](../Development/TechnicalArchitecture.md)
- [Documents/Development/TestingStrategy.md](../Development/TestingStrategy.md)
