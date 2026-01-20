return {
  "jellydn/tiny-cloak.nvim",
  opts = {},
  ft = { "sh", "yml", "json", "jsonc", "yaml" },
  keys = {
    {
      "<leader>tc",
      "<cmd>CloakToggle<cr>",
      desc = "Toggle Cloak",
    },
  },
}
