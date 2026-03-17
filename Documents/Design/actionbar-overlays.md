# Actionbar Overlays Design

## Overview

BlazDamage renders abbreviated damage/healing metrics directly on actionbar buttons using WoW's FontString API. Overlays are attached once per button (idempotent) and refreshed on each throttled stat update cycle.

## Data Flow Pipeline

For each tracked actionbar button, each refresh cycle:

1. `button.action` → slot number
2. `HasAction(slot)` → skip if no action
3. `GetActionInfo(slot)` → skip if not `"spell"`
4. `BD.StatCollector.getSpellStats(spellID)` → `spellStats` (`description`, `castTime`, `resourceCost`)
5. `BD.DescriptionParser.parse(spellStats.description)` → damage components
6. `BD.StatCollector.getPlayerStats()` → `playerStats` (`critChance`, `critMult`, `gcd`)
7. Merge `spellStats.{castTime, resourceCost}` + `playerStats.{critChance, critMult, gcd}` → unified `stats` table
8. `BD.Calculator.computeMetrics(components, stats)` → `{totals={avg, dps}}`
9. `BD.Calculator.resolveMetric(result, metric)` → numeric value
10. `BD.Calculator.formatNumber(value)` → `"14.5k"`, `"1.2M"`, etc.
11. `overlay:SetText(formatted)` / `overlay:Show()` — or `overlay:Hide()` on any nil

## OverlayRenderer API

**`BD.OverlayRenderer.attachOverlay(button)`**
Attaches a FontString overlay to a button frame. Idempotent — no-op if already attached. Anchored to the
configured position (default `BOTTOMRIGHT`), with offsets from `POSITION_OFFSETS`, font `STANDARD_TEXT_FONT`
at configured size (default 10), color white. Font and position read from `BD.config` with `BD.defaults` fallback.

**`BD.OverlayRenderer.refreshAll()`**
Refreshes all tracked buttons. Hides all overlays if `BD.config.showOverlays == false`.

**`BD.OverlayRenderer.refreshSlot(slot)`**
Refreshes the single button mapped to a specific actionbar slot. Used for immediate `ACTIONBAR_SLOT_CHANGED` updates.

**`BD.OverlayRenderer.applyStyle()`**
Re-applies font (size, face) and position anchor to all tracked overlays from current `BD.config` values. Called immediately by the options panel `OnValueChanged` callbacks for `overlayFontSize` and `overlayPosition`. Uses `ClearAllPoints()` before re-anchoring.

## ActionbarDiscovery API

**`BD.ActionbarDiscovery.init()`**
Idempotent. Runs once per session on `PLAYER_ENTERING_WORLD`. Reads `BD.config.discoveryMode` and dispatches to `initAuto()` or `initUpdate()`. Both modes call `scanDefaultButtons()` (and `scanElvUIButtons()` when ElvUI is present) at init time.

**Discovery Modes**
See [2026-03-10-switchable-actionbar-discovery.md](../Decisions/2026-03-10-switchable-actionbar-discovery.md).

**ElvUI Auto-Detection**
When ElvUI is loaded (`_G.ElvUI` is truthy), `scanElvUIButtons()` runs automatically after the default
Blizzard bar scan in both discovery modes. It checks `_G["ElvUI_Bar{N}Button{M}"]` for bars {1–10,
13–15} and buttons 1–12. No configuration is needed.

If ElvUI is detected but no buttons are found (e.g., the ElvUI actionbar module is disabled), a warning
is printed to chat. Blizzard bar overlays continue to work regardless.

Known limitations:

- Bars added or reconfigured mid-session require `/reload` to pick up new buttons.

## EventHandler Integration

- `PLAYER_ENTERING_WORLD` → `BD.ActionbarDiscovery.init()` + `setDirty()`
- `ACTIONBAR_SLOT_CHANGED` → `slot == 0` (spec swap, equipment set load): `BD.OverlayRenderer.refreshAll()`; `slot > 0`: `BD.OverlayRenderer.refreshSlot(slot)`
- All other stat-affecting events → throttled `setDirty()` path (0.1s throttle)

## Visual Spec

- Position: user-configurable via options panel; default `BOTTOMRIGHT`; all four corners supported (`TOPLEFT`, `TOPRIGHT`, `BOTTOMLEFT`, `BOTTOMRIGHT`) with appropriate offsets
- Font: `STANDARD_TEXT_FONT` at user-configurable size (default 10, range 8–20)
- Color: white `(1, 1, 1)`
- Draw layer: `OVERLAY`

## Number Formatting

Handled by `Calculator.formatNumber(value)`:

| Range | Format | Example |
| --- | --- | --- |
| `< 1000` | Integer | `"500"` |
| `1000–999,949` | `X.Yk` | `"14.5k"` |
| `≥ 999,950` | `X.YM` | `"1.0M"` |

## Data Structures

**`trackedButtons`** (OverlayRenderer module-local): `button frame → { overlay, slot }` — main tracking table.
**`slotToButton`** (OverlayRenderer module-local): `slot number → button frame` — reverse index for `refreshSlot`.
