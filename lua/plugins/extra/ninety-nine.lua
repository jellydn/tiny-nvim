-- ThePrimeagen/99: Neovim AI agent
-- Requires: OpenCode installed and configured
local mapping_key_prefix = "<leader>9"

return {
  -- Register 99 group in which-key
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { mapping_key_prefix, group = "99 AI Agent", mode = { "n", "v" } },
      },
    },
  },
  {
    "jellydn/99",
    branch = "feature/blink-cmp-source", -- Testing blink.cmp support PR
    config = function()
      local _99 = require "99"

      _99.setup {
        model = "zai-coding-plan/glm-4.7",
        completion = {
          source = "blink",
          -- Custom skills folder alongside the plugin config
          custom_rules = {
            vim.fn.stdpath "config" .. "/lua/plugins/extra/99-skills/",
          },
        },
        md_files = {
          "AGENTS.md",
        },
      }

      -- Keybindings
      vim.keymap.set("n", mapping_key_prefix .. "f", function()
        _99.fill_in_function()
      end, { desc = "99: Fill in function" })

      vim.keymap.set("v", mapping_key_prefix .. "v", function()
        _99.visual()
      end, { desc = "99: Visual selection AI" })

      vim.keymap.set("v", mapping_key_prefix .. "s", function()
        _99.stop_all_requests()
      end, { desc = "99: Stop all requests" })

      -- Prompt variants - opens floating window for custom prompt input
      vim.keymap.set("n", mapping_key_prefix .. "p", function()
        _99.fill_in_function_prompt()
      end, { desc = "99: Fill in function with prompt" })

      vim.keymap.set("v", mapping_key_prefix .. "p", function()
        _99.visual_prompt()
      end, { desc = "99: Visual selection with prompt" })
    end,
  },
}
