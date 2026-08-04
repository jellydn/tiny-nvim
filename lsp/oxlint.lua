local Lsp = require "utils.lsp"

return {
  cmd = { "oxlint", "--lsp" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte",
    "astro",
  },
  root_markers = Lsp.oxlint_root_markers,
  settings = {},
}
