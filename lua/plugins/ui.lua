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

local function get_listed_buffers()
  local buffers = vim.fn.getbufinfo { buflisted = 1 }
  table.sort(buffers, function(a, b)
    return a.bufnr < b.bufnr
  end)
  return buffers
end

local function close_buffers(predicate)
  for _, buf in ipairs(get_listed_buffers()) do
    if predicate(buf.bufnr) then
      pcall(vim.api.nvim_buf_delete, buf.bufnr, {})
    end
  end
end

local function close_buffers_left()
  local current = vim.api.nvim_get_current_buf()
  close_buffers(function(bufnr)
    return bufnr < current
  end)
end

local function close_buffers_right()
  local current = vim.api.nvim_get_current_buf()
  close_buffers(function(bufnr)
    return bufnr > current
  end)
end

local function close_other_buffers()
  local current = vim.api.nvim_get_current_buf()
  close_buffers(function(bufnr)
    return bufnr ~= current
  end)
end

local function mini_diff_goto(direction)
  require("mini.diff").goto_hunk(direction)
end

local function mini_diff_apply_current()
  vim.cmd "normal ghgh"
end

local function mini_diff_reset_current()
  vim.cmd "normal gHgh"
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
    "echasnovski/mini.tabline",
    event = "VeryLazy",
    keys = {
      { "<leader>bo", close_other_buffers, desc = "Delete Other Buffers" },
      { "<leader>br", close_buffers_right, desc = "Delete Buffers to the Right" },
      { "<leader>bl", close_buffers_left, desc = "Delete Buffers to the Left" },
      { "<S-h>", "<cmd>bprevious<cr>", desc = "Prev Buffer" },
      { "<S-l>", "<cmd>bnext<cr>", desc = "Next Buffer" },
      { "[b", "<cmd>bprevious<cr>", desc = "Prev Buffer" },
      { "]b", "<cmd>bnext<cr>", desc = "Next Buffer" },
    },
    opts = {},
  },
  {
    "echasnovski/mini.bufremove",
    opts = {},
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
    lazy = false,
    build = ":TSUpdate",
    branch = "main",
    keys = {
      { "<c-space>", desc = "Increment Selection" },
      { "<bs>", desc = "Decrement Selection", mode = "x" },
    },
    opts_extend = { "ensure_installed" },
    config = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        opts.ensure_installed = deduplicate(opts.ensure_installed)
      end
      require("nvim-treesitter.config").setup(opts)
      local filetypes = opts.ensure_installed
      require("nvim-treesitter").install(filetypes)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = filetypes,
        callback = function()
          vim.treesitter.start()
        end,
      })
    end,
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
      ensure_installed = {
        "bash",
        "c",
        "css",
        "diff",
        "go",
        "gomod",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "latex",
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
        "scss",
        "svelte",
        "toml",
        "tsx",
        "typescript",
        "typst",
        "vim",
        "vimdoc",
        "vue",
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
    "echasnovski/mini.diff",
    event = "VeryLazy",
    keys = {
      {
        "]h",
        function()
          mini_diff_goto "next"
        end,
        desc = "Next Hunk",
      },
      {
        "[h",
        function()
          mini_diff_goto "prev"
        end,
        desc = "Prev Hunk",
      },
      {
        "]H",
        function()
          mini_diff_goto "last"
        end,
        desc = "Last Hunk",
      },
      {
        "[H",
        function()
          mini_diff_goto "first"
        end,
        desc = "First Hunk",
      },
      { "<leader>ghs", mini_diff_apply_current, desc = "Stage Hunk" },
      { "<leader>ghr", mini_diff_reset_current, desc = "Reset Hunk" },
    },
    opts = {
      view = {
        style = "sign",
        signs = { add = "▎", change = "▎", delete = "" },
      },
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
}
