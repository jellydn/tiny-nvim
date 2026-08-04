local Lsp = require "utils.lsp"

function _G.biome_fix()
  -- NOTE: Migrate to LSP later if it's available
  local file = vim.fn.fnameescape(vim.fn.expand "%:p") -- Escape file path for shell
  vim.cmd("silent !biome lint --write " .. file)
end
function _G.biome_fix_unsafe()
  -- NOTE: Migrate to LSP later if it's available
  local file = vim.fn.fnameescape(vim.fn.expand "%:p") -- Escape file path for shell
  vim.cmd("silent !biome lint --write --unsafe " .. file)
end

return {
  cmd = { "biome", "lsp-proxy" },
  -- Shared LSP keymaps come from global LspAttach; only biome-specific maps here.
  on_attach = function(client, bufnr)
    if not client then
      return
    end
    vim.api.nvim_buf_set_keymap(
      bufnr,
      "n",
      "<leader>cb",
      "<cmd>lua biome_fix()<CR>",
      { noremap = true, silent = true, desc = "Biome: Fix" }
    )
    vim.api.nvim_buf_set_keymap(
      bufnr,
      "n",
      "<leader>cB",
      "<cmd>lua biome_fix_unsafe()<CR>",
      { noremap = true, silent = true, desc = "Biome: Fix unsafe" }
    )
  end,
  filetypes = {
    "astro",
    "css",
    "graphql",
    "javascript",
    "javascriptreact",
    "json",
    "jsonc",
    "svelte",
    "typescript",
    "typescriptreact",
    "vue",
  },
  root_markers = Lsp.biome_root_markers,
}
