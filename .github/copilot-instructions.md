# Project: BlazDamage

## Overview

WoW addon that displays calculated damage/healing metrics on actionbar buttons and enriches spell tooltips — a modern successor to DrDamage using the WoW API (no manual spell data).

## Technology Stack

- **Language**: Lua 5.1 (WoW API runtime)
- **Platform**: World of Warcraft Retail (Midnight, Interface 12.x)
- **Framework**: None (pure WoW addon — Ace3 optional later)
- **Database**: None (WoW SavedVariables for persistence)
- **Build Tool**: None (WoW addons are pure Lua — no transpilation or bundling)
- **Testing**: busted (BDD-style Lua test framework, runs in standalone Lua 5.1)
- **Linting**: Luacheck (with community WoW API stubs from ketho/wow-api)

## Architecture

Layered architecture with strict Engine/UI separation:

```text
┌─────────────────────────────────────────────────┐
│                      UI/                         │
│    WoW frames, hooks, events, overlays,         │
│    tooltips, options panel, actionbar discovery  │
├─────────────────────────────────────────────────┤
│                   Engine/                        │
│    Pure Lua calculation logic — stat math,      │
│    damage formulas, metric computation          │
├─────────────────────────────────────────────────┤
│                   Config/                        │
│    Pure Lua constants and saved variable defaults│
├─────────────────────────────────────────────────┤
│                    Data/                         │
│    Static lookup tables (override data if needed)│
└─────────────────────────────────────────────────┘
```

**The Portability Test**: _"Would this code run unmodified in a standalone Lua 5.1 interpreter with no WoW API?"_

- **YES** → belongs in `Engine/` or `Config/`
- **NO** → belongs in `UI/`

See `.github/architecture-rules.md` for full layer rules, dependency constraints, and violation examples.

## Directory Structure

```text
BlazDamage/
├── .github/
│   ├── copilot-instructions.md   # This file — agent project context
│   ├── architecture-rules.md     # Layer boundary rules and examples
│   ├── instructions/             # Workflow instruction files
│   ├── scripts/                  # Validation scripts
│   └── workflows/                # GitHub Actions CI
├── Config/
│   └── Defaults.lua              # SavedVariables defaults
├── Data/                         # Static lookup tables (if needed)
├── Engine/                       # Pure Lua — calculations, parsing
├── Libs/                         # Embedded libraries (Ace3, etc.)
├── Tests/                        # busted unit tests (Engine layer)
├── UI/                           # WoW frames, hooks, overlays, tooltips
├── Documents/
│   ├── Design/                   # Design documents (committed with PRs)
│   ├── Decisions/                # Architecture Decision Records
│   └── Development/              # Vision, roadmap, quick-start, etc.
├── BlazDamage.toc                # WoW addon metadata
├── Core.lua                      # Addon entry point, namespace init
├── .luacheckrc                   # Luacheck configuration
├── .editorconfig                 # Formatting defaults
└── README.md
```

## Key Conventions

### Lua

- **Indentation**: 4-space (WoW addon community convention)
- **Module naming**: PascalCase for module tables (`Calculator`, `StatCollector`)
- **Method naming**: camelCase for functions and methods (`calculateDps`, `parseDescription`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_OVERLAY_UPDATE_RATE`, `DEFAULT_METRIC`)
- **Locals**: Always use `local` — never pollute the global namespace
- **Addon namespace**: Access via `local addonName, BD = ...` in each file listed in the TOC

### Banned Suffixes

Do not use `*Helper`, `*Utils`, or `*Manager` as module names. These are vague — name modules by what they do (e.g., `DamageCalculator` not `DamageHelper`).

### Engine Layer Rules

- Engine files must contain **zero** WoW API calls
- Engine functions take plain Lua values (numbers, strings, tables) as input
- Engine is testable with busted in a standalone Lua 5.1 interpreter
- Never `require` or reference WoW globals (`C_Spell`, `CreateFrame`, `GameTooltip`, etc.)

### UI Layer Rules

- UI files handle all WoW API interaction (events, frames, hooks)
- UI calls Engine functions for all calculations — never duplicate formulas
- UI converts WoW API outputs into plain Lua values before passing to Engine

### Error Handling

- Graceful degradation: if spell description parsing fails, skip that spell (no errors, no wrong numbers)
- Use `pcall` / `xpcall` for WoW API calls that may fail
- Log warnings via `print()` prefixed with `|cFFFFFF00BlazDamage:|r` for in-game visibility

## Build & Run

```bash
# No build step — WoW addons are pure Lua

# Install the addon (symlink or copy to WoW AddOns directory):
# Windows:
# mklink /D "C:\Program Files\World of Warcraft\_retail_\Interface\AddOns\BlazDamage" "C:\path\to\BlazDamage"

# Reload in-game:
# /reload

# Run unit tests (standalone Lua, not in WoW):
busted Tests/

# Lint:
luacheck .

# Architecture validation:
pwsh .github/scripts/validate-architecture.ps1
```

## Quick-Validate

```bash
luacheck . && pwsh .github/scripts/validate-architecture.ps1 && busted Tests/
```

## Code Review Configuration

```yaml
critic_passes: 3
```

## Related Documentation

- Architecture Rules: `.github/architecture-rules.md`
- Documentation Hub: `Documents/index.md`
