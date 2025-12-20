-- Setup AI with sidekick.nvim

-- Constants for special tokens
local SIDEKICK_TOKENS = {
  THIS = "{this}",
  FILE = "{file}",
  SELECTION = "{selection}",
}

-- Reusable prompts
local COMMIT_PROMPT =
  "Run git diff --staged then do atomic commit message for the change with commitizen convention. Write clear, informative commit messages that explain the 'what' and 'why' behind changes, not just the 'how'."

--- Safe require wrapper with error notification
---@param module string Module name to require
---@return table|nil The required module or nil if failed
local function safe_require(module)
  local ok, mod = pcall(require, module)
  if not ok then
    vim.notify("Failed to load " .. module .. ": " .. tostring(mod), vim.log.levels.ERROR)
    return nil
  end
  return mod
end

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
  -- integration with snacks.nvim for sending selection to sidekick
  {
    "folke/snacks.nvim",
    optional = true,
    opts = {
      picker = {
        actions = {
          sidekick_send = function(...)
            return require("sidekick.cli.picker.snacks").send(...)
          end,
        },
        win = {
          input = {
            keys = {
              ["<a-a>"] = {
                "sidekick_send",
                mode = { "n", "i" },
              },
            },
          },
        },
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
              -- Quote file paths containing special characters
              Text.transform(text, function(str)
                return str:find "[^%w/_%.%-]" and ('"' .. str .. '"') or str
              end, "SidekickLocFile")
              local ret = Text.to_string(text)
              -- Transform Sidekick location format to amp's format
              -- Multiline range with columns: @file :L5:C20-L6:C8 => @file#L5-6
              ret = ret:gsub("@([^ ]+)%s*:L(%d+):C%d+%-L(%d+):C%d+", "@%1#L%2-%3")
              -- Single line range with columns: @file :L5:C9-C29 => @file#L5
              ret = ret:gsub("@([^ ]+)%s*:L(%d+):C%d+%-C%d+", "@%1#L%2")
              -- Multiline range without columns: @file :L5-L13 => @file#L5-13
              ret = ret:gsub("@([^ ]+)%s*:L(%d+)%-L(%d+)", "@%1#L%2-%3")
              -- Single line with column: @file :L5:C9 => @file#L5
              ret = ret:gsub("@([^ ]+)%s*:L(%d+):C%d+", "@%1#L%2")
              -- Single line without column: @file :L5 => @file#L5
              ret = ret:gsub("@([^ ]+)%s*:L(%d+)", "@%1#L%2")
              return ret
            end,
          },
        },
        prompts = {
          -- Simple string prompts
          explain = "Explain this code",
          optimize = "How can this code be optimized?",
          tests = "Can you write tests for this code?",
          -- Prompts with diagnostics context
          diagnostics = {
            msg = "What do the diagnostics in this file mean?",
            diagnostics = true,
          },
          fix = {
            msg = "Can you fix the issues in this code?",
            diagnostics = true,
          },
          review = {
            msg = "Can you review this code for any issues or improvements?",
            diagnostics = true,
          },
          -- Custom prompts
          commit = {
            msg = COMMIT_PROMPT,
          },
          refactor = "Refactor this code to improve readability and maintainability while preserving functionality.",
          document = "Add documentation comments to this code following best practices.",
          security = {
            msg = "Review this code for potential security vulnerabilities.",
            diagnostics = true,
          },
          -- Factory AI use cases
          understand = "Explain the purpose and structure of this code. What does it do and how does it fit into the broader system?",
          coverage = "Analyze this code and suggest improvements to test coverage. What edge cases or scenarios are missing?",
          debug = "Help me debug this code. Analyze the error, suggest root causes, and propose a minimal fix.",
          feature = "Help me implement this feature. Create a plan first, then implement step by step with clear explanations.",
          dependency = "Review this code for dependency issues, security vulnerabilities, and compatibility problems.",
          tdd = "Help with test-driven development. First write tests that define the expected behavior, then implement the code to pass those tests.",
        },
      },
    },
    -- stylua: ignore
    keys = {
      {
        "<leader>aa",
        function()
          local cli = safe_require("sidekick.cli")
          if cli then cli.toggle() end
        end,
        desc = "Sidekick Toggle CLI",
      },
      {
        "<leader>as",
        function()
          local cli = safe_require("sidekick.cli")
          if cli then cli.select() end
        end,
        desc = "Select CLI",
      },
      {
        "<leader>ad",
        function()
          local cli = safe_require("sidekick.cli")
          if cli then cli.close() end
        end,
        desc = "Detach a CLI session",
      },
      {
        "<leader>at",
        function()
          local cli = safe_require("sidekick.cli")
          if cli then cli.send({ msg = SIDEKICK_TOKENS.THIS }) end
        end,
        mode = { "x", "n" },
        desc = "Send This",
      },
      {
        "<leader>af",
        function()
          local cli = safe_require("sidekick.cli")
          if cli then cli.send({ msg = SIDEKICK_TOKENS.FILE }) end
        end,
        desc = "Send File",
      },
      {
        "<leader>av",
        function()
          local cli = safe_require("sidekick.cli")
          if cli then cli.send({ msg = SIDEKICK_TOKENS.SELECTION }) end
        end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      {
        "<leader>ap",
        function()
          local cli = safe_require("sidekick.cli")
          if cli then cli.prompt() end
        end,
        mode = { "n", "x" },
        desc = "Sidekick Select Prompt",
      },
      {
        "<tab>",
        function()
          local sidekick = safe_require("sidekick")
          if not sidekick then
            return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
          end
          -- If there is a next edit, jump to it, otherwise apply it if any
          local result = sidekick.nes_jump_or_apply()
          if result == false or result == nil then
            return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
          end
        end,
        expr = true,
        desc = "Goto/Apply Next Edit Suggestion",
      },
      {
        "<c-.>",
        function()
          local cli = safe_require("sidekick.cli")
          if cli then cli.focus() end
        end,
        mode = { "n", "x", "i", "t" },
        desc = "Sidekick Switch Focus",
      },
      {
        "<leader>ac",
        function()
          local cli = safe_require("sidekick.cli")
          if cli then cli.toggle({ name = "claude", focus = true }) end
        end,
        desc = "Sidekick Toggle Claude",
      },
      {
        "<leader>am",
        function()
          local cli = safe_require("sidekick.cli")
          if cli then
            cli.send({ focus = true, msg = COMMIT_PROMPT, submit = true })
          end
        end,
        desc = "Sidekick - Generate commit message for staged changes",
      },
    },
  },
}
