# BlazDamage

A modern spiritual successor to [DrDamage](https://www.curseforge.com/wow/addons/dr-damage) for **Retail WoW** (The War Within / Midnight).

BlazDamage displays calculated damage and healing metrics directly on your actionbar buttons, and injects enriched statistics into spell tooltips — all without manually maintained spell data.

## Features

- **Actionbar Overlays** — Calculated damage/healing numbers displayed on each actionbar button (user-configurable metric: avg, DPS, DPSC, DPM, etc.)
- **Enriched Tooltips** — Detailed statistics appended to spell tooltips in the spellbook and on the actionbar (avg damage, crit chance, DPS, efficiency metrics)
- **Dynamic Updates** — Overlays and tooltips update automatically when gear, buffs, or your target changes
- **Addon-Agnostic** — Works with Blizzard's default actionbars and third-party bar addons (Bartender4, ElvUI, Dominos, etc.)
- **API-First** — No hand-maintained spell tables; all values derived from the modern WoW API

## Why Not Just Use DrDamage?

DrDamage was abandoned around 2013 (Mists of Pandaria). It died because every expansion required manually updating per-class Lua data files with hardcoded spell formulas — an unsustainable maintenance burden. Monks were never even supported.

BlazDamage solves this by leaning entirely on the modern WoW API: `C_Spell.GetSpellDescription()` returns pre-calculated damage/healing values, and stat APIs (`GetSpellCritChance()`, `GetHaste()`, `GetMasteryEffect()`, etc.) provide the multipliers. No manual spell data, no expansion-breaking maintenance cycles.

## Status

> **Early development** — infrastructure and documentation are being established. Feature implementation has not started.

See [Issue #2](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/2) for the v1 feature roadmap.

## Quick Start

> Full setup instructions: [Documents/Development/QUICK-START.md](Documents/Development/QUICK-START.md) *(coming soon)*

**Prerequisites:** Lua 5.1, [luarocks](https://luarocks.org/), [busted](https://lunarmodules.github.io/busted/), [luacheck](https://github.com/mpeterv/luacheck), PowerShell (`pwsh`)

```bash
git clone https://github.com/Grimblaz-and-Friends/BlazDamage.git
```

Copy or symlink the repo folder into your WoW AddOns directory, then `/reload` in-game.

## Documentation

See [Documents/index.md](Documents/index.md) for the full documentation hub *(coming soon)*.

## Contributing

Run `luacheck .` before every commit.
Run `pwsh .github/scripts/validate-architecture.ps1` before every PR.

See [.github/architecture-rules.md](.github/architecture-rules.md) for code architecture guidelines *(coming soon)*.

### Architecture in brief

| Layer | Directory | Rule |
| --- | --- | --- |
| **Engine** | `Engine/` | Pure Lua. No WoW API. Unit-testable with busted. |
| **UI** | `UI/` | WoW frames, hooks, events. Calls Engine for all calculations. |
| **Config** | `Config/` | Pure Lua constants and saved variable defaults. |

**The rule:** if the code would run unmodified in a standalone Lua 5.1 interpreter with no WoW API — it belongs in `Engine/`.
