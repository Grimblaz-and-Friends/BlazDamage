# Developer Tooling

## Purpose

This document covers the editor/IDE configuration, formatter settings, linting setup,
and validation commands that keep BlazDamage consistent across contributors and agent
workflows. It records the rationale for per-language overrides so future changes can be
made deliberately.

## Editor Formatter Settings

Configuration lives in `.vscode/settings.json`.

### Global defaults

```json
"editor.formatOnSave": true,
"files.eol": "\n"
```

`files.eol: "\n"` enforces LF unconditionally, overriding the Windows CRLF default.
This keeps files clean after agent writes or formatter runs on Windows machines.

### Lua — formatter disabled

```json
"[lua]": {
  "editor.formatOnSave": false
}
```

No Lua auto-formatter is configured. Style is governed by `.editorconfig` (4-space indent,
LF, no trailing whitespace) and the conventions in `.github/copilot-instructions.md`.

**Rationale**: The sumneko Lua Language Server ships a formatter that would rewrite
hand-authored column-aligned tables and comments. Disabling it prevents the formatter
from silently dirtying committed files and causing spurious whitespace-only diffs in PRs.
If a formatter is ever enabled for Lua, configure it here, stage all files (`git add`),
and verify `git diff --exit-code` exits 0 before committing (see Pre-commit check below).

### Markdown — markdownlint formatter

```json
"[markdown]": {
  "editor.defaultFormatter": "DavidAnson.vscode-markdownlint"
}
```

Uses the `DavidAnson.vscode-markdownlint` extension as the default formatter to enforce
consistent heading, list, and emphasis style.

### PowerShell — column-aligned formatting

```json
"powershell.codeFormatting.alignPropertyValuePairs": true,
"powershell.codeFormatting.openBraceOnSameLine": true,
"powershell.codeFormatting.newLineAfterOpenBrace": true
```

Matches the authored style in `.github/scripts/*.ps1` — open brace on same line,
property values column-aligned.

## Linting

### luacheck

Configuration: `.luacheckrc`
Standard: `lua51` (WoW addon Lua 5.1 runtime)
Vendor excluded: `.luarocks/**`

Passing bar: **0 warnings / 0 errors**.

WoW API globals are declared in `.luacheckrc` via a custom `wow` std. The list covers
the current UI/ call surface; expand it as new WoW API calls are added. Engine/ files
must not reference any WoW global — luacheck enforces this boundary.

### Lua Language Server diagnostics

The sumneko Lua LS (`Lua.*` settings in `.vscode/settings.json`) is configured to:

- Target Lua 5.1 runtime (`Lua.runtime.version`)
- Disable all standard library diagnostics (WoW provides its own runtime)
- Load WoW API type annotations from the `ketho.wow-api` VS Code extension

This gives in-editor type checking and autocomplete against the WoW API without
conflicting with the luacheck lint pass.

## Validation Workflow

### Quick-Validate

Run all three checks in sequence before every commit:

```bash
luacheck . && pwsh .github/scripts/validate-architecture.ps1 && busted Tests/
```

| Tool | Purpose | Pass condition |
| ---- | ------- | -------------- |
| `luacheck` | Lint Lua source | 0 warnings / 0 errors |
| `validate-architecture.ps1` | Enforce Engine/UI layer rules | Exit 0 |
| `busted Tests/` | Unit tests | All tests pass |

### Pre-commit idempotency check

After writing all files and staging changes:

```bash
git add .
git diff --exit-code
```

Exit code 0 confirms no formatter or tool dirtied the working tree between staging and
commit. A non-zero exit means a formatter ran on save after staging — re-stage and
re-check.

This check is especially important when adding or modifying `.vscode/settings.json`
formatter settings, since the act of saving it can trigger format-on-save on adjacent
open files.
