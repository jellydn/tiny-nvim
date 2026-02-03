-- Copilot integration for blink.cmp
-- Enable by adding "blink-copilot" to vim.g.enable_extra_plugins in .nvim-config.lua

local enabled = vim.tbl_contains(vim.g.enable_extra_plugins or {}, "blink-copilot")

return {
  {
    "saghen/blink.cmp",
    enabled = enabled,
    dependencies = { "fang2hou/blink-copilot" },
    opts = {
      sources = {
        default = { "copilot" },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 100,
            async = true,
          },
        },
      },
    },
  },
}
