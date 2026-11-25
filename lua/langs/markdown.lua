-- Command that previm appends the preview file path to.
-- Set `vim.g.previm_browser` (e.g. in .nvim-config.lua) to pick a specific browser.
local function previm_open_cmd()
  local browser = vim.g.previm_browser
  local sysname = vim.uv.os_uname().sysname or ""

  if type(browser) == "string" and browser ~= "" then
    if vim.fn.has "mac" == 1 or sysname == "Darwin" then
      return ('open -a "%s"'):format(browser)
    end
    return browser
  end

  if vim.fn.has "mac" == 1 or sysname == "Darwin" then
    -- `open` uses the default browser and reuses a running instance.
    -- Launching the browser binary directly can drop the file URL.
    return "open"
  end

  if vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 or sysname:match "^Windows" then
    -- The empty "" is the window title; without it `start` swallows the path.
    return 'cmd /c start ""'
  end

  for _, cand in ipairs { "xdg-open", "brave-browser", "google-chrome", "firefox", "sensible-browser" } do
    if vim.fn.executable(cand) == 1 then
      return cand
    end
  end
  return "xdg-open"
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = { ensure_installed = { "markdown", "markdown_inline" } },
  },
  -- Markdown preview in the browser
  {
    "previm/previm",
    config = function()
      vim.g.previm_open_cmd = previm_open_cmd()
    end,
    ft = { "markdown" },
    keys = {
      {
        "<leader>m",
        "<cmd>PrevimOpen<cr>",
        desc = "Markdown preview in browser",
      },
    },
  },
  -- Markdown preview inside Neovim
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      latex = { enabled = false },
    },
    ft = { "markdown" },
    keys = {
      {
        "<leader>tm",
        "<cmd>RenderMarkdown toggle<cr>",
        desc = "Toggle Markdown preview",
      },
    },
  },
}
