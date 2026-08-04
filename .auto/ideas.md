# Deferred ideas (nvim 0.13 migration / UX)

- Primary expand is `g<Space>` (Ctrl+Space often stolen). Optional Cursor restore:
  `{ "key": "ctrl+space", "command": "vscode-neovim.send", "args": "<C-Space>", "when": "editorTextFocus && neovim.init && neovim.mode != 'insert'" }`
- Native visual `an`/`in` treesitter selection may appear on recent nightlies (neovim#36993);
  public API still evolving (neovim#38211). Prefer documenting `g<Space>` until keymaps are stable.
- Consider documenting: reload Cursor/VS Code window after nvim.dir / flash changes so keymaps apply
- Drop `lua/utils/flash_hacks.lua` preload once folke/flash.nvim merges PR #496
- If flash `s`/`S` conflicts with vscode-neovim defaults again, narrow modes (e.g. operator-only) instead of full disable
- If vscode.eval label paint still fails in Cursor: try one shared Decoration type + per-range `renderOptions.after`
- Drop vscode.eval label path if upstream flash/vscode-neovim overlay support lands
- `.auto/log.jsonl` record shapes: `init` metadata, early `result` (partial fail_*), later `run` (full fail_* set). Treat as schema_version 1; do not infer a reduced check set from older `result` rows.
- Optional: add `eslint` to default `lsp_by_ft` JS/TS list (currently `vim.g.lsp_on_demands` only)
- Optional: drop redundant per-config `on_attach = Lsp.on_attach` now that global LspAttach applies keymaps
