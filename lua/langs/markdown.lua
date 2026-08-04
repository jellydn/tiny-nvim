return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>m", group = "markdown", icon = "" },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = { ensure_installed = { "markdown", "markdown_inline" } },
  },
  -- Markdown preview
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
  {
    "previm/previm",
    config = function()
      -- define global for open markdown preview (cross-platform)
      -- macOS: use Brave app binary path
      -- Windows: use `start` to open default browser
      -- Linux/other: prefer xdg-open, fallback to available browser binary
      local ok, uname = pcall(vim.uv.os_uname)
      local sysname = ""
      if ok and uname and uname.sysname then
        sysname = uname.sysname
      end

      if vim.fn.has "mac" == 1 or sysname == "Darwin" then
        vim.g.previm_open_cmd = "/Applications/Brave\\ Browser.app/Contents/MacOS/Brave\\ Browser"
      elseif vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 or sysname:match "^Windows" then
        -- Using `start` via cmd opens the default browser on Windows
        vim.g.previm_open_cmd = "start"
      else
        -- Prefer the first available open command on Linux/Unix
        local open_cmd = "xdg-open"
        for _, cand in ipairs { "xdg-open", "brave-browser", "google-chrome", "firefox", "sensible-browser" } do
          if vim.fn.executable(cand) == 1 then
            open_cmd = cand
            break
          end
        end
        vim.g.previm_open_cmd = open_cmd
      end
    end,
    ft = { "markdown" },
    keys = {
      {
        "<leader>m",
        "<cmd>PrevimOpen<cr>",
        desc = "Markdown preview on browser",
      },
    },
  },
}
