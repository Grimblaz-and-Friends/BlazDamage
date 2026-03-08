# Addon Skeleton Design

The addon skeleton establishes the foundational framework that all other BlazDamage modules build on.

## Namespace Pattern

Every TOC-loaded file receives the addon namespace via varargs:

```lua
local addonName, BD = ...
```

WoW passes the addon name string as the first vararg and a shared table as the second. `BD` is the shared namespace table — all modules attach themselves to it (`BD.Calculator`, `BD.defaults`, etc.).

For Engine modules (loaded via `require()` in busted tests), the second vararg is nil — modules must guard with `BD = BD or {}` and `return` their module table for busted compatibility.

## Bootstrap Sequence

1. `Config/Defaults.lua` — loaded first (TOC order); sets `BD.defaults = {...}`
2. `Core.lua` — loaded second; registers events, initializes SavedVariables, registers slash commands

## SavedVariables Pattern

```lua
-- In Core.lua ADDON_LOADED handler:
BlazDamageDB = BlazDamageDB or {}
BD.config = BlazDamageDB
```

WoW injects `BlazDamageDB` as a global (declared in the TOC with `## SavedVariables: BlazDamageDB`). On first login the global is nil — the `or {}` creates a fresh table. On subsequent logins WoW repopulates it from disk. `BD.config` is the live in-memory reference all modules use to read/write settings.

## Slash Commands

Both `/blazdamage` and `/bd` are registered as aliases for the same handler group:

```lua
SLASH_BLAZDAMAGE1 = "/blazdamage"
SLASH_BLAZDAMAGE2 = "/bd"
SlashCmdList["BLAZDAMAGE"] = function(msg) ... end
```

WoW dispatches `/blazdamage` and `/bd` both to `SlashCmdList["BLAZDAMAGE"]`. A `SLASH_BD1 = "/bd"` entry (different suffix prefix) would require a corresponding `SlashCmdList["BD"]` — they are distinct command groups.

## Event Bootstrap

```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        -- initialization
    end
end)
```

ADDON_LOADED fires for every addon, so the `name == addonName` guard is required. All one-time initialization (SavedVars, config, registering other events) happens in this handler.

## Acceptance Criteria

- [ ] Addon loads without Lua errors on `/reload`
- [ ] `/bd` and `/blazdamage` both print the current version
- [ ] `BD.config` is non-nil after login
- [ ] `BD.defaults` persists default values before config is loaded
- [ ] Engine modules authored with the `BD = BD or {}` guard and `return Module` pass `require()` in busted tests
