-- neovim#39485 moved search_* FFI globals into Search; upstream PR #496 pending.
-- Preload before flash.nvim loads so jump mode does not dlsym-crash on 0.13+.
if vim.fn.has "nvim-0.13" == 1 then
  package.preload["flash.hacks"] = function()
    return require "utils.flash_hacks"
  end
end

-- Incremental selection without flash letter marks (LazyVim uses flash labels; we expand only).
-- Primary chord is g<Space> — Ctrl+Space is often stolen by macOS Input Sources / Cursor Suggest.
local function treesitter_incremental_selection()
  require("utils.vscode_treesitter").expand()
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
        "g<Space>",
        mode = { "n", "o", "x" },
        treesitter_incremental_selection,
        desc = "Treesitter Expand Selection",
      },
      {
        "<c-space>",
        mode = { "n", "o", "x" },
        treesitter_incremental_selection,
        desc = "Treesitter Expand Selection",
      },
      {
        "<c-@>",
        mode = { "n", "o", "x" },
        treesitter_incremental_selection,
        desc = "Treesitter Expand Selection",
      },
      {
        "<Nul>",
        mode = { "n", "o", "x" },
        treesitter_incremental_selection,
        desc = "Treesitter Expand Selection",
      },
      {
        "<M-Space>",
        mode = { "n", "o", "x" },
        treesitter_incremental_selection,
        desc = "Treesitter Expand Selection",
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
