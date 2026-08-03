# Deferred ideas (nvim 0.13 migration / UX)

- Ensure oil `init` / keys fire early enough before first BufEnter on a directory
- Consider documenting: reload Cursor/VS Code window after nvim.dir / flash changes so keymaps apply
- Drop `lua/utils/flash_hacks.lua` preload once folke/flash.nvim merges PR #496
- Audit other `vscode = true` plugins for unwanted buffer hijacks (beyond flash)
