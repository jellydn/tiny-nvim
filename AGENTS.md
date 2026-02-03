# AGENTS.md - tiny-nvim

Guide for agentic coding agents working in this Neovim configuration repository.

## Project Overview

tiny-nvim is a minimal Neovim 0.11+ config that relies on built-in LSP and a curated set
of plugins managed by lazy.nvim. Most edits are Lua under `lua/` with optional extras
under `lua/plugins/extra/`.

## Build, Lint, Test

### Setup

```bash
# Install required external tools
./scripts/install-tools.sh

# Plugin sync (run inside Neovim)
:Lazy sync
```

### Linting and Formatting

```bash
# Format all Lua
stylua .

# Format a single file
stylua lua/plugins/coding.lua

# Lint JS/TS/JSON (biome is linter only)
biome lint .
biome lint --write .
biome lint --write --unsafe .

# Spell check
cspell "**/*.{lua,md,txt}"
```

### Health Checks

```vim
:checkhealth
:check vim.lsp
:ConformInfo
```

### Tests (Single Test Focus)

This repo does not include unit tests itself. Testing is typically done through Neovim
plugins against external projects.

Within Neovim (vim-test):

- `:TestNearest` single test at cursor
- `:TestFile` tests in current file
- `:TestSuite` full suite
- `:JestRunner` or `:VitestRunner` for nearest test

Within Neovim (neotest):

- `<leader>ctr` run nearest test
- `<leader>ctt` run current file
- `<leader>ctT` run all test files
- `<leader>ctl` rerun last test

## Code Style Guidelines

### Lua Formatting

- Indentation: 2 spaces, no tabs
- Max line width: 120
- Quotes: prefer double quotes
- Call parens: omit for single string arg (`require "config.options"`)

### Imports and Requires

```lua
require "config.options"
local map = vim.keymap.set

local ok, mod = pcall(require, "module")
if not ok then
  return
end

local on_attach = require("utils.lsp").on_attach
```

### Naming

- Variables/functions: `snake_case`
- Modules/tables: `PascalCase`
- Globals: `_G.camelCase()` only when required for keymaps
- Private helpers: prefix with `_`

### Error Handling

- Prefer guard clauses and early returns
- Use `pcall` for optional modules or IO
- Notify errors via `vim.notify(..., vim.log.levels.ERROR)` when user-facing

### Comments

- Keep comments minimal; rely on clear names
- Comment only for non-obvious logic or user-facing behavior

### Types and Diagnostics

- Lua runtime is LuaJIT
- Allowed globals include `vim` and `Snacks` (from `.luarc.json`)
- Keep `workspace.checkThirdParty = false`

## Project Conventions

### Structure

```
lua/
  config/      core options, keymaps, autocmds, lazy
  plugins/     plugin specs
    extra/     optional/extra plugins
  langs/       language-specific configs
  utils/       shared helpers
lsp/           native Neovim 0.11+ LSP configs
scripts/       install/setup scripts
```

### Plugin Specs

- Files under `lua/plugins/` return plugin spec tables for lazy.nvim
- Use `optional = true` for extension plugins
- Keep plugin config close to its spec

### LSP and Project Overrides

- LSP configs live in `lsp/` and use native Neovim 0.11+ format
- Project-specific overrides go in `.nvim-config.lua` (gitignored)
- Global config toggles use `vim.g.*` (e.g., `vim.g.enable_extra_plugins`)

## Rules and Agent Notes

### Cursor and Copilot Rules

- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` found
  in this repo at the time of writing.

### Editing Expectations

- Keep changes small and focused
- Avoid unnecessary new dependencies
- Do not auto-generate large blocks or rewrite unrelated files

## Quick Validation

After changes, run:

- `stylua .` for Lua formatting
- `:checkhealth` in Neovim to confirm config health
