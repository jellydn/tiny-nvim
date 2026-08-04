local Lsp = require "utils.lsp"
-- Prefer mise/uv ruff that supports `ruff server` (old Homebrew ruff 0.1.x cannot).
-- Sentinel cmd is intentionally non-executable so attach/enable skip instead of
-- retrying a PATH `ruff` that already failed the server probe.
local cmd = Lsp.ruff_cmd() or { "tiny-nvim-ruff-unavailable" }
return {
  cmd = cmd,
  filetypes = { "python" },
  root_markers = Lsp.python_root_markers { "ruff.toml", ".ruff.toml" },
}
