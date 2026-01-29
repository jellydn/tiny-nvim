-- Claude Code integration with prompt shortcuts

-- Configuration
local MAPPING_PREFIX = "<leader>C"
local TOGGLE_KEY = "<C-,>"
local MAX_RETRY_ATTEMPTS = 5
local INITIAL_RETRY_DELAY_MS = 100
local PROMPT_PREVIEW_LENGTH = 50

-- Prompts (can be extended via opts.prompts)
local prompts = {
  commit = "Run git diff --staged then do atomic commit message for the change with commitizen convention. Write clear, informative commit messages that explain the 'what' and 'why' behind changes, not just the 'how'.",
  explain = "Explain this code",
  fix = "Can you fix the issues in this code?",
  optimize = "How can this code be optimized?",
  refactor = "Refactor this code to improve readability and maintainability while preserving functionality.",
  review = "Can you review this code for any issues or improvements?",
  tests = "Can you write tests for this code?",
  diagnostics = "Analyze the diagnostics/errors in this code and suggest fixes.",
  document = "Add documentation comments to this code following best practices.",
  security = "Review this code for potential security vulnerabilities.",
  understand = "Explain the purpose and structure of this code. What does it do and how does it fit into the broader system?",
  coverage = "Analyze this code and suggest improvements to test coverage. What edge cases or scenarios are missing?",
  debug = "Help me debug this code. Analyze the error, suggest root causes, and propose a minimal fix.",
  feature = "Help me implement this feature. Create a plan first, then implement step by step with clear explanations.",
  dependency = "Review this code for dependency issues, security vulnerabilities, and compatibility problems.",
  tdd = "Help with test-driven development. First write tests that define the expected behavior, then implement the code to pass those tests.",
}

--- Escape text for safe terminal input
---@param text string
---@return string
local function escape_terminal_text(text)
  local result = text:gsub("[\r\n]+", " "):gsub("[%z\1-\31]", ""):gsub("\\", "\\\\")
  return result
end

--- Find Claude Code terminal window and buffer
---@return integer|nil win, integer|nil buf
local function find_claude_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
      local name = vim.api.nvim_buf_get_name(buf)
      if name:lower():match "term://.*claude" then
        return win, buf
      end
    end
  end
  return nil, nil
end

--- Send text to Claude Code terminal
---@param text string
---@return boolean
local function send_to_claude(text)
  local win, buf = find_claude_window()
  if not win or not buf then
    return false
  end

  if not vim.api.nvim_win_is_valid(win) or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  local ok_focus = pcall(vim.api.nvim_set_current_win, win)
  if not ok_focus then
    return false
  end

  local chan = vim.bo[buf].channel
  if not chan or chan <= 0 then
    vim.notify("Invalid terminal channel", vim.log.levels.ERROR)
    return false
  end

  local safe_text = escape_terminal_text(text)
  local ok, err = pcall(vim.api.nvim_chan_send, chan, safe_text)
  if not ok then
    vim.notify("Failed to send to Claude: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  vim.cmd "startinsert"
  return true
end

--- Open Claude and send prompt
---@param prompt string
local function claude_prompt(prompt)
  if send_to_claude(prompt) then
    return
  end

  vim.cmd "ClaudeCode"

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
      vim.notify("Claude terminal not ready. Try running :ClaudeCode manually and retry.", vim.log.levels.WARN)
    end
  end

  vim.defer_fn(try_send, delay)
end

--- Show prompt picker
local function select_prompt()
  local items = {}
  for name, prompt in pairs(prompts) do
    table.insert(items, { name = name, prompt = prompt })
  end

  if #items == 0 then
    vim.notify("No prompts available", vim.log.levels.WARN)
    return
  end

  table.sort(items, function(a, b)
    return a.name < b.name
  end)

  vim.ui.select(items, {
    prompt = "Select Claude Prompt:",
    format_item = function(item)
      local preview = #item.prompt > PROMPT_PREVIEW_LENGTH and item.prompt:sub(1, PROMPT_PREVIEW_LENGTH) .. "..."
        or item.prompt
      return item.name .. ": " .. preview
    end,
  }, function(choice)
    if choice and choice.prompt then
      claude_prompt(choice.prompt)
    end
  end)
end

--- Create keymap for prompt
---@param key string
---@param prompt_name string
---@param desc string
---@param modes? string|string[]
---@return table
local function prompt_keymap(key, prompt_name, desc, modes)
  return {
    MAPPING_PREFIX .. key,
    function()
      local prompt_text = prompts[prompt_name]
      if not prompt_text then
        vim.notify(string.format("Prompt '%s' not found", prompt_name), vim.log.levels.ERROR)
        return
      end
      claude_prompt(prompt_text)
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
    dependencies = { "folke/snacks.nvim" },
    config = function(_, opts)
      if opts.prompts then
        prompts = vim.tbl_deep_extend("force", prompts, opts.prompts)
        opts.prompts = nil
      end
      require("claudecode").setup(opts)
    end,
    -- stylua: ignore
    keys = {
      { TOGGLE_KEY, "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { MAPPING_PREFIX .. "c", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { MAPPING_PREFIX .. "f", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { MAPPING_PREFIX .. "s", "<cmd>ClaudeCodeSend<cr>", desc = "Send to Claude", mode = "v" },
      { MAPPING_PREFIX .. "b", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add Buffer to Claude" },
      { MAPPING_PREFIX .. "a", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Diff" },
      { MAPPING_PREFIX .. "d", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Diff" },
      { MAPPING_PREFIX .. "p", select_prompt, desc = "Select Prompt", mode = { "n", "v" } },
      -- Prompts
      prompt_keymap("e", "explain", "Explain Code", { "n", "v" }),
      prompt_keymap("r", "review", "Review Code", { "n", "v" }),
      prompt_keymap("t", "tests", "Write Tests", { "n", "v" }),
      prompt_keymap("x", "fix", "Fix Issues", { "n", "v" }),
      prompt_keymap("o", "optimize", "Optimize Code", { "n", "v" }),
      prompt_keymap("R", "refactor", "Refactor Code", { "n", "v" }),
      prompt_keymap("D", "document", "Add Documentation", { "n", "v" }),
      prompt_keymap("S", "security", "Security Review", { "n", "v" }),
      prompt_keymap("d", "diagnostics", "Fix Diagnostics", { "n", "v" }),
      prompt_keymap("u", "understand", "Understand Code", { "n", "v" }),
      prompt_keymap("C", "coverage", "Test Coverage", { "n", "v" }),
      prompt_keymap("g", "debug", "Debug Code", { "n", "v" }),
      prompt_keymap("F", "feature", "Implement Feature", { "n", "v" }),
      prompt_keymap("Z", "dependency", "Review Dependencies", { "n", "v" }),
      prompt_keymap("T", "tdd", "TDD Workflow", { "n", "v" }),
      prompt_keymap("m", "commit", "Generate Commit Message"),
    },
    opts = {
      -- Use ccs with GLM model
      terminal_cmd = "ccs glm",
      terminal = {
        snacks_win_opts = {
          position = "float",
          width = 0.9,
          height = 0.9,
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
