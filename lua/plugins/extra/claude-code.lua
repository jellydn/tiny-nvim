-- Claude Code Plugin for Neovim
-- 
-- Usage:
--   • Toggle Claude: <C-,> (Control + comma) in normal or terminal mode
--   • Continue conversation: <leader>Cc
--   • Verbose mode: <leader>Cv
--
-- The plugin opens in a floating window covering 90% of the screen.
-- You can interact with Claude directly from within Neovim for coding assistance.

local mapping_key_prefix = "<leader>C"

return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { mapping_key_prefix, group = "Claude Code", mode = { "n", "v" } },
      },
    },
  },
  {
    "greggh/claude-code.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      keymaps = {
        toggle = {
          normal = "<C-,>",
          terminal = "<C-,>",
          variants = {
            continue = "<leader>Cc",
            verbose = "<leader>Cv",
          },
        },
      },
      window = {
        position = "float",
        float = {
          width = "90%",
          height = "90%",
          row = "center",
          col = "center",
          relative = "editor",
          border = "double",
        },
      },
    },
  },
}
