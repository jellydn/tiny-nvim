local completion = vim.g.completion_mode or "blink" -- or 'native'

return {
  -- nvim-cmp compatibility layer for blink.cmp (required by 99 plugin for blink support)
  {
    "saghen/blink.compat",
    -- use v2.* for blink.cmp v1.*
    version = "2.*",
    opts = {},
  },
  -- Autocomplete, refer to https://cmp.saghen.dev/#compared-to-built-in-completion for more information
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    enable = completion == "blink",
    -- use a release tag to download pre-built binaries
    version = "1.*",
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',
    dependencies = {
      -- optional: provides snippets for the snippet source
      "L3MON4D3/LuaSnip",
      version = "v2.*",
      build = (function()
        -- Build Step is needed for regex support in snippets.
        -- This step is not supported in many windows environments.
        -- Remove the below condition to re-enable on windows.
        if vim.fn.has "win32" == 1 or vim.fn.executable "make" == 0 then
          return
        end
        return "make install_jsregexp"
      end)(),
      dependencies = {
        -- `friendly-snippets` contains a variety of premade snippets.
        {
          "rafamadriz/friendly-snippets",
          config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
            require("luasnip.loaders.from_vscode").lazy_load { paths = { vim.fn.stdpath "config" .. "/snippets" } }
          end,
        },
      },
    },
    ---@module 'blink.cmp'
    -- Refer https://cmp.saghen.dev/installation.html
    opts = {
      -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
      -- 'super-tab' for mappings similar to vscode (tab to accept)
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- All presets have the following mappings:
      -- C-space: Open menu or open docs if already open
      -- C-n/C-p or Up/Down: Select next/previous item
      -- C-e: Hide menu
      -- C-k: Toggle signature help (if signature.enabled = true)
      --
      -- See :h blink-cmp-config-keymap for defining your own keymap
      keymap = { preset = "enter" },
      completion = {
        -- Controls whether the documentation window will automatically show when selecting a completion item
        documentation = {
          auto_show = true,
        },
      },
      -- Experimental signature help support
      signature = {
        enabled = false,
      },
      appearance = {
        -- Sets the fallback highlight groups to nvim-cmp's highlight groups
        -- Useful for when your theme doesn't support blink.cmp
        -- Will be removed in a future release
        use_nvim_cmp_as_default = true,
        -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        nerd_font_variant = "mono",
      },
      snippets = { preset = "luasnip" },
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "cmp" },
        providers = {
          cmp = {
            name = "cmp",
            module = "blink.compat.source",
          },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      -- Disable cmdline completions
      cmdline = {
        enabled = false,
      },
      -- Disable per file type
      enabled = function()
        return not vim.tbl_contains({ "copilot-chat" }, vim.bo.filetype)
          and not vim.tbl_contains({ "codecompanion" }, vim.bo.filetype)
          and vim.bo.buftype ~= "prompt"
          and vim.b.completion ~= false
      end,
    },
    -- without having to redefine it
    opts_extend = {
      "sources.completion.enabled_providers",
      "sources.compat", -- Support nvim-cmp source
      "sources.default",
    },
  },
  -- Lazydev
  {
    "folke/lazydev.nvim",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "lazy.nvim", words = { "LazyVim" } },
      },
    },
    optional = true,
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        -- add lazydev to your completion providers
        default = { "lazydev" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100, -- show at a higher priority than lsp
          },
        },
      },
    },
  },
  -- Markdown
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
    opts = {},
    optional = true,
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        default = { "markdown" },
        providers = {
          markdown = {
            name = "RenderMarkdown",
            module = "render-markdown.integ.blink",
            fallbacks = { "lsp" },
          },
        },
      },
    },
  },
  -- Refactoring
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>d", group = "debug" },
        { "<leader>r", group = "refactoring", icon = "" },
      },
    },
  },
  -- The Refactoring library based off the Refactoring book by Martin Fowler
  -- v2.0+: uses operator-pending mode (functions return textobject strings)
  {
    "ThePrimeagen/refactoring.nvim",
    vscode = true,
    dependencies = {
      { "lewis6991/async.nvim" },
      { "nvim-lua/plenary.nvim", vscode = true },
      { "nvim-treesitter/nvim-treesitter" },
    },
    keys = {
      {
        "<leader>rm",
        function()
          require("refactoring").select_refactor()
        end,
        mode = { "n", "v" },
        desc = "Refactoring Menu",
      },
      {
        "<leader>re",
        function()
          return require("refactoring").extract_func()
        end,
        desc = "Extract Function",
        mode = { "n", "x" },
        expr = true,
      },
      {
        "<leader>rf",
        function()
          return require("refactoring").extract_func_to_file()
        end,
        desc = "Extract to file",
        mode = { "n", "x" },
        expr = true,
      },
      {
        "<leader>rv",
        function()
          return require("refactoring").extract_var()
        end,
        desc = "Extract variable",
        mode = { "n", "x" },
        expr = true,
      },
      {
        "<leader>ri",
        function()
          return require("refactoring").inline_var()
        end,
        desc = "Inline variable",
        mode = { "n", "x" },
        expr = true,
      },
      {
        "<leader>rI",
        function()
          return require("refactoring").inline_func()
        end,
        desc = "Inline function",
        mode = { "n", "x" },
        expr = true,
      },
      -- Debug variable
      {
        "<leader>dv",
        function()
          local cmd = require("refactoring.debug").print_var { output_location = "below" }
          if vim.fn.mode() == "n" then
            return cmd .. "iw"
          end
          return cmd
        end,
        mode = { "n", "x" },
        desc = "Print below variables",
        expr = true,
      },
      {
        "<leader>dV",
        function()
          local cmd = require("refactoring.debug").print_var { output_location = "above" }
          if vim.fn.mode() == "n" then
            return cmd .. "iw"
          end
          return cmd
        end,
        mode = { "n", "x" },
        desc = "Print above variables",
        expr = true,
      },
      -- Clean up debugging
      {
        "<leader>dc",
        function()
          local cmd = require("refactoring.debug").cleanup { restore_view = true }
          if vim.fn.mode() == "n" then
            return cmd .. "ag"
          end
          return cmd
        end,
        mode = { "n", "x" },
        desc = "Clear debugging",
        expr = true,
      },
    },
    opts = {},
  },
  -- Code comment
  {
    "folke/ts-comments.nvim",
    opts = {},
    event = "VeryLazy",
  },
  -- Learn those tips from LazyVim
  -- Auto pairs
  {
    "echasnovski/mini.pairs",
    event = "VeryLazy",
    opts = {},
  },
  -- Extend and create a/i textobjects
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    opts = function()
      local ai = require "mini.ai"
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter { -- code block
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          },
          f = ai.gen_spec.treesitter { a = "@function.outer", i = "@function.inner" }, -- function
          c = ai.gen_spec.treesitter { a = "@class.outer", i = "@class.inner" }, -- class
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
          d = { "%f[%d]%d+" }, -- digits
          e = { -- Word with case
            { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
            "^().*()$",
          },
          u = ai.gen_spec.function_call(), -- u for "Usage"
          U = ai.gen_spec.function_call { name_pattern = "[%w_]" }, -- without dot in function name
          g = require("mini.extra").gen_ai_spec.buffer(), -- g for "Global/buffer" (used with `ag` textobject)
        },
      }
    end,
  },
  -- A better annotation generator. Supports multiple languages and annotation conventions.
  -- <C-n> to jump to next annotation, <C-p> to jump to previous annotation
  {
    "danymat/neogen",
    dependencies = "nvim-treesitter/nvim-treesitter",
    opts = { enabled = true },
    cmd = "Neogen",
    vscode = true,
    keys = {
      { "<leader>ci", "<cmd>Neogen<cr>", desc = "Neogen: Annotation generator" },
    },
  },
}
