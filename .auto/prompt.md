# Autoresearch: Neovim 0.13 config migration

## Objective

Migrate this tiny-nvim config to Neovim 0.13 (`NVIM v0.13.0-dev-*`) while keeping
**treesitter**, **AI (sidekick.nvim)**, and **native LSP** fully supported and loadable.
This repo does **not** use LazyVim — consult LazyVim only as a reference for 0.13 API
patterns (`vim.hl.hl_op`, `vim.lsp.config`, etc.).

## Metrics

- **Primary**: `compat_failures` (count, lower is better) — frozen assertion failures
- **Secondary**:
  - `startup_ms` — median warm headless startup milliseconds (regression monitor only)
  - `fail_binary`, `fail_startup`, `fail_messages`, `fail_deprecated`
  - `fail_loadfile`, `fail_fixture_lua`, `fail_fixture_md`
  - `fail_vim_loop`, `fail_treesitter`, `fail_ai`, `fail_lsp`, `fail_miniai`

## How to Run

`./.auto/measure.sh` — outputs `METRIC name=number` lines.

Binary: `NVIM_BIN` if set, otherwise `nvim` from `PATH` (e.g. mise `neovim/nightly`).

## Files in Scope

- `init.lua` — entry, filetype-driven `vim.lsp.enable`
- `lua/config/**` — options, keymaps, autocmds, lazy, theme, project
- `lua/plugins/**` — plugin specs (including `ai.lua`, treesitter in `ui.lua`)
- `lua/langs/**` — language extras
- `lua/utils/**` — shared helpers
- `lsp/**` — native Neovim 0.11+ LSP configs
- `lazy-lock.json` — lock baseline already committed; update only for real compat fixes
- `.auto/**` — harness (preserve across discards). `log.jsonl` has `init` / early `result` /
  full `run` shapes (schema_version 1); older partial `result` rows are not a reduced check set

## Off Limits

- Do not remove/disable treesitter, sidekick/AI, or LSP to improve the metric
- Do not delete scenarios, soften assertions, or filter diagnostics for scoring
- Do not network-install or `:Lazy update` during measurement
- Do not replace this config with LazyVim wholesale
- Do not edit fixtures under `.auto/fixtures/` after baseline freeze
- Do not change `.auto/measure.sh` assertion set after baseline without re-baselining

## Constraints

- Target: Neovim 0.13 nightly (mise `neovim/nightly`)
- Prefer `vim.uv` over deprecated `vim.loop`
- Prefer `vim.hl.hl_op` on 0.13 (already gated in autocmds)
- Keep treesitter (`nvim-treesitter` main branch + `vim.treesitter.start`) working
- Keep AI (`folke/sidekick.nvim` in `lua/plugins/ai.lua`) loadable
- Keep native LSP (`vim.lsp.enable` + `lsp/*.lua`) working
- `fail_lsp` asserts API/config presence (`vim.lsp.enable`, `lsp/*.lua`, init wiring),
  every `lsp/*.lua` loads with `cmd` (`LSP_ALL_OK`), **and** smoke client attach on temp
  fixtures (`LSP_ATTACH_OK`). Missing binaries are skipped (not failures); attach timeouts fail.
  Language-server *project* health beyond initialize is out of scope.
- Startup-message filter (`fail_messages`) exempts **only** these missing-workspace tooling
  signatures (exact substrings): `TypeScript installation`, `Could not find a valid TypeScript`,
  `tsserver`, `rust-analyzer quit`. All other TS/Rust init errors still count
- Timing is secondary only — never keep a change solely for faster startup
- Anti-cheat: equal/worse `compat_failures` → discard; only keep real reductions

## Must Support (hard)

1. **Treesitter** — `nvim-treesitter` + `nvim-treesitter-textobjects` present; `vim.treesitter` API available; Lua `textobjects` query reachable
2. **AI** — `sidekick.nvim` present in lock + `lua/plugins/ai.lua`; module loadable after lazy setup
3. **LSP** — `vim.lsp.enable` available; at least one `lsp/*.lua` config present; filetype enable path in `init.lua` intact
4. **mini.ai** — treesitter textobjects (`af`/`if`) must not raise `Can not get query` for Lua

## What's Been Tried

- Confirmed this config dir is the active Neovim config (often via symlink)
- Branch: `autoresearch/nvim-0.13-migration-2026-08-03`
- Lock baseline committed: `chore(deps): update plugin lock baseline`
- Normal headless startup on 0.13: OK (`lazy_ok=true`)
- `checkhealth vim.deprecated`: OK — no deprecated functions detected (health buffer)
- Artificial `-u NONE` + `luafile` caused false `kanagawa` error — discarded as invalid probe
- TS/Rust fixture LSP errors are missing-tooling env noise, not 0.13 API failures
- **Root cause of mini.ai E5108**: `nvim-treesitter` main no longer ships `textobjects.scm`; mini.ai `gen_spec.treesitter` needs them. Fix: add `nvim-treesitter/nvim-treesitter-textobjects` (main), depend from `mini.ai` (LazyVim reference pattern)
- Replaced direct `vim.loop` with `vim.uv` in `init.lua`, `lua/langs/markdown.lua`, `lua/plugins/extra/codecompanion.lua`
- Hardened treesitter FileType start via `pcall(vim.treesitter.start)` and lang membership check
- Floor `compat_failures=0` held through: nvim.dir/oil/vscode `-`, flash SearchState patch (conditional preload), `g<Space>` expand, modern LSP (`ty`+`ruff`, default `vtsls`, nearest-dir JS lint), buffer-scoped git/linter detect, shared TS keymaps
- Deferred: drop `flash_hacks` after flash.nvim PR #496 merges + lock update; do not drop `ts_ls` while measure attach smoke covers it
