-- Claude Code Plugin for Neovim (coder/claudecode.nvim)
--
-- Usage:
--   • Toggle Claude: <C-,> (Control + comma) in normal or terminal mode
--   • Send selection: <leader>Cs (visual mode)
--   • Add current buffer: <leader>Cb
--   • Focus Claude: <leader>Cf
--   • Select prompt: <leader>Cp (normal/visual mode)
--
-- The plugin opens in a floating window covering 90% of the screen.
-- Note: Prompts are inserted into the terminal input for you to review before sending.

-- Constants
local MAPPING_PREFIX = "<leader>C"
local TOGGLE_KEY = "<C-,>"
local MAX_RETRY_ATTEMPTS = 5
local INITIAL_RETRY_DELAY_MS = 100
local PROMPT_PREVIEW_LENGTH = 50
local FLOAT_WIDTH = 0.9
local FLOAT_HEIGHT = 0.9

-- Default prompts (can be extended via opts.prompts)
local default_prompts = {
  commit = "Run git diff --staged then do atomic commit message for the change with commitizen convention. Write clear, informative commit messages that explain the 'what' and 'why' behind changes, not just the 'how'.",
  document = "Add documentation comments to this code following best practices.",
  explain = "Explain this code",
  fix = "Can you fix the issues in this code?",
  optimize = "How can this code be optimized?",
  refactor = "Refactor this code to improve readability and maintainability while preserving functionality.",
  review = "Can you review this code for any issues or improvements?",
  security = "Review this code for potential security vulnerabilities.",
  tests = "Can you write tests for this code?",
}

-- Merged prompts (populated on setup)
local prompts = vim.deepcopy(default_prompts)

--- Find Claude Code terminal window and buffer
---@return integer|nil win, integer|nil buf
local function find_claude_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
      local name = vim.api.nvim_buf_get_name(buf)
      if name:lower():match("term://.*claude") then
        return win, buf
      end
    end
  end
  return nil, nil
end

--- Send text to Claude Code terminal (types into terminal input)
---@param text string
---@return boolean success
local function send_to_claude(text)
  local win, buf = find_claude_window()
  if not win or not buf then
    return false
  end

  -- Focus the Claude window
  vim.api.nvim_set_current_win(win)

  -- Get channel and send text
  local chan = vim.bo[buf].channel
  if chan and chan > 0 then
    -- Escape special characters and send without newline (user reviews before pressing Enter)
    local safe_text = text:gsub("[\r\n]+", " ")
    vim.api.nvim_chan_send(chan, safe_text)
    -- Enter insert mode in terminal
    vim.cmd("startinsert")
    return true
  end

  return false
end

--- Open Claude, focus it, and insert a prompt
---@param prompt string
local function claude_prompt(prompt)
  -- If terminal window exists and visible, send immediately
  if send_to_claude(prompt) then
    return
  end

  -- Open Claude terminal
  vim.cmd("ClaudeCode")

  -- Retry with exponential backoff until window is available
  local attempts = 0
  local delay = INITIAL_RETRY_DELAY_MS

  local function try_send()
    attempts = attempts + 1
    if send_to_claude(prompt) then
      return
    end
    if attempts < MAX_RETRY_ATTEMPTS then
      delay = delay * 2
      vim.defer_fn(try_send, delay)
    else
      vim.notify(
        "Claude terminal not ready. Try running :ClaudeCode manually and retry.",
        vim.log.levels.WARN
      )
    end
  end

  vim.defer_fn(try_send, delay)
end

--- Show prompt picker and send selected prompt
local function select_prompt()
  local names = vim.tbl_keys(prompts)
  table.sort(names)
  local items = vim.tbl_map(function(name)
    return { name = name, prompt = prompts[name] }
  end, names)

  vim.ui.select(items, {
    prompt = "Select Claude Prompt:",
    format_item = function(item)
      local preview = #item.prompt > PROMPT_PREVIEW_LENGTH
          and item.prompt:sub(1, PROMPT_PREVIEW_LENGTH) .. "..."
        or item.prompt
      return item.name .. ": " .. preview
    end,
  }, function(choice)
    if choice then
      claude_prompt(choice.prompt)
    end
  end)
end

--- Create a keymap spec for a prompt
---@param key string
---@param prompt_name string
---@param desc string
---@param modes? string|string[]
---@return table
local function prompt_keymap(key, prompt_name, desc, modes)
  return {
    MAPPING_PREFIX .. key,
    function()
      claude_prompt(prompts[prompt_name])
    end,
    desc = desc,
    mode = modes or "n",
  }
end

return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { MAPPING_PREFIX, group = "Claude Code", mode = { "n", "v" } },
      },
    },
  },
  {
    "coder/claudecode.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    config = function(_, opts)
      -- Merge custom prompts if provided
      if opts.prompts then
        prompts = vim.tbl_deep_extend("force", prompts, opts.prompts)
        opts.prompts = nil -- Remove before passing to plugin
      end
      require("claudecode").setup(opts)
    end,
    keys = {
      { TOGGLE_KEY, "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { MAPPING_PREFIX .. "c", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { MAPPING_PREFIX .. "f", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { MAPPING_PREFIX .. "s", "<cmd>ClaudeCodeSend<cr>", desc = "Send to Claude", mode = "v" },
      { MAPPING_PREFIX .. "b", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add Buffer to Claude" },
      { MAPPING_PREFIX .. "a", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Diff" },
      { MAPPING_PREFIX .. "d", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Diff" },
      { MAPPING_PREFIX .. "p", select_prompt, desc = "Select Prompt", mode = { "n", "v" } },
      -- Direct prompt keymaps
      prompt_keymap("e", "explain", "Explain Code", { "n", "v" }),
      prompt_keymap("r", "review", "Review Code", { "n", "v" }),
      prompt_keymap("t", "tests", "Write Tests", { "n", "v" }),
      prompt_keymap("m", "commit", "Generate Commit Message"),
      prompt_keymap("o", "optimize", "Optimize Code", { "n", "v" }),
      prompt_keymap("x", "fix", "Fix Issues", { "n", "v" }),
      prompt_keymap("R", "refactor", "Refactor Code", { "n", "v" }),
      prompt_keymap("D", "document", "Add Documentation", { "n", "v" }),
      prompt_keymap("S", "security", "Security Review", { "n", "v" }),
    },
    opts = {
      -- Custom prompts can be added here:
      -- prompts = {
      --   my_prompt = "My custom prompt text",
      -- },
      terminal = {
        snacks_win_opts = {
          position = "float",
          width = FLOAT_WIDTH,
          height = FLOAT_HEIGHT,
          border = "double",
          keys = {
            claude_hide = {
              TOGGLE_KEY,
              function(self)
                self:hide()
              end,
              mode = "t",
              desc = "Hide Claude",
            },
          },
        },
      },
    },
  },
}
