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
    "ThePrimeagen/99",
    config = function()
      local _99 = require "99"

      _99.setup {
        model = "zai-coding-plan/glm-4.7",
        tmp_dir = "./tmp",
        completion = {
          source = "blink",
          custom_rules = {
            vim.fn.stdpath "config" .. "/lua/plugins/extra/99-skills/",
          },
        },
        md_files = {
          "AGENTS.md",
        },
      }

      -- Search - runs prompt and populates quickfix list
      vim.keymap.set("n", mapping_key_prefix .. "s", function()
        _99.search()
      end, { desc = "99: Search" })

      -- Visual selection AI
      vim.keymap.set("v", mapping_key_prefix .. "v", function()
        _99.visual()
      end, { desc = "99: Visual selection AI" })

      -- Stop all in-flight requests
      vim.keymap.set("n", mapping_key_prefix .. "x", function()
        _99.stop_all_requests()
      end, { desc = "99: Stop all requests" })

      -- Clear previous requests
      vim.keymap.set("n", mapping_key_prefix .. "c", function()
        _99.clear_previous_requests()
      end, { desc = "99: Clear previous requests" })

      -- View logs
      vim.keymap.set("n", mapping_key_prefix .. "l", function()
        _99.view_logs()
      end, { desc = "99: View logs" })
    end,
  },
}
