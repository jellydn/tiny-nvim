local Lsp = require "utils.lsp"
-- uv tool install ruff@latest
return {
  cmd = { "ruff", "server" },
  on_attach = Lsp.on_attach,
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    ".git",
  },
}
