local git_ignored = setmetatable({}, {
  __index = function(self, key)
    local proc = vim.system({ "git", "ls-files", "--ignored", "--exclude-standard", "--others", "--directory" }, {
      cwd = key,
      text = true,
    })
    local result = proc:wait()
    local ret = {}
    if result.code == 0 then
      for line in vim.gsplit(result.stdout, "\n", { plain = true, trimempty = true }) do
        -- Remove trailing slash
        line = line:gsub("/$", "")
        table.insert(ret, line)
      end
    end

    rawset(self, key, ret)
    return ret
  end,
})
local function max_height()
  local height = vim.fn.winheight(0)
  if height >= 40 then
    return 30
  elseif height >= 30 then
    return 20
  else
    return 10
  end
end

return {
  -- Disable Snack explorer and use oil.nvim instead
  {
    "folke/snacks.nvim",
    optional = true,
    opts = {
      explorer = {
        enabled = false,
      },
    },
  },
  {
    "stevearc/oil.nvim",
    opts = {
      -- Set to false if you still want to use netrw.
      default_file_explorer = true,
      -- Skip the confirmation popup for simple operations (:help oil.skip_confirm_for_simple_edits)
      skip_confirm_for_simple_edits = true,
      -- Set to false to disable all of the above keymaps
      use_default_keymaps = true,
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = false,
        -- This function defines what is considered a "hidden" file
        is_hidden_file = function(name, _)
          -- dotfiles are always considered hidden
          if vim.startswith(name, ".") then
            return true
          end
          local dir = require("oil").get_current_dir()
          -- if no local directory (e.g. for ssh connections), always show
          if not dir then
            return false
          end
          -- Check if file is gitignored
          return vim.list_contains(git_ignored[dir], name)
        end,
        -- is_hidden_file = function(name)
        --   local ignore_folders = { "node_modules", "dist", "build", "coverage", "__pycache__" }
        --   return vim.startswith(name, ".") or vim.tbl_contains(ignore_folders, name)
        -- end,
      },
      -- Configuration for the floating window in oil.open_float
      float = {
        padding = 2,
        max_width = 120,
        max_height = max_height(),
        border = "rounded",
        win_options = {
          winblend = 0,
        },
      },
      -- Custom Keymap
      keymaps = {
        ["<C-c>"] = false,
        ["<C-s>"] = {
          desc = "Save all changes",
          callback = function()
            require("oil").save({ confirm = false })
          end,
        },
        ["q"] = "actions.close",
        ["<C-y>"] = "actions.copy_entry_path",
      },
    },
    -- Use g? to see default key mappings
    keys = {
      {
        "<leader>e",
        function()
          require("oil").toggle_float()
        end,
        desc = "Open file explorer",
      },
    },
  },
}
