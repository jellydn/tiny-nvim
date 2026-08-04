-- neovim#39485 moved search_* FFI globals into Search; upstream PR #496 pending.
-- Preload our patch only while installed flash.hacks still lacks SearchState.
if vim.fn.has "nvim-0.13" == 1 then
  local function flash_hacks_path()
    local roots = {}
    local ok, lazy_config = pcall(require, "lazy.core.config")
    if ok and lazy_config.options and lazy_config.options.root then
      roots[#roots + 1] = lazy_config.options.root
    end
    roots[#roots + 1] = vim.fn.stdpath "data" .. "/lazy"
    for _, root in ipairs(roots) do
      local path = root .. "/flash.nvim/lua/flash/hacks.lua"
      if vim.uv.fs_stat(path) then
        return path
      end
    end
    return nil
  end

  local function upstream_has_search_state()
    local path = flash_hacks_path()
    if not path then
      return false
    end
    local ok, lines = pcall(vim.fn.readfile, path)
    if not ok or type(lines) ~= "table" then
      return false
    end
    for _, line in ipairs(lines) do
      if line:find("SearchState", 1, true) then
        return true
      end
    end
    return false
  end

  if not upstream_has_search_state() then
    package.preload["flash.hacks"] = function()
      return require "utils.flash_hacks"
    end
  end
end

-- Expand/shrink chords: utils.vscode_treesitter.setup_keymaps (keymaps.lua / vscode.lua).

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
