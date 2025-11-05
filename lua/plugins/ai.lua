-- Setup AI with sidekick.nvim
return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>a", group = "ai" },
      },
    },
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
        tools = {
          -- Based on https://github.com/folke/sidekick.nvim/issues/158#issuecomment-3491732950
          amp = {
            cmd = { "amp" },
            format = function(text)
              local Text = require "sidekick.text"
              Text.transform(text, function(str)
                return str:find "[^%w/_%.%-]" and ('"' .. str .. '"') or str
              end, "SidekickLocFile")
              local ret = Text.to_string(text)
              -- transform line ranges to a format that amp understands
              ret = ret:gsub("@([^ ]+)%s*:L(%d+):C%d+%-L(%d+):C%d+", "@%1#L%2-%3") -- @file :L5:C20-L6:C8 => @file#L5-6
              ret = ret:gsub("@([^ ]+)%s*:L(%d+):C%d+%-C%d+", "@%1#L%2") -- @file :L5:C9-C29 => @file#L5
              ret = ret:gsub("@([^ ]+)%s*:L(%d+)%-L(%d+)", "@%1#L%2-%3") -- @file :L5-L13 => @file#L5-13
              ret = ret:gsub("@([^ ]+)%s*:L(%d+):C%d+", "@%1#L%2") -- @file :L5:C9 => @file#L5
              ret = ret:gsub("@([^ ]+)%s*:L(%d+)", "@%1#L%2") -- @file :L5 => @file#L5
              return ret
            end,
          },
        },
      },
    },
    -- stylua: ignore
    keys = {
      {
        "<leader>aa",
        function() require("sidekick.cli").toggle() end,
        desc = "Sidekick Toggle CLI",
      },
      {
        "<leader>as",
        function()
          require("sidekick.cli").select()
          -- Or to select only installed tools:
          -- require("sidekick.cli").select({ filter = { installed = true } })
        end,
        desc = "Select CLI",
      },
      {
        "<leader>ad",
        function() require("sidekick.cli").close() end,
        desc = "Detach a CLI session",
      },
      {
        "<leader>at",
        function() require("sidekick.cli").send({ msg = "{this}" }) end,
        mode = { "x", "n" },
        desc = "Send This",
      },
      {
        "<leader>af",
        function() require("sidekick.cli").send({ msg = "{file}" }) end,
        desc = "Send File",
      },
      {
        "<leader>av",
        function() require("sidekick.cli").send({ msg = "{selection}" }) end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      {
        "<leader>ap",
        function() require("sidekick.cli").prompt() end,
        mode = { "n", "x" },
        desc = "Sidekick Select Prompt",
      },
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
        "<c-.>",
        function() require("sidekick.cli").focus() end,
        mode = { "n", "x", "i", "t" },
        desc = "Sidekick Switch Focus",
      },
      {
        "<leader>ac",
        function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end,
        desc = "Sidekick Toggle Claude",
      },
      -- Generate commit message based on the git diff
      {
        "<leader>am",
        function()
          local prompt =
          "Run git diff --staged then do atomic commit message for the change with commitizen convention. Write clear, informative commit messages that explain the 'what' and 'why' behind changes, not just the 'how'."
          require("sidekick.cli").send({ focus = true, msg = prompt, submit = true })
        end,
        desc = "Sidekick - Generate commit message for staged changes",
      },
    },
  },
}
