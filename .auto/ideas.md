# Deferred ideas (nvim 0.13 migration / UX)

- Ensure oil `init` / keys fire early enough before first BufEnter on a directory
- Consider documenting: reload Cursor/VS Code window after nvim.dir / flash changes so keymaps apply
- Drop `lua/utils/flash_hacks.lua` preload once folke/flash.nvim merges PR #496
- If flash `s`/`S` conflicts with vscode-neovim defaults again, narrow modes (e.g. operator-only) instead of full disable
- Deferred: true flash letter labels under vscode via `vscode.eval` TextEditorDecorationType (virt_text path was worse than expand-only)
- Keep vscode `S` as expand/shrink; do not reintroduce getchar label picker unless decorations work
