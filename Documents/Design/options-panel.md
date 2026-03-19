# Options Panel Design

BlazDamage exposes all 13 user-configurable settings through a native Blizzard Settings panel registered via the Settings API (Dragonflight+/Midnight).

## Access

- **Interface Options**: Interface → AddOns → BlazDamage
- **Slash command**: `/bd` or `/bd options`

## Settings API Integration Pattern

```lua
-- Category registered at file-load time (safe before ADDON_LOADED)
local category = Settings.RegisterVerticalLayoutCategory("BlazDamage")
Settings.RegisterAddOnCategory(category)
BD.optionsCategoryID = category:GetID()

-- Settings registered in OptionsPanel.init() (called from ADDON_LOADED)
-- BD.config is guaranteed non-nil when init() runs.
local setting = Settings.RegisterAddOnSetting(
    category, "BlazDamage_variableKey", "variableKey",
    BD.config, Settings.VarType.Boolean, "Display Name", defaultValue
)
Settings.CreateCheckbox(category, setting, "Tooltip text")
```

The variableTable pattern (`BD.config` as 4th arg) means the Blizzard Settings framework reads and writes directly to `BD.config.variableKey` when the widget value changes.
Settings with immediate visual side effects (metric, overlays) also register explicit `SetValueChangedCallback` handlers — the framework write handles persistence; the callback handles the immediate redraw.

## Widget Types Per Setting

| Setting | Widget | Range / Options |
| --- | --- | --- |
| `metric` | Dropdown | avg, dps, dpsc, dpscd, dpm |
| `showOverlays` | Checkbox | — |
| `overlayFontSize` | Slider | 8–20, step 1 |
| `overlayPosition` | Dropdown | TOPLEFT, TOPRIGHT, BOTTOMLEFT, BOTTOMRIGHT |
| `showTooltips` | Checkbox | — |
| `tooltipShowAvg` | Checkbox | — |
| `tooltipShowDps` | Checkbox | — |
| `tooltipShowDpsc` | Checkbox | — |
| `tooltipShowDpscd` | Checkbox | — |
| `tooltipShowCrit` | Checkbox | — |
| `tooltipShowDpm` | Checkbox | — |
| `discoveryMode` | Dropdown | auto, update |
| `showPerf` | Checkbox | — |

## OnValueChanged Callback Routing

Callbacks are only registered for settings with immediate side effects:

| Setting | Side effect |
| --- | --- |
| `metric`, `showOverlays` | `BD.OverlayRenderer.refreshAll()` (nil-guarded) |
| `overlayFontSize`, `overlayPosition` | `BD.OverlayRenderer.applyStyle()` (nil-guarded on both) |
| `showTooltips`, `tooltipShow*` | None — settings API writes BD.config; effect on next tooltip hover |
| `discoveryMode` | None — effective on next `/reload` |
| `showPerf` | None — effective on next refresh cycle |

## Category ID Storage

`BD.optionsCategoryID = category:GetID()` is set at file-load time and referenced by the slash handler: `Settings.OpenToCategory(BD.optionsCategoryID)`.

## Persistence

All settings write through to `BD.config = BlazDamageDB` (SavedVariables). No separate flush step is needed.
