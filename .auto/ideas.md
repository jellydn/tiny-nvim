# Deferred ideas (nvim 0.13 migration / UX)

- vscode.lua: duplicate `<leader>fw` normal-mode maps (lines 42–48) — clean up
- Install `tree-sitter` CLI (missing → nvim-treesitter compile ENOENT); wire into `scripts/install-tools.sh` if not already
- Ensure oil `init` runs early enough before first `-` press / BufEnter on dir (lazy load timing)
