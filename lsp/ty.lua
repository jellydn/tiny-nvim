local Lsp = require "utils.lsp"
-- Astral ty: type checker + language server (replaces basedpyright/pyright).
-- Install: uv tool install ty@latest
return {
  cmd = Lsp.ty_cmd(),
  filetypes = { "python" },
  root_markers = {
    "ty.toml",
    "pyproject.toml",
    "uv.lock",
    "poetry.lock",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    ".git",
  },
  settings = {
    ty = {
      -- openFilesOnly keeps editor noise low; set workspace for full-project checks
      diagnosticMode = "openFilesOnly",
    },
  },
}
