local logo = [[
      ██╗████████╗    ███╗   ███╗ █████╗ ███╗   ██╗
      ██║╚══██╔══╝    ████╗ ████║██╔══██╗████╗  ██║
      ██║   ██║       ██╔████╔██║███████║██╔██╗ ██║
      ██║   ██║       ██║╚██╔╝██║██╔══██║██║╚██╗██║
      ██║   ██║       ██║ ╚═╝ ██║██║  ██║██║ ╚████║
      ╚═╝   ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
]]

logo = string.rep("\n", 4) .. logo .. "\n"

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
        items = {
          {
            name = "Find File",
            action = function()
              require("mini.pick").builtin.files()
            end,
            section = "Search",
          },
          {
            name = "Find Text",
            action = function()
              require("mini.pick").builtin.grep_live()
            end,
            section = "Search",
          },
          {
            name = "Recent Files",
            action = function()
              require("mini.extra").pickers.oldfiles()
            end,
            section = "Search",
          },
          {
            name = "Config",
            action = function()
              require("mini.pick").builtin.files(nil, { source = { cwd = vim.fn.stdpath "config" } })
            end,
            section = "Search",
          },
          {
            name = "Restore Session",
            action = restore_session,
            section = "Session",
          },
          {
            name = "Lazy",
            action = function()
              lazy_cmd "Lazy"
            end,
            section = "Tools",
          },
          {
            name = "Update",
            action = function()
              lazy_cmd "Lazy update"
            end,
            section = "Tools",
          },
          {
            name = "Quit",
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
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
  },
}
