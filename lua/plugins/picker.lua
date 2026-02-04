local function pick_files(opts)
  require("mini.pick").builtin.files(nil, opts or {})
end

local function pick_grep_live(opts)
  require("mini.pick").builtin.grep_live(nil, opts or {})
end

local function pick_help()
  require("mini.pick").builtin.help()
end

local function pick_buffers(opts)
  require("mini.pick").builtin.buffers(nil, opts or {})
end

local function pick_resume()
  require("mini.pick").builtin.resume()
end

local function minifiles_toggle(path)
  local mini_files = require "mini.files"
  if not mini_files.close() then
    mini_files.open(path)
  end
end

local function minifiles_open_cwd()
  minifiles_toggle()
end

local function minifiles_open_file()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    minifiles_toggle()
    return
  end

  if vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1 then
    minifiles_toggle(path)
    return
  end

  minifiles_toggle()
end

local function in_git_repo()
  return vim.fn.isdirectory ".git" == 1
end

local function git_cli(command, fallback)
  if not in_git_repo() then
    vim.notify(fallback or "Not a git repository", vim.log.levels.WARN)
    return
  end

  require("mini.pick").builtin.cli(nil, { command = command })
end

local function pick_commands_history()
  require("mini.extra").pickers.history { scope = ":" }
end

local function pick_buffer_lines()
  require("mini.extra").pickers.buf_lines { scope = "current" }
end

local function pick_open_buffer_lines()
  require("mini.extra").pickers.buf_lines { scope = "all" }
end

local function pick_autocmds()
  local MiniPick = require "mini.pick"
  local autocmds = vim.api.nvim_get_autocmds {}
  local items = vim.tbl_map(function(autocmd)
    local events = table.concat(autocmd.event or {}, ",")
    local patterns = table.concat(autocmd.pattern or {}, ",")
    local group = autocmd.group_name or autocmd.group or "-"
    local desc = autocmd.desc or ""
    local cmd = autocmd.command or ""
    return string.format("%s | %s | %s | %s | %s", events, patterns, group, desc, cmd)
  end, autocmds)

  MiniPick.start {
    source = {
      name = "Autocmds",
      items = items,
    },
  }
end

local function pick_list(scope)
  require("mini.extra").pickers.list { scope = scope }
end

local function pick_diagnostic(scope)
  require("mini.extra").pickers.diagnostic { scope = scope }
end

local function pick_lsp(scope)
  require("mini.extra").pickers.lsp { scope = scope }
end

return {
  {
    "echasnovski/mini.pick",
    opts = {},
    keys = {
      -- Picker
      { "<leader>,", pick_buffers, desc = "Buffers" },
      { "<leader>/", pick_grep_live, desc = "Grep" },
      { "<leader>:", pick_commands_history, desc = "Command History" },
      { "<leader><space>", pick_files, desc = "Find Files" },

      -- Explorer
      {
        "<leader>e",
        function()
          minifiles_open_file()
        end,
        desc = "File Explorer",
      },
      {
        "<leader>E",
        function()
          minifiles_open_cwd()
        end,
        desc = "File Explorer (cwd)",
      },

      -- find
      { "<leader>fb", pick_buffers, desc = "Buffers" },
      {
        "<leader>fc",
        function()
          pick_files { source = { cwd = vim.fn.stdpath "config" } }
        end,
        desc = "Find Config File",
      },
      { "<leader>ff", pick_files, desc = "Find Files" },
      {
        "<leader>fg",
        function()
          git_cli({ "git", "ls-files", "--cached", "--others", "--exclude-standard" }, "No git files found")
        end,
        desc = "Find Git Files",
      },
      {
        "<leader>fr",
        function()
          require("mini.extra").pickers.oldfiles()
        end,
        desc = "Recent",
      },
      { "<leader>fR", pick_resume, desc = "Resume" },
      {
        "<leader>fw",
        function()
          pick_grep_live()
        end,
        desc = "Visual selection or word",
        mode = { "n", "x" },
      },

      -- git
      {
        "<leader>gc",
        function()
          require("mini.extra").pickers.git_commits()
        end,
        desc = "Git Log",
      },
      {
        "<leader>gs",
        function()
          require("mini.extra").pickers.git_hunks()
        end,
        desc = "Git Hunks",
      },
      {
        "<leader>gS",
        function()
          git_cli({ "git", "stash", "list" }, "No git stash entries")
        end,
        desc = "Git Stash",
      },

      -- Grep
      { "<leader>sb", pick_buffer_lines, desc = "Buffer Lines" },
      { "<leader>sB", pick_open_buffer_lines, desc = "Grep Open Buffers" },
      { "<leader>sg", pick_grep_live, desc = "Grep" },

      -- search
      {
        '<leader>s"',
        function()
          require("mini.extra").pickers.registers()
        end,
        desc = "Registers",
      },
      { "<leader>sa", pick_autocmds, desc = "Autocmds" },
      { "<leader>sc", pick_commands_history, desc = "Command History" },
      {
        "<leader>sC",
        function()
          require("mini.extra").pickers.commands()
        end,
        desc = "Commands",
      },
      {
        "<leader>sd",
        function()
          pick_diagnostic "all"
        end,
        desc = "Diagnostics",
      },
      {
        "<leader>sD",
        function()
          pick_diagnostic "current"
        end,
        desc = "Buffer Diagnostics",
      },
      { "<leader>sh", pick_help, desc = "Help Pages" },
      {
        "<leader>sH",
        function()
          require("mini.extra").pickers.hl_groups()
        end,
        desc = "Highlights",
      },
      {
        "<leader>sj",
        function()
          pick_list "jump"
        end,
        desc = "Jumps",
      },
      {
        "<leader>sk",
        function()
          require("mini.extra").pickers.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>sl",
        function()
          pick_list "location"
        end,
        desc = "Location List",
      },
      {
        "<leader>sm",
        function()
          require("mini.extra").pickers.marks()
        end,
        desc = "Marks",
      },
      {
        "<leader>sM",
        function()
          require("mini.extra").pickers.man()
        end,
        desc = "Man Pages",
      },
      {
        "<leader>sq",
        function()
          pick_list "quickfix"
        end,
        desc = "Quickfix List",
      },
      {
        "<leader>su",
        function()
          pick_list "change"
        end,
        desc = "Changelist",
      },
      {
        "<leader>uC",
        function()
          require("mini.extra").pickers.colorschemes()
        end,
        desc = "Colorschemes",
      },
      {
        "<leader>sp",
        function()
          pick_grep_live { source = { cwd = vim.fn.stdpath "config" .. "/lua/plugins" } }
        end,
        desc = "Search for Plugin Spec",
      },

      -- LSP
      {
        "gd",
        function()
          pick_lsp "definition"
        end,
        desc = "Goto Definition",
      },
      {
        "gD",
        function()
          pick_lsp "declaration"
        end,
        desc = "Goto Declaration",
      },
      {
        "gr",
        function()
          pick_lsp "references"
        end,
        desc = "References",
        nowait = true,
      },
      {
        "gi",
        function()
          pick_lsp "implementation"
        end,
        desc = "Goto Implementation",
      },
      {
        "gy",
        function()
          pick_lsp "type_definition"
        end,
        desc = "Goto T[y]pe Definition",
      },
      {
        "<leader>ss",
        function()
          pick_lsp "document_symbol"
        end,
        desc = "LSP Symbols",
      },
      {
        "<leader>sS",
        function()
          pick_lsp "workspace_symbol"
        end,
        desc = "LSP Workspace Symbols",
      },
    },
  },
  {
    "echasnovski/mini.extra",
    opts = {},
  },
}
