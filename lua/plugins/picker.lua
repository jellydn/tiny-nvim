-- Module state for tracking hidden file toggle
local _hidden_files = false
local _unrestricted_files = false

local function get_visual_selection()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local lines = vim.fn.getregion(vim.fn.getpos "v", vim.fn.getpos ".", { type = mode })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    return table.concat(lines, "\n")
  end
  return ""
end

local function pick_files(opts)
  local MiniPick = require "mini.pick"
  MiniPick.builtin.files(
    nil,
    vim.tbl_deep_extend("force", opts or {}, {
      mappings = {
        toggle_hidden = {
          char = "<M-h>",
          func = function()
            _hidden_files = not _hidden_files
            _unrestricted_files = false
            local cmd = _hidden_files and { "fd", "-H", "-t", "f" } or { "fd", "-t", "f" }
            vim.notify("Hidden files: " .. tostring(_hidden_files), vim.log.levels.INFO)
            MiniPick.builtin.cli({
              command = cmd,
              spawn_opts = { cwd = opts and opts.source and opts.source.cwd },
            }, {
              source = {
                name = _hidden_files and "Files (hidden)" or "Files",
                choose = MiniPick.default_choose,
                preview = MiniPick.default_preview,
              },
            })
          end,
        },
        toggle_unrestricted = {
          char = "<M-u>",
          func = function()
            _unrestricted_files = not _unrestricted_files
            _hidden_files = false
            local cmd = _unrestricted_files and { "fd", "-HI", "-t", "f" } or { "fd", "-t", "f" }
            vim.notify("Include gitignored: " .. tostring(_unrestricted_files), vim.log.levels.INFO)
            MiniPick.builtin.cli({
              command = cmd,
              spawn_opts = { cwd = opts and opts.source and opts.source.cwd },
            }, {
              source = {
                name = _unrestricted_files and "Files (unrestricted)" or "Files",
                choose = MiniPick.default_choose,
                preview = MiniPick.default_preview,
              },
            })
          end,
        },
      },
    })
  )
end

-- Find all files including gitignored
local function pick_files_unrestricted(opts)
  local MiniPick = require "mini.pick"
  MiniPick.builtin.cli({
    command = { "fd", "-HI", "-t", "f" },
    spawn_opts = { cwd = opts and opts.source and opts.source.cwd },
  }, {
    source = {
      name = "Files (all)",
      choose = MiniPick.default_choose,
      preview = MiniPick.default_preview,
    },
  })
end

-- Find git files including untracked files
local function pick_git_files_all(opts)
  local MiniPick = require "mini.pick"
  MiniPick.builtin.cli({
    command = { "git", "ls-files", "-co", "--exclude-standard" },
    spawn_opts = { cwd = opts and opts.source and opts.source.cwd },
  }, {
    source = {
      name = "Git Files (all)",
      choose = MiniPick.default_choose,
      preview = MiniPick.default_preview,
    },
  })
end

-- Normal grep (respects .gitignore)
-- opts.pattern: optional pattern to pre-fill search
local function pick_grep_live(opts)
  local MiniPick = require "mini.pick"
  if opts and opts.pattern then
    local pattern = opts.pattern
    opts.pattern = nil
    MiniPick.builtin.grep({ pattern = pattern }, opts)
  else
    MiniPick.builtin.grep_live(nil, opts or {})
  end
end

-- Grep with hidden files (respects .gitignore)
-- Asks for pattern, then searches in hidden files like .env
local function pick_grep_unrestricted(opts)
  local pattern = vim.fn.input "Grep (hidden) pattern: "
  if pattern == "" then
    return
  end

  local MiniPick = require "mini.pick"
  MiniPick.builtin.cli({
    command = { "rg", "--hidden", "--line-number", "--color=never", "--with-filename", pattern },
    spawn_opts = { cwd = opts and opts.source and opts.source.cwd },
  }, {
    source = {
      name = "Grep (hidden)",
      choose = MiniPick.default_choose,
      preview = MiniPick.default_preview,
    },
  })
end

-- Grep for word under cursor
local function pick_grep_cword(opts)
  local word = vim.fn.expand "<cword>"
  if word == "" then
    vim.notify("No word under cursor", vim.log.levels.WARN)
    return
  end
  pick_grep_live(vim.tbl_deep_extend("force", opts or {}, { pattern = word }))
end

-- Grep for WORD under cursor
local function pick_grep_cWORD(opts)
  local word = vim.fn.expand "<cWORD>"
  if word == "" then
    vim.notify("No WORD under cursor", vim.log.levels.WARN)
    return
  end
  pick_grep_live(vim.tbl_deep_extend("force", opts or {}, { pattern = word }))
end

-- Grep project (like fzf-lua grep_project)
local function pick_grep_project(opts)
  local pattern = vim.fn.input "Grep pattern: "
  if pattern == "" then
    return
  end

  local MiniPick = require "mini.pick"
  MiniPick.builtin.cli({
    command = { "rg", "--line-number", "--color=never", "--with-filename", "--smart-case", pattern },
    spawn_opts = { cwd = opts and opts.source and opts.source.cwd },
  }, {
    source = {
      name = "Grep Project",
      choose = MiniPick.default_choose,
      preview = MiniPick.default_preview,
    },
  })
end

-- Live grep including hidden files
local function pick_grep_live_hidden(opts)
  local MiniPick = require "mini.pick"
  MiniPick.builtin.cli({
    command = {
      "rg",
      "--hidden",
      "--line-number",
      "--color=never",
      "--with-filename",
      "--smart-case",
      "-g",
      "!{.git,node_modules}/",
      ".",
    },
    spawn_opts = { cwd = opts and opts.source and opts.source.cwd },
  }, {
    source = {
      name = "Grep (hidden)",
      choose = MiniPick.default_choose,
      preview = MiniPick.default_preview,
    },
  })
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

local function git_cli(command, fallback)
  if not require("utils.path").is_git_repo() then
    vim.notify(fallback or "Not a git repository", vim.log.levels.WARN)
    return
  end

  require("mini.pick").builtin.cli { command = command }
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

-- Git branches picker
local function pick_git_branches()
  git_cli({ "git", "branch", "-a", "--format=%(refname:short)" }, "Not a git repository")
end

-- Git buffer commits (commits for current file)
local function pick_git_bcommits()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return
  end
  git_cli({ "git", "log", "--oneline", "--follow", "--", file }, "Not a git repository")
end

-- Todo comments picker using mini.pick
local function pick_todo_comments(keywords)
  local MiniPick = require "mini.pick"
  local kw_pattern = keywords and table.concat(keywords, "|") or "TODO|HACK|WARN|PERF|NOTE|FIX|FIXME"
  MiniPick.builtin.cli({
    command = {
      "rg",
      "--line-number",
      "--color=never",
      "--with-filename",
      "--smart-case",
      "(" .. kw_pattern .. ")[:( ]",
    },
  }, {
    source = {
      name = keywords and "Todo/Fix/Fixme" or "Todo Comments",
      choose = MiniPick.default_choose,
      preview = MiniPick.default_preview,
    },
  })
end

return {
  {
    "echasnovski/mini.pick",
    opts = {},
    config = function(_, opts)
      local MiniPick = require "mini.pick"
      MiniPick.setup(opts)
      vim.ui.select = MiniPick.ui_select
    end,
    keys = {
      -- Picker
      { "<leader>,", pick_buffers, desc = "Switch Buffer" },
      { "<leader>/", pick_grep_live, desc = "Grep" },
      { "<leader>:", pick_commands_history, desc = "Command History" },
      { "<leader><space>", pick_files, desc = "Find Files" },

      -- Ctrl shortcuts
      {
        "<C-g>",
        pick_grep_project,
        desc = "Grep Project",
      },
      {
        "<C-g>",
        function()
          local text = get_visual_selection()
          if text ~= "" then
            pick_grep_live { pattern = text }
          else
            vim.notify("No text selected", vim.log.levels.WARN)
          end
        end,
        desc = "Grep visual selection",
        mode = "v",
      },
      {
        "<C-e>",
        pick_files,
        desc = "Find Files at project directory",
      },

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
      {
        "<leader>ff",
        function()
          pick_git_files_all()
        end,
        desc = "Find Git Files",
      },
      { "<leader>fa", pick_files_unrestricted, desc = "Find Files (all)" },
      {
        "<leader>fg",
        function()
          pick_git_files_all()
        end,
        desc = "Find Git Files (including untracked)",
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
        "<leader>fl",
        pick_grep_live_hidden,
        desc = "Find Live Grep (including hidden files)",
      },
      -- git
      {
        "<leader>gc",
        function()
          require("mini.extra").pickers.git_commits()
        end,
        desc = "Git Commits",
      },
      {
        "<leader>gS",
        function()
          require("mini.extra").pickers.git_files { scope = "modified" }
        end,
        desc = "Git Modified",
      },
      {
        "<leader>gs",
        function()
          if not require("utils.path").is_git_repo() then
            vim.notify("Not a git repository", vim.log.levels.WARN)
            return
          end
          local output = vim.fn.systemlist "git status --short"
          if #output == 0 then
            vim.notify("No modified or untracked files", vim.log.levels.INFO)
            return
          end
          local items = {}
          for _, line in ipairs(output) do
            local file = line:match "^...(.+)$"
            if file then
              table.insert(items, vim.trim(file))
            end
          end
          require("mini.pick").start {
            source = {
              name = "Git Status",
              items = items,
              show = function(buf_id, items_to_show, query)
                require("mini.pick").default_show(buf_id, items_to_show, query, { show_icons = true })
              end,
            },
          }
        end,
        desc = "Git Status",
      },
      {
        "<leader>gb",
        pick_git_branches,
        desc = "Git Branches",
      },
      {
        "<leader>gB",
        pick_git_bcommits,
        desc = "Git Buffer Commits",
      },

      -- Grep
      { "<leader>sb", pick_buffer_lines, desc = "Search Current Buffer" },
      { "<leader>sB", pick_open_buffer_lines, desc = "Search Lines in Open Buffers" },
      { "<leader>sg", pick_grep_unrestricted, desc = "Grep (all files)" },
      {
        "<leader>sw",
        pick_grep_cword,
        desc = "Search word under cursor",
      },
      {
        "<leader>sw",
        function()
          local text = get_visual_selection()
          if text ~= "" then
            pick_grep_live { pattern = text }
          else
            vim.notify("No text selected", vim.log.levels.WARN)
          end
        end,
        desc = "Search word in visual selection",
        mode = "v",
      },
      {
        "<leader>sW",
        pick_grep_cWORD,
        desc = "Search WORD under cursor",
      },

      -- search
      {
        '<leader>s"',
        function()
          require("mini.extra").pickers.registers()
        end,
        desc = "Registers",
      },
      {
        "<leader>sa",
        function()
          require("mini.extra").pickers.commands()
        end,
        desc = "Find Actions (Commands)",
      },
      {
        "<leader>s:",
        pick_commands_history,
        desc = "Command History",
      },
      { "<leader>sc", pick_autocmds, desc = "Autocmds" },
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
          pick_diagnostic "current"
        end,
        desc = "Document Diagnostics",
      },
      {
        "<leader>sD",
        function()
          pick_diagnostic "all"
        end,
        desc = "Workspace Diagnostics",
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
        "<leader>si",
        function()
          pick_lsp "incoming_calls"
        end,
        desc = "LSP Incoming Calls",
      },
      {
        "<leader>so",
        function()
          pick_lsp "outgoing_calls"
        end,
        desc = "LSP Outgoing Calls",
      },
      {
        "<leader>sj",
        function()
          pick_list "jump"
        end,
        desc = "Search Jumplist",
      },
      {
        "<leader>sk",
        function()
          require("mini.extra").pickers.keymaps()
        end,
        desc = "Search Keymaps",
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
        desc = "Search Marks",
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
        desc = "Search Quickfix",
      },
      {
        "<leader>st",
        function()
          pick_todo_comments()
        end,
        desc = "Todo Comments",
      },
      {
        "<leader>sT",
        function()
          pick_todo_comments { "TODO", "FIX", "FIXME" }
        end,
        desc = "Todo/Fix/Fixme",
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
