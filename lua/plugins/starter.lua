local logo = [[
      ██╗████████╗    ███╗   ███╗ █████╗ ███╗   ██╗
      ██║╚══██╔══╝    ████╗ ████║██╔══██╗████╗  ██║
      ██║   ██║       ██╔████╔██║███████║██╔██╗ ██║
      ██║   ██║       ██║╚██╔╝██║██╔══██║██║╚██╗██║
      ██║   ██║       ██║ ╚═╝ ██║██║  ██║██║ ╚████║
      ╚═╝   ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
]]

logo = string.rep("\n", 4) .. logo .. "\n"
local hostname = io.popen("hostname"):read("*a"):gsub("%s+", "")

local function action_find_files()
  require("mini.pick").builtin.files()
end

local function action_find_text()
  require("mini.pick").builtin.grep_live()
end

local function action_recent_files()
  require("mini.extra").pickers.oldfiles()
end

local function action_config_files()
  require("mini.pick").builtin.files(nil, { source = { cwd = vim.fn.stdpath "config" } })
end

local function starter_footer()
  local base = "Welcome back, " .. hostname .. "!"
  local ok, lazy = pcall(require, "lazy")
  if not ok then
    return base
  end

  local stats = lazy.stats()
  if not stats or not stats.count or not stats.startuptime then
    return base
  end

  local startup_ms = math.floor(stats.startuptime + 0.5)
  return string.format("%s  |  %d/%d plugins in %dms", base, stats.loaded or 0, stats.count, startup_ms)
end

local function restore_session()
  local ok, persistence = pcall(require, "persistence")
  if not ok then
    vim.notify("persistence.nvim is not available", vim.log.levels.WARN)
    return
  end

  persistence.load()
end

local function lazy_cmd(cmd)
  if not package.loaded.lazy then
    vim.notify("lazy.nvim is not available", vim.log.levels.WARN)
    return
  end

  vim.cmd(cmd)
end

return {
  {
    "echasnovski/mini.starter",
    opts = function()
      local starter = require "mini.starter"
      return {
        header = logo,
        footer = starter_footer,
        query_updaters = "",
        items = {
          {
            name = " [F]iles",
            action = action_find_files,
            section = "Search",
          },
          {
            name = " [G]rep",
            action = action_find_text,
            section = "Search",
          },
          {
            name = " [R]ecent Files",
            action = action_recent_files,
            section = "Search",
          },
          {
            name = " [C]onfig",
            action = action_config_files,
            section = "Search",
          },
          {
            name = " [S]ession",
            action = restore_session,
            section = "Session",
          },
          {
            name = "󰒲 [L]azy",
            action = function()
              lazy_cmd "Lazy"
            end,
            section = "Tools",
          },
          {
            name = "󰊳 [U]pdate",
            action = function()
              lazy_cmd "Lazy update"
            end,
            section = "Tools",
          },
          {
            name = " [Q]uit",
            action = "qa",
            section = "Builtins",
          },
        },
        content_hooks = {
          starter.gen_hook.adding_bullet(),
          starter.gen_hook.aligning("center", "center"),
          starter.gen_hook.padding(3, 2),
        },
      }
    end,
    config = function(_, opts)
      local starter = require "mini.starter"
      starter.setup(opts)

      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimStarted",
        callback = function()
          if starter.refresh then
            starter.refresh()
          end
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniStarterOpened",
        callback = function(args)
          local buf = args.buf or vim.api.nvim_get_current_buf()
          local map = function(lhs, rhs)
            vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true })
          end

          map("f", action_find_files)
          map("g", action_find_text)
          map("r", action_recent_files)
          map("c", action_config_files)
          map("s", restore_session)
          map("q", "<cmd>qa<cr>")
          map("l", function()
            lazy_cmd "Lazy"
          end)
          map("u", function()
            lazy_cmd "Lazy update"
          end)
        end,
      })
    end,
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
  },
}
