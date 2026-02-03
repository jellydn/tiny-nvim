return {
  {
    "CRAG666/betterTerm.nvim",
    opts = {
      position = "bot",
      size = 15,
      startInserted = true,
      show_tabs = true,
    },
    keys = {
      {
        "<leader>ft",
        function()
          require("betterTerm").open()
        end,
        desc = "Toggle Terminal",
      },
      {
        "<c-/>",
        function()
          require("betterTerm").open()
        end,
        desc = "Toggle Terminal",
      },
      {
        "<c-_>",
        function()
          require("betterTerm").open()
        end,
        desc = "which_key_ignore",
      },
    },
  },
}
