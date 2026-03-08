# Vision

## The Big Idea

BlazDamage displays calculated damage and healing metrics directly on your actionbar buttons, and injects enriched statistics into spell tooltips — without requiring hand-maintained spell data tables.

Where DrDamage showed you what your spells might do, BlazDamage shows you what they *actually* do given your current stats, using the same values the game itself computes.

## Who It's For

- **Performance-oriented players** who want to see DPS, average damage, or damage-per-mana values at a glance without opening a spreadsheet
- **Theory-crafters** who want live overlay numbers during gear comparison or talent experimentation
- **Anyone** who misses DrDamage and wants a maintained, modern replacement

## Platform Target

Retail WoW (Midnight, Interface 12.x). No Classic, no Cata Classic, no PTR-only features.

## Core Principles

1. **API-first** — Never maintain manual spell data. Use what Blizzard provides. If the API doesn't give us a value, skip that spell gracefully.
2. **Graceful degradation** — Incomplete coverage is acceptable. Wrong numbers are not. Skipping an unsupported spell is better than displaying an incorrect value.
3. **Zero maintenance burden** — New expansions, new patches, new specs should work automatically. If they don't, the architecture must be revisited, not band-aided with more manual data.
4. **Addon-agnostic** — Works with the default UI and all major actionbar addons (Bartender4, ElvUI, Dominos, etc.) without per-addon code.
5. **Class-agnostic** — The calculation engine makes no assumptions about class or spec. It receives plain numbers and returns plain numbers.

## Long-Term Direction

The v1 goal is a reliable, accurate overlay for damage spells. Later milestones expand to healing metrics, more display options, a configuration panel, and deeper tooltip enrichment. BlazDamage will remain an overlay-first tool — not a combat log parser, not a damage meter, not a theorycraft simulator.
