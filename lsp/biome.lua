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
  on_attach = function(client, bufnr)
    Lsp.on_attach(client, bufnr)
    -- Map <leader>cb to biome_fix and <leader>cB to biome_fix_unsafe
    if client then
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
    end
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
  root_markers = { "biome.json", "biome.jsonc", ".git" },
}
