-- neovim#39485 moved search_* FFI globals into Search; upstream PR #496 pending.
-- Preload before flash.nvim loads so jump mode does not dlsym-crash on 0.13+.
if vim.fn.has "nvim-0.13" == 1 then
  package.preload["flash.hacks"] = function()
    return require "utils.flash_hacks"
  end
end

return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    -- Re-enabled under vscode-neovim; 0.13 SearchState patch is preloaded above
    vscode = true,
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          -- vscode-neovim: letter labels via vscode.eval decorations (see utils.vscode_treesitter)
          if vim.g.vscode then
            require("utils.vscode_treesitter").select()
            return
          end
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesitter Search",
      },
      {
        "<c-s>",
        mode = { "c" },
        function()
          require("flash").toggle()
        end,
        desc = "Toggle Flash Search",
      },
    },
  },
}
