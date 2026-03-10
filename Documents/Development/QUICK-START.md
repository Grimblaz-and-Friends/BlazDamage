# Quick Start

## Prerequisites

- **Lua 5.1** — [lua.org](https://www.lua.org/download.html)
- **luarocks** — [luarocks.org](https://luarocks.org/)
- **busted** — `luarocks install busted`
- **luacheck** — `luarocks install luacheck`
- **PowerShell** (`pwsh`) — for architecture validation
- **World of Warcraft Retail** (Midnight, Interface 12.x)

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/Grimblaz-and-Friends/BlazDamage.git
```

### 2. Symlink into WoW AddOns

**Windows:**

```powershell
# Requires admin/UAC — WoW is installed under C:\Program Files\ by default
cmd /c mklink /J "C:\Program Files\World of Warcraft\_retail_\Interface\AddOns\BlazDamage" "C:\path\to\BlazDamage"
```

Or copy the folder directly into:

```text
C:\Program Files\World of Warcraft\_retail_\Interface\AddOns\BlazDamage\
```

### 3. Enable in WoW

Launch WoW → AddOns (on character select screen) → enable BlazDamage → log in.

Type `/bd` or `/blazdamage` to verify the addon loaded. You should see the current version printed in chat.

### Reload After Changes

After editing any `.lua` file, type `/reload` in-game to reload the UI without relaunching WoW.

## Development Setup

The repository is flat Lua — no build step required. Open the folder in VS Code with the recommended extensions:

- **sumneko.lua** (Lua Language Server) — IntelliSense and diagnostics
- **ketho.wow-api** — WoW API autocomplete
- **editorconfig.editorconfig** — consistent formatting

Recommended extensions are listed in `.vscode/extensions.json`.

**WoW API stubs**: `.vscode/settings.json` references `ketho.wow-api-0.22.3` for Lua Language Server WoW API completions. If your installed version differs, update the `Lua.workspace.library` path accordingly.

## Running Tests

Unit tests live in `Tests/` and run in standalone Lua via busted (no WoW required):

```bash
busted Tests/
```

Tests cover the `Engine/` layer only. UI layer code must be verified manually in-game.

## Linting

```bash
luacheck .
```

Uses `.luacheckrc` for configuration. WoW API globals are permitted in `UI/` and root files, but not in `Engine/` — luacheck enforces this per-layer.

## Architecture Validation

```bash
pwsh .github/scripts/validate-architecture.ps1
```

Scans `Engine/`, `Config/`, and `Data/` files for forbidden WoW API calls. Fails with a non-zero exit code if violations are found.

## Quick Validate (All Three)

```bash
luacheck . && pwsh .github/scripts/validate-architecture.ps1 && busted Tests/
```
