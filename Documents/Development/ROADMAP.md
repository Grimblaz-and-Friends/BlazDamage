# Roadmap

## Guiding Principle

Ship correct values for the most common cases before expanding coverage. A reliable overlay for direct-damage spells is more valuable than an unreliable overlay for every spell type.

## v1 — Core Overlays (Current)

**Goal**: Display accurate damage metrics on actionbar buttons for direct-damage spells.

- [ ] Description parser — extract min/max from `C_Spell.GetSpellDescription()`
- [ ] Stat collector — crit, haste, mastery, versatility, spell power
- [ ] Damage calculator — average, DPS, DPSC, DPM
- [ ] Actionbar overlay renderer
- [ ] Tooltip enrichment (spellbook + actionbar)
- [ ] Event-driven updates (gear swap, buff change, action slot change)
- [ ] Manual verification with 3+ specs

**Release criteria**: Overlays display correct numbers for at least 3 diverse specs, with graceful skip for unsupported spell types.

## v1.1 — Healing & Configuration

**Goal**: Expand to healing metrics and add a minimal in-game options panel.

- [ ] Healing description parser (adapts v1 parser for healing format)
- [ ] Healing metrics: avg heal, HPS, HPM
- [ ] In-game options panel (Blizzard InterfaceOptions or a simple /bd config frame)
- [ ] Configuration persistence via SavedVariables
- [ ] User-selectable display metric per-slot (future)

## v2 — Advanced Metrics & Polish

**Goal**: Deepen metric coverage and improve display quality.

- [ ] Effective health per resource (EHPR) metrics
- [ ] Multi-target AoE scaling estimates (where description provides count)
- [ ] Overlay font and position customization
- [ ] Masque integration for overlay styling
- [ ] Minimap button / options access
