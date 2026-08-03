-- neovim#39485 moved search_* FFI globals into Search; upstream PR #496 pending.
-- Preload before flash.nvim loads so jump mode does not dlsym-crash on 0.13+.
if vim.fn.has "nvim-0.13" == 1 then
  package.preload["flash.hacks"] = function()
    return require "utils.flash_hacks"
  end
end

-- LazyVim-style incremental selection (nvim-treesitter main dropped incremental_selection).
-- Primary chord is g<Space> — Ctrl+Space is often stolen by macOS Input Sources / Cursor Suggest.
local TS_INC_ACTIONS = {
  ["g<Space>"] = "next",
  ["<c-space>"] = "next",
  ["<C-@>"] = "next",
  ["<Nul>"] = "next",
  ["<M-Space>"] = "next",
  ["<BS>"] = "prev",
}

local function treesitter_incremental_selection()
  -- vscode-neovim: flash UI overlays do not render; expand via utils.vscode_treesitter
  if vim.g.vscode then
    require("utils.vscode_treesitter").expand()
    return
  end
  require("flash").treesitter { actions = TS_INC_ACTIONS }
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
        desc = "Treesitter Incremental Selection",
      },
      {
        "<c-space>",
        mode = { "n", "o", "x" },
        treesitter_incremental_selection,
        desc = "Treesitter Incremental Selection",
      },
      {
        "<c-@>",
        mode = { "n", "o", "x" },
        treesitter_incremental_selection,
        desc = "Treesitter Incremental Selection",
      },
      {
        "<Nul>",
        mode = { "n", "o", "x" },
        treesitter_incremental_selection,
        desc = "Treesitter Incremental Selection",
      },
      {
        "<M-Space>",
        mode = { "n", "o", "x" },
        treesitter_incremental_selection,
        desc = "Treesitter Incremental Selection",
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
