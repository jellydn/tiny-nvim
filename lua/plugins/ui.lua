local function deduplicate(list)
  local seen = {}
  local result = {}
  for _, item in ipairs(list) do
    if not seen[item] then
      seen[item] = true
      table.insert(result, item)
    end
  end
  return result
end

return {
  "nvim-lua/plenary.nvim",
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    opts = {
      -- NOTE: Refer if any issues with tui like lazygit https://github.com/max397574/better-escape.nvim/issues/85
      default_mappings = false,
      mappings = {
        i = {
          j = {
            k = "<Esc>",
            j = "<Esc>",
          },
        },
      },
    },
  },
  {
    "echasnovski/mini.icons",
    opts = {
      file = {
        [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
        ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
      },
      filetype = {
        dotenv = { glyph = "", hl = "MiniIconsYellow" },
      },
    },
    config = function(_, options)
      local icons = require "mini.icons"
      icons.setup(options)
      -- Mocking methods of 'nvim-tree/nvim-web-devicons' for better integrations with plugins outside 'mini.nvim'
      icons.mock_nvim_web_devicons()
    end,
  },
  {
    "echasnovski/mini.statusline",
    opts = {
      set_vim_settings = false,
      content = {
        active = function()
          local MiniStatusline = require "mini.statusline"
          local mode, mode_hl = MiniStatusline.section_mode { trunc_width = 120 }
          local git = MiniStatusline.section_git { trunc_width = 40 }
          local filename = MiniStatusline.section_filename { trunc_width = 140 }
          local diagnostics = MiniStatusline.section_diagnostics { trunc_width = 75 }
          return MiniStatusline.combine_groups {
            { hl = mode_hl, strings = { mode:upper() } },
            { hl = "MiniStatuslineDevinfo", strings = { git, diagnostics } },
            "%<", -- Mark general truncate point
            { hl = "MiniStatuslineFilename", strings = { filename } },
            "%=", -- End left alignment
            {
              hl = "MiniStatuslineFileinfo",
              strings = {
                vim.bo.filetype ~= ""
                  and require("mini.icons").get("filetype", vim.bo.filetype) .. " " .. vim.bo.filetype,
              },
            },
            { hl = mode_hl, strings = { "%l:%v" } },
          }
        end,
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
      { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete Other Buffers" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
      { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
    },
    opts = {
      options = {
        always_show_bufferline = false,
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
  {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {},
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    keys = {
      { "<c-space>", desc = "Increment Selection" },
      { "<bs>", desc = "Decrement Selection", mode = "x" },
    },
    opts_extend = { "ensure_installed" },
    config = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        opts.ensure_installed = deduplicate(opts.ensure_installed)
      end
      require("nvim-treesitter.configs").setup(opts)
    end,
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
      ensure_installed = {
        "bash",
        "c",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "printf",
        "python",
        "query",
        "regex",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts_extend = { "spec" },
    opts = {
      defaults = {},
      ---@type false | "classic" | "modern" | "helix"
      preset = vim.g.which_key_preset or "helix", -- default is "classic"
      -- Custom helix layout
      win = vim.g.which_key_window or {
        width = { min = 30, max = 60 },
        height = { min = 4, max = 0.85 },
      },
      spec = {
        {
          mode = { "n", "v" },
          { "<leader><tab>", group = "tabs" },
          { "<leader>b", group = "buffer" },
          { "<leader>c", group = "code" },
          { "<leader>f", group = "file/find" },
          { "<leader>g", group = "git" },
          { "<leader>gh", group = "hunks" },
          { "<leader>q", group = "quit/session" },
          { "<leader>s", group = "search" },
          { "<leader>t", group = "toggle" },
          { "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },
          { "<leader>w", group = "windows" },
          { "<leader>x", group = "diagnostics/quickfix", icon = { icon = "󱖫 ", color = "green" } },
          { "[", group = "prev" },
          { "]", group = "next" },
          { "g", group = "goto" },
          { "gs", group = "surround" },
          { "z", group = "fold" },
        },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show { global = false }
        end,
        desc = "Buffer Keymaps (which-key)",
      },
    },
    config = function(_, opts)
      local wk = require "which-key"
      wk.setup(opts)
      if not vim.tbl_isempty(opts.defaults) then
        wk.register(opts.defaults)
      end
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal { "]c", bang = true }
          else
            gs.nav_hunk "next"
          end
        end, "Next Hunk")
        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal { "[c", bang = true }
          else
            gs.nav_hunk "prev"
          end
        end, "Prev Hunk")
        map("n", "]H", function()
          gs.nav_hunk "last"
        end, "Last Hunk")
        map("n", "[H", function()
          gs.nav_hunk "first"
        end, "First Hunk")
        map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
        map("n", "<leader>ghb", function()
          gs.blame_line { full = true }
        end, "Blame Line")
        map("n", "<leader>ghB", function()
          gs.blame()
        end, "Blame Buffer")
        map("n", "<leader>ghd", gs.diffthis, "Diff This")
        map("n", "<leader>ghD", function()
          gs.diffthis "~"
        end, "Diff This ~")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")

        -- Toggle blame line
        map("n", "<leader>tb", function()
          gs.toggle_current_line_blame()
        end, "Toggle Blame Line")
      end,
    },
  },
  -- Search and replace
  {
    "MagicDuck/grug-far.nvim",
    opts = { headerMaxWidth = 80 },
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function()
          local grug = require "grug-far"
          local ext = vim.bo.buftype == "" and vim.fn.expand "%:e"
          grug.open {
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          }
        end,
        mode = { "n", "v" },
        desc = "Search and Replace",
      },
    },
  },
  -- Theme
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {
      dimInactive = true, -- dim inactive window `:h hl-NormalNC`
      -- Remove gutter background
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none",
            },
          },
        },
      },
      overrides = function(colors)
        local theme = colors.theme
        return {
          -- Transparent background
          NormalFloat = { bg = "none" },
          FloatBorder = { bg = "none" },
          FloatTitle = { bg = "none" },

          NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },
          LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
          MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },

          -- Credit to https://github.com/rebelot/kanagawa.nvim/pull/268
          -- SnacksDashboard
          SnacksDashboardHeader = { fg = theme.vcs.removed },
          SnacksDashboardFooter = { fg = theme.syn.comment },
          SnacksDashboardDesc = { fg = theme.syn.identifier },
          SnacksDashboardIcon = { fg = theme.ui.special },
          SnacksDashboardKey = { fg = theme.syn.special1 },
          SnacksDashboardSpecial = { fg = theme.syn.comment },
          SnacksDashboardDir = { fg = theme.syn.identifier },
          -- SnacksNotifier
          SnacksNotifierBorderError = { link = "DiagnosticError" },
          SnacksNotifierBorderWarn = { link = "DiagnosticWarn" },
          SnacksNotifierBorderInfo = { link = "DiagnosticInfo" },
          SnacksNotifierBorderDebug = { link = "Debug" },
          SnacksNotifierBorderTrace = { link = "Comment" },
          SnacksNotifierIconError = { link = "DiagnosticError" },
          SnacksNotifierIconWarn = { link = "DiagnosticWarn" },
          SnacksNotifierIconInfo = { link = "DiagnosticInfo" },
          SnacksNotifierIconDebug = { link = "Debug" },
          SnacksNotifierIconTrace = { link = "Comment" },
          SnacksNotifierTitleError = { link = "DiagnosticError" },
          SnacksNotifierTitleWarn = { link = "DiagnosticWarn" },
          SnacksNotifierTitleInfo = { link = "DiagnosticInfo" },
          SnacksNotifierTitleDebug = { link = "Debug" },
          SnacksNotifierTitleTrace = { link = "Comment" },
          SnacksNotifierError = { link = "DiagnosticError" },
          SnacksNotifierWarn = { link = "DiagnosticWarn" },
          SnacksNotifierInfo = { link = "DiagnosticInfo" },
          SnacksNotifierDebug = { link = "Debug" },
          SnacksNotifierTrace = { link = "Comment" },
          -- SnacksProfiler
          SnacksProfilerIconInfo = { bg = theme.ui.bg_search, fg = theme.syn.fun },
          SnacksProfilerBadgeInfo = { bg = theme.ui.bg_visual, fg = theme.syn.fun },
          SnacksScratchKey = { link = "SnacksProfilerIconInfo" },
          SnacksScratchDesc = { link = "SnacksProfilerBadgeInfo" },
          SnacksProfilerIconTrace = { bg = theme.syn.fun, fg = theme.ui.float.fg_border },
          SnacksProfilerBadgeTrace = { bg = theme.syn.fun, fg = theme.ui.float.fg_border },
          SnacksIndent = { fg = theme.ui.bg_p2, nocombine = true },
          SnacksIndentScope = { fg = theme.ui.pmenu.bg, nocombine = true },
          SnacksZenIcon = { fg = theme.syn.statement },
          SnacksInputIcon = { fg = theme.ui.pmenu.bg },
          SnacksInputBorder = { fg = theme.syn.identifier },
          SnacksInputTitle = { fg = theme.syn.identifier },
          -- SnacksPicker
          SnacksPickerInputBorder = { fg = theme.syn.constant },
          SnacksPickerInputTitle = { fg = theme.syn.constant },
          SnacksPickerBoxTitle = { fg = theme.syn.constant },
          SnacksPickerSelected = { fg = theme.syn.number },
          SnacksPickerToggle = { link = "SnacksProfilerBadgeInfo" },
          SnacksPickerPickWinCurrent = { fg = theme.ui.fg, bg = theme.syn.number, bold = true },
          SnacksPickerPickWin = { fg = theme.ui.fg, bg = theme.ui.bg_search, bold = true },
        }
      end,
    },
  },
}
