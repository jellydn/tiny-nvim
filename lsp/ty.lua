local Lsp = require "utils.lsp"
-- Astral ty: type checker + language server (replaces basedpyright/pyright).
-- Install: uv tool install ty@latest
local cmd = Lsp.ty_cmd() or { "tiny-nvim-ty-unavailable" }
return {
  cmd = cmd,
  filetypes = { "python" },
  root_markers = Lsp.python_root_markers { "ty.toml" },
  settings = {
    ty = {
      -- openFilesOnly keeps editor noise low; set workspace for full-project checks
      diagnosticMode = "openFilesOnly",
    },
  },
}
