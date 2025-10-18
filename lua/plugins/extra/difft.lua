local mapping_key_prefix = vim.g.git_prefix_key or "<leader>gd"

return {
  "ahkohd/difft.nvim",
  opts = {
    command = "GIT_EXTERNAL_DIFF='difft --color=always' git diff",
    layout = "ivy_taller", -- nil (buffer), "float", or "ivy_taller"
    no_diff_message = "All clean! No changes detected.",
    loading_message = "Loading diff...",
    window = {
      number = false,
      relativenumber = false,
      border = "rounded",
    },
    header = {
      content = function(filename, step)
        local mini_icons = require "mini.icons"
        local icon = mini_icons.get("file", filename)

        if step then
          return string.format("%s [%d/%d] %s", icon, step.current, step.of, filename)
        end
        return string.format("%s %s", icon, filename)
      end,
      highlight = {
        link = "FloatTitle",
        full_width = true,
      },
    },
  },
  keys = {
    {
      mapping_key_prefix,
      function()
        if Difft.is_visible() then
          Difft.hide()
        else
          Difft.diff()
        end
      end,
      desc = "Toggle Difft",
    },
  },
}
