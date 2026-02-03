local Lsp = require "utils.lsp"
-- npm install -g basedpyright
return {
  cmd = { "basedpyright-langserver", "--stdio" },
  on_attach = Lsp.on_attach,
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    ".git",
  },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "basic",
      },
    },
  },
}
