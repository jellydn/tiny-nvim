local M = {}

local theme_names = { "kanagawa" }

M.themes = {
  kanagawa = function()
    vim.o.background = "dark"
    require("kanagawa").load "wave"
  end,
}

local function list_themes()
  return table.concat(theme_names, ", ")
end

function M.apply(name)
  local theme = name or vim.g.theme or "kanagawa"
  local apply = M.themes[theme]
  if not apply then
    vim.notify(("Unknown theme '%s'. Available: %s"):format(theme, list_themes()), vim.log.levels.WARN)
    return
  end

  vim.g.theme = theme
  apply()
end

function M.setup()
  vim.api.nvim_create_user_command("Theme", function(opts)
    if opts.args == "" then
      local current = vim.g.theme or "kanagawa"
      vim.notify(("Current theme: %s. Available: %s"):format(current, list_themes()))
      return
    end

    M.apply(opts.args)
  end, {
    nargs = "?",
    complete = function()
      return theme_names
    end,
  })
end

return M
