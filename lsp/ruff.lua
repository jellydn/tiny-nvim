local Lsp = require "utils.lsp"
-- Prefer mise/uv ruff that supports `ruff server` (old Homebrew ruff 0.1.x cannot).
return {
  cmd = Lsp.ruff_cmd(),
  filetypes = { "python" },
  root_markers = Lsp.python_root_markers { "ruff.toml", ".ruff.toml" },
}
