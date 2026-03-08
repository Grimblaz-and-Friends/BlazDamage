# MVP Scope

Defines the feature boundary for BlazDamage v1.

## V1 Included

### Core Engine

- **Description parsing** — Extract min/max damage values from `C_Spell.GetSpellDescription()` output
- **Stat collection** — Read crit chance, haste, mastery, versatility, and spell power from WoW stat APIs
- **Damage calculation** — Compute average damage, DPS (damage × haste), and DPSC (damage per spell cost) from parsed + collected values
- **Metric selection** — User-configurable default metric (avg, dps, dpsc, dpm)

### UI Layer

- **Actionbar overlays** — Numeric display on each discoverable ActionButton frame
- **Actionbar discovery** — Generic hook via `hooksecurefunc("ActionButton_Update", ...)` — works with default UI and common third-party bar addons
- **Overlay updates** — Refresh overlays on PLAYER_ENTERING_WORLD, PLAYER_EQUIPMENT_CHANGED, UNIT_AURA (player), ACTIONBAR_SLOT_CHANGED

### Tooltip Enrichment

- **Spellbook tooltips** — Append computed stats (avg damage, crit, DPS) to spell tooltips in the spellbook
- **Actionbar tooltips** — Same enrichment on actionbar button hover

## V1 Excluded

These features are intentionally deferred:

| Feature | Reason for deferral |
| --- | --- |
| Healing prediction | Requires separate healing metric pipeline — v1.1 milestone |
| Multi-target AoE calculations | Complex — depends on target count and cleave models |
| WeakAuras / custom frame integration | Out of scope for generic hook approach |
| In-game options panel | Configuration via SavedVariables only in v1 |
| Masque / button skinning integration | Visual enhancement only — no impact on overlay correctness |
| Per-spell override data tables | Only added if specific spells prove systematically wrong in testing |

## Permanently Out of Scope

- **Combat log parsing** — BlazDamage computes *predicted* values from your current stats; it is not a damage meter
- **Simulation / theorycraft mode** — Stat-swapping, gear comparison sims — use Raidbots
- **Classic WoW support** — API differences are too significant; separate project if ever warranted
- **Healing done / damage taken overlays** — BlazDamage focuses on *outgoing* spell metrics
