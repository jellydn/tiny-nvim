local Lsp = require "utils.lsp"
return {
  cmd = { "rust-analyzer" },
  on_attach = Lsp.on_attach,
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", ".git" },
}
