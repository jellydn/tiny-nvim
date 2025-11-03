-- This configuration sets up CopilotChat with which-key integration and custom keybindings.
local mapping_key_prefix = vim.g.ai_prefix_key or "<leader>a"

return {
  -- Register AI Code group in which-key for CopilotChat keybindings
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { mapping_key_prefix, group = "AI Code", mode = { "n", "v" } },
        { "<leader>gm", group = "Copilot Chat" },
      },
    },
  },
  -- Disable sidekick if using CopilotChat
  {
    "folke/sidekick.nvim",
    enabled = false,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    optional = true,
    opts = {
      file_types = { "markdown", "copilot-chat" },
    },
    ft = { "markdown", "copilot-chat" },
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "main",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    opts = {
      headers = {
        user = "  User ",
        assistant = "  Copilot ",
        tool = "󰊳  Tool ",
      },
      mappings = {
        -- Use tab for completion
        complete = {
          detail = "Use @<Tab> or /<Tab> for options.",
          insert = "<Tab>",
        },
        -- Close the chat
        close = {
          normal = "q",
          insert = "<C-c>",
        },
        -- Reset the chat buffer
        reset = {
          normal = "<C-x>",
          insert = "<C-x>",
        },
        -- Submit the prompt to Copilot
        submit_prompt = {
          normal = "<CR>",
          insert = "<C-CR>",
        },
        -- Accept the diff
        accept_diff = {
          normal = "<C-y>",
          insert = "<C-y>",
        },
        -- Show help
        show_help = {
          normal = "g?",
        },
      },
    },
    -- stylua: ignore
    keys = {
      -- Show prompts actions with telescope
      {
        mapping_key_prefix .. "p",
        function()
          require("CopilotChat").select_prompt {
            context = {
              "buffers",
            },
          }
        end,
        desc = "CopilotChat - Prompt actions",
      },
      {
        mapping_key_prefix .. "p",
        function()
          require("CopilotChat").select_prompt()
        end,
        mode = "x",
        desc = "CopilotChat - Prompt actions",
      },
      -- Generate commit message based on the git diff
      {
        mapping_key_prefix .. "m",
        "<cmd>CopilotChatCommit<cr>",
        desc = "CopilotChat - Generate commit message for all changes",
      },
      -- Fix the issue with diagnostic
      { mapping_key_prefix .. "f", "<cmd>CopilotChatFix<cr>", desc = "CopilotChat - Fix Diagnostic" },
      -- Clear buffer and chat history
      { mapping_key_prefix .. "l", "<cmd>CopilotChatReset<cr>", desc = "CopilotChat - Clear buffer and chat history" },
      -- Toggle Copilot Chat Vsplit
      { mapping_key_prefix .. "v", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat - Toggle" },
      -- Copilot Chat Models
      { mapping_key_prefix .. "?", "<cmd>CopilotChatModels<cr>", desc = "CopilotChat - Select Models" },
    },
  },
}
