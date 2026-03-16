# Tooltip Enrichment Design

`UI/TooltipEnricher.lua` appends calculated damage metrics to spell tooltips using WoW's modern `TooltipDataProcessor` API.

## Hook Strategy

```lua
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, enrichCallback)
```

This single hook fires after *all* spell tooltips render, covering both spellbook entries and actionbar buttons. The `TooltipDataProcessor` system is the recommended Retail API; it replaces the older `hooksecurefunc("GameTooltip_SetSpell", ...)` pattern. No manual tooltip event registration is required.

## Data Flow Pipeline

The pipeline reuses the same flow established in `UI/OverlayRenderer.lua`:

1. Guard: `BD.config` nil check (addon-load race prevention)
2. Guard: `BD.config.showTooltips == false` toggle check
3. Extract `spellID` from `tooltipData.id` — return if nil
4. `BD.StatCollector.getSpellStats(spellID)` — return if nil or no description
5. `BD.DescriptionParser.parse(description)` — return if nil or empty
6. Merge `playerStats` + `spellStats` into `stats` table for Calculator
7. `BD.Calculator.computeMetrics(parsed, stats)` — return if nil
8. Append tooltip lines via `tooltip:AddLine()`
9. `tooltip:Show()` to resize the tooltip frame after line addition

## Tooltip Line Format

```text
|cFFFFFF00BlazDamage:|r        ← gold header (always)
  Avg: 14.3k                   ← always (avg is never nil for a non-nil result)
  DPS: 8.2k                    ← when totals.dps non-nil (damage spell or mixed)
  DPSC: 9.1k                   ← when totals.dpsc non-nil and totals.dps non-nil
  HPS: 12.1k                   ← when totals.dps non-nil (heal-only spell; label swapped from DPS)
  HPSC: 13.4k                  ← when totals.dpsc and totals.dps non-nil (heal-only, cast time > 0)
  Crit: 18.5%                  ← always (from StatCollector.getPlayerStats().critChance * 100)
  DPM: 650                     ← when spell has a resource cost (label from Calculator.resourceLabel)
  HPM: 650                     ← heal-only variant of the resource efficiency line
```

`DPS`/`DPSC` and `HPS`/`HPSC` are mutually exclusive: damage or mixed spells show `DPS`/`DPSC`; heal-only spells (selected by `Calculator.isHealOnly()`) show `HPS`/`HPSC` instead.

For heal-only spells, `DPS`/`DPSC`/`DPM` labels are swapped to `HPS`/`HPSC`/`HPM` (etc.) via `Calculator.isHealOnly(result.components)`. Mixed damage+heal spells keep damage labels.

The resource efficiency line label adapts to the spell's resource type:

- Mana spells → `DPM` (Damage per Mana)
- Rage spells → `DPR` (Damage per Rage)
- Energy spells → `DPE` (Damage per Energy)
- Focus spells → `DPF` (Damage per Focus)
- Runic Power → `DPRP` (Damage per Runic Power)
- Others → `DPR` (fallback)

## Edge Cases

| Scenario | Behaviour |
| --- | --- |
| Instant-cast spell (castTime = 0) | `DPSC` line omitted (nil guard); `DPS` uses GCD floor |
| Costless spell (resourceType = nil, resourceCost = 0) | Resource efficiency line omitted (label = nil, dpm = nil) |
| Heal-only spell | `HPS` and `HPSC` shown (labels swapped from DPS/DPSC); `HPM/HPR/HPRP/HPE/HPF` shown when spell has resource cost. `HPSC` suppressed when castTime = 0. |
| Unparseable description | All enrichment skipped silently; default tooltip only |
| `showTooltips = false` | All enrichment skipped; original tooltip unchanged |
| Addon-load race (ADDON_LOADED) | `BD.config` nil guard prevents crash at first tooltip |

## Shared Pipeline Pattern

Both `OverlayRenderer` and `TooltipEnricher` use the same pipeline:
`getSpellStats → parse → merge stats → computeMetrics → render`

Extracting a shared helper was evaluated and deferred: the two callers differ in render surface (FontString vs tooltip API) and guard handling. If a third consumer emerges, extraction would be justified.

## Known Limitations

- **Stale tooltip during buff changes**: Calculated values reflect stats at the time the tooltip opens. If a short-duration buff expires while the tooltip is visible, the tooltip does not refresh. This matches the behaviour of most WoW UI add-ons and is unlikely to be noticed in practice.
