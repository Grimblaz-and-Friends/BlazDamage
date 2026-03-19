# ElvUI Actionbar Discovery — Per-Addon Exception

**Date**: 2026-03-15
**Status**: Approved
**Issues**: [#35](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/35) (primary), [#10](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/10) (evidence)
**Partially supersedes**: Decision #2 of [2026-03-02-addon-agnostic-actionbar-discovery.md](2026-03-02-addon-agnostic-actionbar-discovery.md) — for ElvUI only

## Context

In-game investigation during Issue #10 confirmed that the generic discovery hooks —
`ActionBarButtonEventsFrame:RegisterFrame()` and `ActionButton_Update` — find zero ElvUI buttons.
ElvUI replaces Blizzard's entire frame system, including its actionbar infrastructure, with its own
implementation. ElvUI actionbar buttons do not participate in `ActionBarButtonEventsFrame:RegisterFrame()`
registration and do not trigger `ActionButton_Update`, making both discovery modes ineffective for
ElvUI users without additional handling.

ElvUI is the most widely-used actionbar and UI replacement addon in the WoW community and is the
developer's primary addon. Its buttons follow a predictable, well-documented naming convention
(`ElvUI_Bar{N}Button{M}`) that is stable across ElvUI releases.

The original Decision #2 in
[2026-03-02-addon-agnostic-actionbar-discovery.md](2026-03-02-addon-agnostic-actionbar-discovery.md)
correctly anticipated this scenario as a documented known limitation: addons that use completely
non-standard frames would not show overlays, and the hook strategy would be evaluated case by case.
This ADR creates a targeted exception rather than abandoning the no-shim principle entirely.

## Decisions

### 1. Add `scanElvUIButtons()` Frame Name Scan

**Choice**: Implement `scanElvUIButtons()` in `ActionbarDiscovery` that checks
`_G["ElvUI_Bar{N}Button{M}"]` for bars 1–10 and 13–15, buttons 1–12. The function checks `_G.ElvUI`
before doing any work and is a no-op when ElvUI is absent. It is called from both `initAuto()` and
`initUpdate()` after the default Blizzard bar scan. If ElvUI is detected but no buttons are found
(e.g., the ElvUI actionbar module is disabled), a warning is printed to chat.
**Rationale**: ElvUI's frame naming convention is stable and publicly documented. This is the narrowest
change that delivers overlay support to ElvUI users. Guarding on `_G.ElvUI` ensures zero overhead for
users without ElvUI. The warning on zero-button detection handles the graceful degradation case
(disabled actionbar module) without crashing or silently doing nothing.
**Impact**: ElvUI users receive overlays automatically in both discovery modes without any
configuration. Users without ElvUI are unaffected.

### 2. Limiting Principle — ElvUI Exception Only

**Choice**: This exception applies to ElvUI specifically and does not establish a general pattern for
adding per-addon shims.
**Rationale**: Adding per-addon detection for every popular actionbar addon recreates the O(N)
maintenance burden that Decision #2 of the original ADR was designed to avoid. Future requests for
addon-specific discovery must be evaluated individually against the same criteria: (a) generic hooks
confirmed to return zero results in-game; (b) meaningful user demand documented; (c) a new ADR filed
per addon.
**Impact**: The codebase remains maintainable. Contributors cannot add addon-specific discovery code
without an explicit ADR. This ADR is not a precedent for ad-hoc shims.

## Consequences

- ElvUI users get overlays automatically in both `auto` and `update` discovery modes without any
  configuration.
- Pre-merge verification of `button.action` compatibility with LibActionButton (LAB) frames is
  required as a CE Gate scenario before this change ships.
- ElvUI bars added or reconfigured mid-session (e.g., enabling additional bars after init) are not
  detected until `/reload`.

## References

- [GitHub Issue #35](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/35) — ElvUI actionbar
  discovery
- [GitHub Issue #10](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/10) — In-game
  investigation confirming zero buttons with generic hooks
- [2026-03-02-addon-agnostic-actionbar-discovery.md](2026-03-02-addon-agnostic-actionbar-discovery.md) —
  Original ADR establishing Decision #2 (no per-addon shims)
- [2026-03-10-switchable-actionbar-discovery.md](2026-03-10-switchable-actionbar-discovery.md) —
  Switchable discovery modes (not superseded by this ADR)
