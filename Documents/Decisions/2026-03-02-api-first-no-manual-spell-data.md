# API-First Approach — No Manual Spell Data Tables

**Date**: 2026-03-02  
**Issue**: [#1 — Project Bootstrap](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/1)  
**Status**: Approved

## Context

The original DrDamage addon was abandoned around 2013 because every expansion required manually updating per-class Lua data files with
hardcoded spell formulas. Monks were never supported because adding a new class required a full data file rewrite. The core failure mode
was that the addon's accuracy was coupled to volunteer maintenance effort that didn't scale with WoW's expansion cadence.

WoW's modern API includes `C_Spell.GetSpellDescription(spellID)`, which returns a pre-formatted description string containing the
spell's actual damage/healing values — already accounting for spell power, versatility, and other scaling factors that Blizzard applies
server-side. This makes the addon's data self-updating: any time Blizzard buffs or nerfs a spell, the description string changes automatically.

Additional stat APIs (`GetSpellCritChance()`, `GetHaste()`, `GetMasteryEffect()`, etc.) provide the multipliers needed to compute DPS and efficiency metrics. Together, these APIs give BlazDamage everything it needs without any hand-authored spell data.

## Decisions

### 1. Use `C_Spell.GetSpellDescription()` as Primary Data Source

**Choice**: Parse spell description strings returned by the API instead of maintaining spell formula tables.  
**Rationale**: Blizzard maintains these values — they update automatically with patches, buffs, nerfs, and new expansions. The addon stays correct across the entire WoW content lifecycle with zero human intervention.  
**Impact**: Engine must contain a description parser that extracts numeric values from strings like "Deals 1,234 to 5,678 Nature damage."
This is the core technical challenge of the project. The parser must handle locale-specific number formatting (commas, periods) and
variable string structures across different spell types.

### 2. No Manual Per-Class Spell Data

**Choice**: No `Data/` table files with per-class, per-spell formulas.  
**Rationale**: This is the explicit lesson from DrDamage's failure. Any manual data creates maintenance debt that scales O(N) with spells × classes × expansions. The burden compounds each patch cycle and eventually causes abandonment.  
**Impact**: Spells whose descriptions don't contain parseable numbers (e.g., procs, passive abilities, aura effects) will simply be skipped — graceful degradation accepts incomplete coverage over maintenance burden. The addon shows overlays only on spells it can compute confidently.

## References

- [GitHub Issue #1](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/1)
- [GitHub Issue #2](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/2) — Implementation details
- [Documents/Development/TechnicalArchitecture.md](../Development/TechnicalArchitecture.md) — Calculation pipeline
