# Next Steps

## Current Milestone: Issue #1 — Repository Infrastructure

Setting up the project foundation before feature work begins:

- Root config files (`.luacheckrc`, `.editorconfig`, `.markdownlint.jsonc`)
- Loadable addon skeleton (`BlazDamage.toc`, `Core.lua`, `Config/Defaults.lua`)
- Architecture validation script and CI workflow
- Documentation (Vision, Architecture, ADRs, etc.)
- GitHub labels

See [Issue #1](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/1) for full status.

## Immediate Next Actions

Once Issue #1 is complete, work begins on:

1. **[Issue #2 — BlazDamage v1 Feature Implementation](https://github.com/Grimblaz-and-Friends/BlazDamage/issues/2)**
   - Description parser (`Engine/DescriptionParser.lua`)
   - Stat collector (`UI/StatCollector.lua`)
   - Damage calculator (`Engine/Calculator.lua`)
   - Actionbar discovery and overlay renderer (`UI/`)
   - Tooltip enricher (`UI/`)

## Blocked By

- Issue #2 is blocked on Issue #1 completion
