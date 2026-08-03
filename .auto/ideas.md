# Deferred ideas (nvim 0.13 migration / UX)

- If Cursor steals `<C-Space>` for suggest / macOS Input Sources: use `<M-Space>` (Option+Space), or disable the OS shortcut, and add Cursor keybinding:
  `{ "key": "ctrl+space", "command": "vscode-neovim.send", "args": "<C-Space>", "when": "editorTextFocus && neovim.init && neovim.mode != 'insert'" }`
- Ensure oil `init` / keys fire early enough before first BufEnter on a directory
- Consider Neovim 0.13 built-in treesitter incremental selection (`an`/`vim.treesitter.*`) once public API stabilizes (#38211)
- Consider documenting: reload Cursor/VS Code window after nvim.dir / flash changes so keymaps apply
- Drop `lua/utils/flash_hacks.lua` preload once folke/flash.nvim merges PR #496
- If flash `s`/`S` conflicts with vscode-neovim defaults again, narrow modes (e.g. operator-only) instead of full disable
- If vscode.eval label paint still fails in Cursor: try one shared Decoration type + per-range `renderOptions.after`
- Drop vscode.eval label path if upstream flash/vscode-neovim overlay support lands
