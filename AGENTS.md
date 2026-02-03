# AGENTS.md - tiny-nvim

Guide for agentic coding agents working in this Neovim configuration repository.

## Project Overview

This is **tiny-nvim**, a minimal Neovim configuration for version 0.11+ that leverages built-in LSP features and carefully selected plugins managed by lazy.nvim.

## Build/Lint/Test Commands

### Linting & Formatting

```bash
# Format Lua files (stylua)
stylua .

# Check specific Lua file
stylua lua/plugins/coding.lua

# Lint JavaScript/TypeScript/JSON (biome - linter only)
biome lint .
biome lint --write .          # Fix issues
biome lint --write --unsafe . # Fix with unsafe changes

# Spell check
cspell "**/*.{lua,md,txt}"
```

### Testing Commands

This project uses Neovim plugins for testing JavaScript/TypeScript projects:

**Within Neovim (vim-test):**

- `:TestNearest` - Run test nearest to cursor
- `:TestFile` - Run all tests in current file
- `:TestSuite` - Run entire test suite
- `:JestRunner` - Run nearest test with Jest
- `:VitestRunner` - Run nearest test with Vitest

**Within Neovim (neotest):**

- `<leader>ctr` - Run nearest test
- `<leader>ctt` - Run current file
- `<leader>ctT` - Run all test files
- `<leader>ctl` - Run last test

### Health Checks

```vim
:checkhealth          " Overall Neovim health
:check vim.lsp        " LSP configuration health
:ConformInfo          " Formatter status
```

### Installation/Setup

```bash
# Install all required tools
./scripts/install-tools.sh

# Install/update plugins (within Neovim)
:Lazy sync
```

## Code Style Guidelines

### Lua Style

- **Indentation**: 2 spaces (no tabs)
- **Line width**: 120 columns
- **Quotes**: Auto-prefer double quotes
- **Call parentheses**: None for single string args

### Imports & Requires

```lua
-- Good - no parentheses for simple requires
require "config.options"
local map = vim.keymap.set

-- Use parentheses when needed
local ok, err = pcall(require, "module")
local function_call = require("utils.lsp").on_attach
```

### Naming Conventions

- **Variables/functions**: `snake_case`
- **Modules/tables**: `PascalCase`
- **Global functions**: `_G.camelCase()` (for keymaps)
- **Private**: prefix with `_` (e.g., `_internal_func`)

### Error Handling

Use guard clauses and early returns:

```lua
-- Good
if not condition then
  return
end

-- Good - protected calls
local ok, result = pcall(dofile, filepath)
if not ok then
  vim.notify("Error: " .. result, vim.log.levels.ERROR)
  return
end
```

### Comments

- Minimal comments - prefer self-documenting code
- Use meaningful variable/function names
- Only comment complex logic or non-obvious behavior

### Formatting

- Format on save is enabled via conform.nvim
- Run `stylua` before committing Lua changes
- Biome handles linting (not formatting) for JS/TS/JSON

## Project Structure

```
lua/
  config/          " Core configuration (options, keymaps, autocmds, lazy)
  plugins/         " Plugin configurations
    extra/         " Optional/extra plugins
  langs/           " Language-specific settings
  utils/           " Utility modules
lsp/               " LSP server configurations (Neovim 0.11+ native)
scripts/           " Installation/setup scripts
```

## Key Conventions

- Plugin specs return tables with plugin definitions for lazy.nvim
- Use `optional = true` for plugins that extend others
- LSP configs are in `lsp/` directory (native Neovim 0.11+ format)
- Project-specific settings go in `.nvim-config.lua` (gitignored)
- Global variables for configuration: `vim.g.lsp_typescript_server`, `vim.g.enable_extra_plugins`

## Testing

This config doesn't have traditional unit tests. Test by:

1. Running `:checkhealth` after changes
2. Opening various file types to verify LSP/formatting works
3. Checking keymaps work with `:map <leader>xx`
