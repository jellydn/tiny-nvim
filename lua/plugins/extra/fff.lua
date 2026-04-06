return {
  -- fff.nvim - Fast fuzzy file finder with memory built-in
  -- A fast file picker for Neovim with frecency scoring, git integration,
  -- and multiple grep modes (plain, regex, fuzzy)

  -- Register FFF group in which-key
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>F", group = "FFF", mode = { "n", "v" } },
      },
    },
  },

  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      -- Download prebuilt binary or build from source using rustup
      require("fff.download").download_or_build_binary()
    end,
    opts = {
      prompt = "🪿 ",
      title = "FFF",
      max_results = 100,
      max_threads = 4,
      lazy_sync = true, -- Start syncing only when picker is open
      layout = {
        height = 0.8,
        width = 0.8,
        prompt_position = "bottom",
        preview_position = "right",
        preview_size = 0.5,
        flex = {
          size = 130,
          wrap = "top",
        },
        show_scrollbar = true,
        path_shorten_strategy = "middle_number",
      },
      preview = {
        enabled = true,
        max_size = 10 * 1024 * 1024,
        chunk_size = 8192,
        binary_file_threshold = 1024,
        line_numbers = false,
        cursorlineopt = "both",
        wrap_lines = false,
        filetypes = {
          svg = { wrap_lines = true },
          markdown = { wrap_lines = true },
          text = { wrap_lines = true },
        },
      },
      frecency = {
        enabled = true,
      },
      history = {
        enabled = true,
        min_combo_count = 3,
        combo_boost_score_multiplier = 100,
      },
      git = {
        status_text_color = false,
      },
      debug = {
        enabled = false,
        show_scores = false,
      },
      logging = {
        enabled = true,
        log_level = "info",
      },
      grep = {
        max_file_size = 10 * 1024 * 1024,
        max_matches_per_file = 100,
        smart_case = true,
        time_budget_ms = 150,
        modes = { "plain", "regex", "fuzzy" },
      },
    },
    keys = {
      {
        "<leader>Ff",
        function()
          require("fff").find_files()
        end,
        desc = "FFF find files",
      },
      {
        "<leader>Fg",
        function()
          require("fff").live_grep()
        end,
        desc = "FFF live grep",
      },
      {
        "<leader>Fz",
        function()
          require("fff").live_grep {
            grep = {
              modes = { "fuzzy", "plain" },
            },
          }
        end,
        desc = "FFF fuzzy grep",
      },
      {
        "<leader>Fc",
        function()
          require("fff").live_grep { query = vim.fn.expand "<cword>" }
        end,
        desc = "FFF search current word",
      },
    },
  },
}
