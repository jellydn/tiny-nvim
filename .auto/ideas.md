# Deferred ideas (nvim 0.13 migration / UX)

- Drop `lua/utils/flash_hacks.lua` once conditional preload sees upstream SearchState (PR #496) and lock is updated
- If flash `s`/`S` conflicts with vscode-neovim defaults again, narrow modes (e.g. operator-only) instead of full disable
- If vscode.eval label paint still fails in Cursor: try one shared Decoration type + per-range `renderOptions.after`
- Drop vscode.eval label path if upstream flash/vscode-neovim overlay support lands
- `.auto/log.jsonl` contract: see `.auto/log.schema.md` (`schema_version` 1). Historical rows may omit the field; do not infer a reduced check set from partial `result` rows.
- Optional: force JS linter via `vim.g.lsp_js_linter` when auto-detect picks wrong tool
- Optional: drop `lsp/ts_ls.lua` once no projects override to legacy typescript-language-server (measure attach smoke still covers it)
