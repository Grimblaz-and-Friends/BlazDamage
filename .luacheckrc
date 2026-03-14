-- BlazDamage Luacheck configuration

std = "lua51"

-- Exclude luarocks-installed packages from linting (vendor code, not ours)
exclude_files = {".luarocks/**"}

-- WoW API globals — minimal set covering what's actually used at the root/UI level
-- Expand this list as new WoW API calls are added in UI/ files
stds.wow = {
    globals = {
        -- Slash commands
        "SlashCmdList",
        "SLASH_BLAZDAMAGE1",
        "SLASH_BLAZDAMAGE2",
        -- C_ namespaces
        "C_Spell",
        "C_AddOns",
        "C_UnitAuras",
        "C_TooltipInfo",
        "C_ClassTalents",
        "C_Traits",
        "TooltipDataProcessor",
        "Enum",
        -- SavedVariables
        "BlazDamageDB",
        -- Stat functions
        "GetSpellBonusDamage",
        "GetSpellBonusHealing",
        "GetSpellCritChance",
        "GetHaste",
        "GetMeleeHaste",
        "GetMasteryEffect",
        "GetVersatilityBonus",
        -- Unit functions
        "UnitAttackPower",
        "UnitDamage",
        "UnitStat",
        "UnitLevel",
        -- Action functions
        "ActionBarButtonEventsFrame_RegisterFrame",
        "GetActionInfo",
        "HasAction",
        "IsUsableAction",
        -- Frame / UI
        "CreateFrame",
        "NumberFontNormalSmall",
        "UIParent",
        "GameTooltip",
        "InterfaceOptionsFrame",
        "hooksecurefunc",
        -- Addon loading
        "IsAddOnLoaded",
    },
}

-- Root-level and UI-layer files: get Lua 5.1 + WoW API globals
files["Core.lua"] = { std = "lua51+wow" }
files["UI/**/*.lua"] = { std = "lua51+wow" }

-- Config layer: pure Lua only (no WoW API), but allow addon namespace
files["Config/**/*.lua"] = { std = "lua51" }

-- Data layer: pure Lua only
files["Data/**/*.lua"] = { std = "lua51" }

-- Engine layer: strictly pure Lua — ZERO WoW globals
-- This is the primary enforcement of the Engine/UI architecture invariant
files["Engine/**/*.lua"] = { std = "lua51" }

-- Test files: pure Lua + busted globals
files["Tests/**/*.lua"] = {
    std = "lua51",
    read_globals = { "describe", "it", "before_each", "after_each", "setup", "teardown", "assert", "spy", "mock", "stub" },
}

ignore = {
    "212",  -- Unused argument (common in WoW callbacks with fixed signatures)
}
