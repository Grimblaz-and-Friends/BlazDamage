# BlazDamage — Claude Code project context

WoW addon that displays calculated damage/healing metrics on actionbar buttons and enriches spell
tooltips — a modern successor to DrDamage built on the WoW API with no manual spell data.

The full project context (technology stack, layer architecture, naming conventions, error-handling
rules, build and validation commands) lives in the two files imported below. They are the authority;
this file exists so Claude Code and every dispatched subagent load them automatically.

@.github/copilot-instructions.md
@.github/architecture-rules.md

## The one rule that governs placement

**The Portability Test** — *"Would this code run unmodified in a standalone Lua 5.1 interpreter with
no WoW API?"*

- **YES** → `Engine/` or `Config/`
- **NO** → `UI/`

`Engine/` contains zero WoW API calls. UI converts WoW API output into plain Lua values before
handing them to Engine. This is enforced in CI by `.github/scripts/validate-architecture.ps1`, so a
violation fails the build rather than merely reading badly.

## Validation gates

All three run in CI on every PR and should be run locally before proposing a change as complete:

```bash
luacheck . && pwsh .github/scripts/validate-architecture.ps1 && busted Tests/
```

Only the Engine layer is unit-testable. UI behavior is verified manually in-game — see
[Documents/Development/TestingStrategy.md](Documents/Development/TestingStrategy.md). Do not claim UI
behavior is verified on the strength of a passing test suite.

### Local toolchain differs from CI

CI installs **Lua 5.1**, which is the runtime WoW actually uses. A local install may be a later
version (5.4 is common on Windows), and `busted` will happily run Engine tests under it. Tests
passing locally therefore do not prove 5.1 compatibility. Avoid post-5.1 syntax and stdlib in
`Engine/` and `Config/` — notably integer division (`//`), bitwise operators, `goto`, and
`table.unpack` (use `unpack`). `.luacheckrc` pins `std = "lua51"`, so luacheck catches most of this;
CI is the final word.

## Working conventions

- **Branches**: `feature/issue-NN-short-slug`, cut from `main`.
- **Design docs** live in `Documents/Design/` and are committed in the same PR as the implementation
  they describe. Keep them synchronized with shipped behavior rather than aspirational.
- **Architecture decisions** are ADRs in `Documents/Decisions/`, filename-dated `YYYY-MM-DD-slug.md`.
  A decision that supersedes an earlier one says so, and the superseded ADR is marked.
- **Documentation hub**: [Documents/index.md](Documents/index.md) indexes everything above.
- **No trailing whitespace** — `.editorconfig` enforces it and `.githooks/pre-commit` strips it. That
  hook only runs when `core.hooksPath` is set:

  ```bash
  git config core.hooksPath .githooks
  ```

## Agent Orchestra

This repository is worked through the [Agent Orchestra](https://github.com/Grimblaz/agent-orchestra)
plugin. `/open {issue}` is the entrance for standalone work; `/orchestrate` runs the full
implementation pipeline. Durable phase state lives in GitHub issue comments via HTML markers, not in
this repository — nothing here needs to be created or cleaned up to support it.
