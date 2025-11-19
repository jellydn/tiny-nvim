return {
  -- Task runner
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>o", group = "overseer/task", icon = "" },
      },
    },
  },
  {
    "stevearc/overseer.nvim",
    version = "v1.6.0",
    dependencies = {
      -- Uncomment to use toggleterm as the strategy
      -- "akinsho/toggleterm.nvim",
    },
    opts = {
      dap = false,
      -- strategy = "toggleterm",
      -- Configuration for task floating windows
      task_win = {
        -- How much space to leave around the floating window
        padding = 2,
        border = "single", -- or double
        -- Set any window options here (e.g. winhighlight)
        win_opts = {
          winblend = 2,
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
        },
      },
    },
    keys = {
      {
        "<leader>ot",
        "<CMD>OverseerRun<CR>",
        desc = "Run Task",
      },
      -- Quick action
      {
        "<leader>oq",
        "<CMD>OverseerQuickAction<CR>",
        desc = "Quick Action",
      },
      -- Rerun last command
      {
        "<leader>or",
        function()
          local overseer = require "overseer"
          local tasks = overseer.list_tasks { recent_first = true }
          if vim.tbl_isempty(tasks) then
            vim.notify("No tasks found", vim.log.levels.WARN)
          else
            overseer.run_action(tasks[1], "restart")
          end
        end,
        desc = "Rerun Last Task",
      },
      -- Toggle
      {
        "<leader>oo",
        "<CMD>OverseerToggle bottom<CR>",
        desc = "Toggle at bottom",
      },
    },
  },
  -- Code runner
  {
    "jellydn/quick-code-runner.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      debug = false,
      position = "50%",
      size = {
        width = "60%",
        height = "60%",
      },
    },
    cmd = { "QuickCodeRunner", "QuickCodePad" },
    keys = {
      {
        "<leader>cp",
        ":QuickCodeRunner<CR>",
        desc = "Quick Code Runner",
        mode = { "v" },
      },
      {
        "<leader>cp",
        ":QuickCodePad<CR>",
        desc = "Quick Code Pad",
      },
    },
  },
  -- Hurl runner
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>h", group = "hurl", icon = "" },
      },
    },
  },
  {
    "jellydn/hurl.nvim",
    ft = "hurl",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-treesitter/nvim-treesitter" },
    opts = {
      mode = "split",
      auto_close = false,
      debug = false,
      show_notification = false,
      formatters = {
        json = { "jq" },
        html = {
          "prettier",
          "--parser",
          "html",
        },
      },
      fixture_vars = {
        {
          name = "random_int_number",
          callback = function()
            return math.random(1, 1000)
          end,
        },
        {
          name = "random_float_number",
          callback = function()
            local result = math.random() * 10
            return string.format("%.2f", result)
          end,
        },
        {
          name = "now",
          callback = function()
            return os.date "%d/%m/%Y"
          end,
        },
      },
    },
    keys = {
      -- Run API request
      { "<leader>hA", "<cmd>HurlRunner<CR>", desc = "Run All requests" },
      { "<leader>ha", "<cmd>HurlRunnerAt<CR>", desc = "Run Api request" },
      { "<leader>he", "<cmd>HurlRunnerToEntry<CR>", desc = "Run Api request to entry" },
      { "<leader>hE", "<cmd>HurlRunnerToEnd<CR>", desc = "Run Api request from current entry to end" },
      { "<leader>hv", "<cmd>HurlVerbose<CR>", desc = "Run Api in verbose mode" },
      { "<leader>hV", "<cmd>HurlVeryVerbose<CR>", desc = "Run Api in very verbose mode" },
      { "<leader>hr", "<cmd>HurlRerun<CR>", desc = "Rerun last command" },
      -- Run Hurl request in visual mode
      { "<leader>hh", ":HurlRunner<CR>", desc = "Hurl Runner", mode = "v" },
      -- Show last response
      { "<leader>hh", "<cmd>HurlShowLastResponse<CR>", desc = "History", mode = "n" },
      -- Manage variable
      { "<leader>hg", ":HurlSetVariable", desc = "Add global variable" },
      { "<leader>hG", "<cmd>HurlManageVariable<CR>", desc = "Manage global variable" },
      -- Toggle
      { "<leader>tH", "<cmd>HurlToggleMode<CR>", desc = "Toggle Hurl Split/Popup" },
      -- Debug
      { "<leader>hd", "<cmd>HurlDebugInfo<CR>", desc = "Debug Info" },
    },
  },
}
