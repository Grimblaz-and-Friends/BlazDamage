# validate-architecture.ps1
#
# BlazDamage architecture validation script.
# Enforces the Engine/UI layer boundary by scanning Engine/, Config/, and Data/
# files for forbidden WoW API calls and frame references.
#
# Known limitation: Block comments (--[[ ... ]]) are not stripped before scanning.
# Patterns inside block comments may produce false positives. Single-line (--) comments
# are stripped. Address this limitation if false positives are encountered.
#
# Exit Codes:
#   0 = All validations passed
#   1 = One or more validations failed
#
# Usage:
#   pwsh .github/scripts/validate-architecture.ps1

[CmdletBinding()]
param()

$script:FailureCount = 0

$Red    = "`e[31m"
$Green  = "`e[32m"
$Yellow = "`e[33m"
$Reset  = "`e[0m"

function Write-ValidationHeader {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "${Green}✓${Reset} $Message"
}

function Write-Failure {
    param([string]$Message)
    Write-Host "${Red}✗${Reset} $Message"
    $script:FailureCount++
}

function Write-ValidationWarning {
    param([string]$Message)
    Write-Host "${Yellow}⚠${Reset} $Message"
}

# ==========================================
# Strip single-line Lua comments from content
# ==========================================
function Remove-LuaLineComments {
    param([string]$Content)
    # Remove from -- to end of line (but not inside strings — simplified approach)
    return ($Content -split "`n" | ForEach-Object {
        $_ -replace '--[^"]*$', ''
    }) -join "`n"
}

# ==========================================
# Forbidden WoW API patterns for Engine/Config/Data layers
# ==========================================

$ForbiddenPatterns = @(
    # C_ namespace API calls
    @{ Pattern = 'C_Spell\.';        Description = 'C_Spell API call' },
    @{ Pattern = 'C_UnitAuras\.';    Description = 'C_UnitAuras API call' },
    @{ Pattern = 'C_TooltipInfo\.';  Description = 'C_TooltipInfo API call' },
    @{ Pattern = 'C_ClassTalents\.'; Description = 'C_ClassTalents API call' },
    @{ Pattern = 'C_Traits\.';       Description = 'C_Traits API call' },
    # Stat functions
    @{ Pattern = 'GetSpellBonusDamage';  Description = 'WoW stat API call' },
    @{ Pattern = 'GetSpellBonusHealing'; Description = 'WoW stat API call' },
    @{ Pattern = 'GetSpellCritChance';   Description = 'WoW stat API call' },
    @{ Pattern = 'GetHaste';             Description = 'WoW stat API call' },
    @{ Pattern = 'GetMeleeHaste';        Description = 'WoW stat API call' },
    @{ Pattern = 'GetMasteryEffect';     Description = 'WoW stat API call' },
    @{ Pattern = 'GetVersatilityBonus';  Description = 'WoW stat API call' },
    # Unit functions
    @{ Pattern = 'UnitAttackPower'; Description = 'WoW unit API call' },
    @{ Pattern = 'UnitDamage';      Description = 'WoW unit API call' },
    @{ Pattern = 'UnitStat';        Description = 'WoW unit API call' },
    @{ Pattern = 'UnitLevel';       Description = 'WoW unit API call' },
    # Action functions
    @{ Pattern = 'GetActionInfo'; Description = 'WoW action API call' },
    @{ Pattern = 'HasAction';     Description = 'WoW action API call' },
    @{ Pattern = 'IsUsableAction'; Description = 'WoW action API call' },
    # Frame & UI
    @{ Pattern = 'CreateFrame';            Description = 'Frame creation' },
    @{ Pattern = 'UIParent';               Description = 'Frame reference' },
    @{ Pattern = 'GameTooltip';            Description = 'Tooltip reference' },
    @{ Pattern = 'InterfaceOptionsFrame';  Description = 'UI frame reference' },
    @{ Pattern = 'hooksecurefunc';         Description = 'Secure function hook' },
    # Event system
    @{ Pattern = 'RegisterEvent';   Description = 'Event registration' },
    @{ Pattern = 'UnregisterEvent'; Description = 'Event unregistration' },
    @{ Pattern = 'SetScript';       Description = 'Script handler registration' },
    # Global state
    @{ Pattern = 'SlashCmdList'; Description = 'Slash command global' },
    @{ Pattern = 'SLASH_';       Description = 'Slash command prefix global' }
)

function Test-LayerViolations {
    param(
        [string]$LayerPath,
        [string]$LayerName
    )

    $Files = Get-ChildItem -Path $LayerPath -Filter "*.lua" -Recurse -ErrorAction SilentlyContinue
    if (-not $Files) {
        Write-ValidationWarning "${LayerName}: no .lua files found (directory may be empty — this is expected early in development)"
        return
    }

    $ViolationCount = 0
    foreach ($File in $Files) {
        $RawContent = Get-Content $File.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $RawContent) { continue }

        # Strip single-line comments before scanning
        $Content = Remove-LuaLineComments -Content $RawContent

        foreach ($Entry in $ForbiddenPatterns) {
            if ($Content -match $Entry.Pattern) {
                Write-Failure "$LayerName layer violation in $($File.Name): $($Entry.Description) (pattern: $($Entry.Pattern))"
                $ViolationCount++
            }
        }
    }

    if ($ViolationCount -eq 0) {
        Write-Success "${LayerName}: no layer violations in $($Files.Count) file(s)"
    }
}

# ==========================================
# VALIDATION: Directory Structure
# ==========================================
function Test-DirectoryStructure {
    Write-ValidationHeader "Directory Structure"

    $RequiredDirectories = @(
        "Engine",
        "UI",
        "Config",
        ".github/scripts"
    )

    foreach ($Dir in $RequiredDirectories) {
        if (Test-Path $Dir) {
            Write-Success "Directory exists: $Dir"
        } else {
            Write-Failure "Missing required directory: $Dir"
        }
    }
}

# ==========================================
# VALIDATION: Required Files
# ==========================================
function Test-RequiredFiles {
    Write-ValidationHeader "Required Files"

    $RequiredFiles = @(
        "README.md",
        ".gitignore",
        ".luacheckrc",
        "BlazDamage.toc",
        "Core.lua",
        "Config/Defaults.lua",
        ".github/copilot-instructions.md",
        ".github/architecture-rules.md"
    )

    foreach ($File in $RequiredFiles) {
        if (Test-Path $File) {
            Write-Success "File exists: $File"
        } else {
            Write-Failure "Missing required file: $File"
        }
    }
}

# ==========================================
# VALIDATION: Engine Layer Violations
# ==========================================
function Test-EngineLayerViolations {
    Write-ValidationHeader "Engine Layer — WoW API Violations"

    if (-not (Test-Path "Engine")) {
        Write-ValidationWarning "Engine/ directory not found — skipping"
        return
    }

    Test-LayerViolations -LayerPath "Engine" -LayerName "Engine"
}

# ==========================================
# VALIDATION: Config Layer Violations
# ==========================================
function Test-ConfigLayerViolations {
    Write-ValidationHeader "Config Layer — WoW API Violations"

    if (-not (Test-Path "Config")) {
        Write-ValidationWarning "Config/ directory not found — skipping"
        return
    }

    Test-LayerViolations -LayerPath "Config" -LayerName "Config"
}

# ==========================================
# VALIDATION: Data Layer Violations
# ==========================================
function Test-DataLayerViolations {
    Write-ValidationHeader "Data Layer — WoW API Violations"

    if (-not (Test-Path "Data")) {
        Write-ValidationWarning "Data/ directory not found — skipping"
        return
    }

    Test-LayerViolations -LayerPath "Data" -LayerName "Data"
}

# ==========================================
# MAIN
# ==========================================
Write-Host "BlazDamage Architecture Validation" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

Test-DirectoryStructure
Test-RequiredFiles
Test-EngineLayerViolations
Test-ConfigLayerViolations
Test-DataLayerViolations

Write-Host ""
if ($script:FailureCount -eq 0) {
    Write-Host "${Green}All validations passed.${Reset}"
    exit 0
} else {
    Write-Host "${Red}$($script:FailureCount) validation(s) failed.${Reset}"
    exit 1
}
