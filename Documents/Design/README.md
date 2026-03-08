# Design Documents

This folder contains design documentation for BlazDamage features. Design docs are **permanent and authoritative** — they describe what was designed and why, committed alongside the PRs that implement the described feature.

## Purpose

Design docs capture:

- The feature's intent and user-facing behavior
- Key decisions made during design (with rationale)
- Acceptance criteria used to verify implementation

They are **not** post-hoc write-ups. A design doc should exist before implementation begins.

## Naming Convention

Domain-based filenames, not issue-based:

```text
Documents/Design/
├── description-parsing.md      ✅ Domain-based (permanent)
├── actionbar-overlays.md       ✅ Domain-based (permanent)
└── issue-42-something.md       ❌ Issue-based (do not use)
```

Issue-based names create orphan documents after the issue closes. Domain-based names remain meaningful as the codebase evolves.

## Lifecycle

1. **Draft** — Agent or developer creates the design doc before writing code
2. **Approved** — Design doc is reviewed and accepted (either in PR review or by committing it)
3. **Updated** — When the feature evolves, the design doc is updated in the same PR
4. **Superseded** — If a design is replaced wholesale, add a "Superseded By" note at the top and commit both versions

## Relationship to ADRs

Architecture Decision Records (`Documents/Decisions/`) capture one-time architectural choices.
Design documents capture ongoing feature design. Both are permanent; neither gets deleted.
