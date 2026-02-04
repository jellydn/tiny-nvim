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

local function apply_overrides()
  local function link(group, target)
    vim.api.nvim_set_hl(0, group, { link = target })
  end

  -- LazyGit floating windows (Snacks / lazygit float)
  link("LazyGitFloat", "NormalFloat")
  link("LazyGitBorder", "FloatBorder")
  link("LazyGitTitle", "FloatTitle")
  link("SnacksLazygit", "NormalFloat")
  link("SnacksLazygitBorder", "FloatBorder")
  link("SnacksLazygitTitle", "FloatTitle")

  -- Snacks picker highlights
  link("SnacksPickerInputBorder", "FloatBorder")
  link("SnacksPickerInputTitle", "FloatTitle")
  link("SnacksPickerBoxTitle", "FloatTitle")
  link("SnacksPickerSelected", "Visual")
  link("SnacksPickerToggle", "IncSearch")
  link("SnacksPickerPickWinCurrent", "Search")
  link("SnacksPickerPickWin", "Search")

  -- mini.pick fallback highlights
  link("MiniPickNormal", "NormalFloat")
  link("MiniPickBorder", "FloatBorder")
  link("MiniPickBorderBusy", "FloatBorder")
  link("MiniPickBorderText", "FloatTitle")
  link("MiniPickHeader", "Title")
  link("MiniPickMatchCurrent", "Visual")
  link("MiniPickMatchMarked", "IncSearch")
  link("MiniPickMatchRanges", "Search")
  link("MiniPickPrompt", "Title")
  link("MiniPickPromptCaret", "Cursor")
  link("MiniPickPromptPrefix", "Title")
  link("MiniPickPromptSymbol", "Type")
  link("MiniPickIconDirectory", "Directory")
  link("MiniPickIconFile", "NormalFloat")
  link("MiniPickPreviewLine", "CursorLine")
  link("MiniPickPreviewRegion", "Visual")
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
  apply_overrides()
end

function M.setup()
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = apply_overrides,
  })

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
