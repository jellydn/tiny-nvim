-- This configuration sets up sidekick.nvim with which-key integration and custom keybindings.
local mapping_key_prefix = vim.g.ai_prefix_key or "<leader>a"

return {
  -- Register AI Code group in which-key for sidekick keybindings
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { mapping_key_prefix, group = "AI Code", mode = { "n", "v" } },
      },
    },
  },
  {
    "saghen/blink.cmp",
    ---@module 'blink.cmp'
    opts = {
      keymap = {
        ["<Tab>"] = {
          "snippet_forward",
          function() -- sidekick next edit suggestion
            return require("sidekick").nes_jump_or_apply()
          end,
          function() -- if you are using Neovim's native inline completions
            return vim.lsp.inline_completion.get()
          end,
          "fallback",
        },
      },
    },
  },
  -- Disable copilot chat if using sidekick
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    enabled = false,
  },
  {
    "folke/sidekick.nvim",
    opts = {
      cli = {
        mux = {
          -- Terminal multiplexer backend for Sidekick CLI integration
          -- Options: "tmux" or "zellij"
          -- Determines which multiplexer is used to spawn and manage CLI sessions
          backend = "tmux",
          enabled = true,
        },
      },
    },
  -- stylua: ignore
  keys = {
    {
      "<tab>",
      function()
        -- if there is a next edit, jump to it, otherwise apply it if any
        if not require("sidekick").nes_jump_or_apply() then
          return "<Tab>" -- fallback to normal tab
        end
      end,
      expr = true,
      desc = "Goto/Apply Next Edit Suggestion",
    },
    {
      mapping_key_prefix .. "a",
      function() require("sidekick.cli").toggle() end,
      desc = "Sidekick Toggle CLI",
    },
    {
      mapping_key_prefix .. "s",
      function() require("sidekick.cli").select() end,
      -- Or to select only installed tools:
      -- require("sidekick.cli").select({ filter = { installed = true } })
      desc = "Select CLI",
    },
    {
      mapping_key_prefix .. "t",
      function() require("sidekick.cli").send({ msg = "{this}" }) end,
      mode = { "x", "n" },
      desc = "Send This",
    },
    {
      mapping_key_prefix .. "v",
      function() require("sidekick.cli").send({ msg = "{selection}" }) end,
      mode = { "x" },
      desc = "Send Visual Selection",
    },
    {
      mapping_key_prefix .. "p",
      function() require("sidekick.cli").prompt() end,
      mode = { "n", "x" },
      desc = "Sidekick Select Prompt",
    },
    {
      "<c-.>",
      function() require("sidekick.cli").focus() end,
      mode = { "n", "x", "i", "t" },
      desc = "Sidekick Switch Focus",
    },
    -- Example of a keybinding to open Claude directly
    {
      mapping_key_prefix .. "c",
      function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end,
      desc = "Sidekick Toggle Claude",
    },
    -- Generate commit message based on the git diff
    {
      mapping_key_prefix .. "m",
      function()
        local prompt = "Run git diff --staged then write commit message for the change with commitizen convention. Write clear, informative commit messages that explain the 'what' and 'why' behind changes, not just the 'how'."
        require("sidekick.cli").send({ name= "copilot", focus = true, msg = prompt, submit = true })
      end,
      desc = "Sidekick - Generate commit message for staged changes",
    },
  },
  },
}
