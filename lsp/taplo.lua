-- TOML language server + formatter + linter (taplo-cli with lsp feature).
-- Install: mise use -g taplo@latest  (or: cargo install --features lsp --locked taplo-cli)
return {
  cmd = { "taplo", "lsp", "stdio" },
  filetypes = { "toml" },
  root_markers = { ".taplo.toml", "taplo.toml", ".git" },
}
