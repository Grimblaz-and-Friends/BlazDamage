# Addon-Agnostic Actionbar Discovery via `ActionBarButtonMixin`

**Date**: 2026-03-02
**Issue**: [#1 — Project Bootstrap](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/1)
**Status**: Superseded by [2026-03-10-switchable-actionbar-discovery.md](2026-03-10-switchable-actionbar-discovery.md)

## Context

WoW players use a variety of actionbar addons: Bartender4, ElvUI, Dominos, Masque, and Blizzard's default bars.
Each addon creates its own ActionButton frames with different naming conventions and parent hierarchies.
Writing per-addon compatibility modules (as many addons historically did) creates O(N) maintenance burden and
breaks whenever a third-party addon updates its frame structure.

WoW's ActionButton frames all share a common mixin: `ActionBarButtonMixin` for the default Blizzard UI, and
virtually all third-party actionbar addons reuse the standard ActionButton frame template — including its
`ActionButton_Update` function — in order to retain compatibility with Blizzard's own secure action handler
infrastructure. This shared function call is a stable hook point that does not depend on any specific addon's
internal structure.

The alternative — detecting and integrating with each actionbar addon individually — would require BlazDamage to
ship a compatibility shim for every popular bar addon, keep those shims updated as those addons evolve, and test
against each addon's release cycle independently. This is unsustainable for a small team.

## Decisions

### 1. Hook `ActionButton_Update` Generically

**Choice**: Use `hooksecurefunc("ActionButton_Update", callback)` to be notified whenever any ActionButton
updates, regardless of which addon created it.
**Rationale**: This makes BlazDamage automatically compatible with any actionbar addon that reuses the standard
ActionButton frame template, which nearly all do. The hook receives the button frame as its argument, allowing
overlay attachment without caring about the button's origin.
**Impact**: No per-addon compatibility modules are needed. Overlay attachment logic remains in a single place.
New actionbar addons that follow the standard template are supported automatically on first load.

### 2. No Per-Addon Compatibility Shims

**Choice**: Do not write Bartender4-specific, ElvUI-specific, or Dominos-specific detection code.
**Rationale**: Third-party addons evolve independently. Per-addon code breaks silently when the target addon
updates its internal frame structure. The generic hook approach means BlazDamage continues working even when
Bartender4 releases a major update that renames its internal frames.
**Impact**: If an actionbar addon uses a completely non-standard frame that does not call `ActionButton_Update`,
those buttons will not show overlays. This is acceptable (graceful degradation) and is documented as a known
limitation. Users on exotic bar addons are advised to report compatibility issues so the hook strategy can be
evaluated for that specific case.

## References

- [GitHub Issue #1](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/1)
- [GitHub Issue #2](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/2) — Actionbar discovery implementation details
- [Documents/Development/TechnicalArchitecture.md](../Development/TechnicalArchitecture.md)
