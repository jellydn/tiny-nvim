local Lsp = require "utils.lsp"
-- Prefer: rustup component add rust-analyzer
return {
  cmd = { "rust-analyzer" },
  on_attach = Lsp.on_attach,
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "rust-project.json", ".git" },
  settings = {
    ["rust-analyzer"] = {
      cargo = { allFeatures = true },
      check = { command = "clippy" },
      procMacro = { enable = true },
    },
  },
}
