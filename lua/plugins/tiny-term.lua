return {
  {
    "jellydn/tiny-term.nvim",
    opts = {
      override_snacks = true, -- Automatically override Snacks.terminal
      win = {
        position = "bottom",
        split_size = 15,
      },
      start_insert = true,
    },
    keys = {
      {
        "<leader>ft",
        function()
          require("tiny-term").toggle()
        end,
        desc = "Toggle Terminal",
      },
      {
        "<c-/>",
        function()
          require("tiny-term").toggle()
        end,
        desc = "Toggle Terminal",
      },
      {
        "<c-_>",
        function()
          require("tiny-term").toggle(nil, { count = vim.v.count1 })
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>gg",
        function()
          require("tiny-term").toggle("lazygit", {
            win = { position = "float", height = 0.95, width = 0.95 },
          })
        end,
        desc = "Toggle lazygit",
      },
    },
  },
}
