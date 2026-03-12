# Switchable Actionbar Discovery Strategy

**Date**: 2026-03-10  
**Status**: Approved  
**Supersedes**: [2026-03-02-addon-agnostic-actionbar-discovery.md](2026-03-02-addon-agnostic-actionbar-discovery.md)

## Context

The original ADR chose `hooksecurefunc("ActionButton_Update", ...)` as the single discovery mechanism.
During design for Issue #7, we identified that WoW 12.x provides `ActionBarButtonEventsFrame_RegisterFrame` —
a registration hook that fires when buttons formally register with the actionbar event frame.
This provides more reliable button discovery with lower overhead than the update hook.

However, `ActionBarButtonEventsFrame_RegisterFrame` may not exist in all WoW versions or modded environments, so a fallback strategy is needed.

## Decision

Implement two switchable discovery modes controlled by `BD.config.discoveryMode` (SavedVariable, default `"auto"`):

| Mode | Hook | Notes |
| --- | --- | --- |
| `auto` | `ActionBarButtonEventsFrame_RegisterFrame` | Default. Lower overhead, covers dynamically registered buttons. Falls back gracefully via pcall. |
| `update` | `ActionButton_Update` | Fallback for environments where the registration hook is unavailable. |

Both modes call `scanDefaultButtons()` at init time to handle buttons already registered before `PLAYER_ENTERING_WORLD`. Discovery is idempotent — `init()` only runs once per session.

## Switching

```text
/bd discovery auto    -- switch to auto mode (requires /reload)
/bd discovery update  -- switch to update mode (requires /reload)
/bd discovery         -- print current mode
```

## Consequences

- Blizzard default actionbars work in both modes.
- Third-party addon buttons work in `auto` mode if they use `ActionBarButtonEventsFrame_RegisterFrame`; `update` mode covers buttons that trigger `ActionButton_Update`.
- The original ADR's hook is now the fallback rather than the primary strategy.
