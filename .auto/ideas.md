# Deferred ideas (nvim 0.13 migration / UX)

- Drop `lua/utils/flash_hacks.lua` preload once folke/flash.nvim merges PR #496
- If flash `s`/`S` conflicts with vscode-neovim defaults again, narrow modes (e.g. operator-only) instead of full disable
- If vscode.eval label paint still fails in Cursor: try one shared Decoration type + per-range `renderOptions.after`
- Drop vscode.eval label path if upstream flash/vscode-neovim overlay support lands
- `.auto/log.jsonl` record shapes: `init` metadata, early `result` (partial fail_*), later `run` (full fail_* set). Treat as schema_version 1; do not infer a reduced check set from older `result` rows.
- Optional: force JS linter via `vim.g.lsp_js_linter` when auto-detect picks wrong tool
- Optional: drop `lsp/ts_ls.lua` once no projects override to legacy typescript-language-server (measure attach smoke still covers it)
