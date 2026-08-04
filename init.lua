require "config.options"

-- Load project setting if available, e.g: .nvim-config.lua
-- This file is not tracked by git
-- It can be used to set project specific settings
local project_setting = vim.fn.getcwd() .. "/.nvim-config.lua"
-- Check if the file exists and load it
if vim.uv.fs_stat(project_setting) then
  -- Read the file and run it with pcall to catch any errors
  local ok, err = pcall(dofile, project_setting)
  if not ok then
    vim.notify("Error loading project setting: " .. err, vim.log.levels.ERROR)
  end
end

require "config.autocmds"
require "config.lazy"
require "config.keymaps"
require "config.project"

-- Only load the theme if not in VSCode
if vim.g.vscode then
  -- Trigger vscode keymap
  local pattern = "NvimIdeKeymaps"
  vim.api.nvim_exec_autocmds("User", { pattern = pattern, modeline = false })
else
  -- Load the theme
  local theme = require "config.theme"
  theme.setup()
  theme.apply()

  -- TypeScript: vtsls by default (ts_ls is legacy — set vim.g.lsp_typescript_server = "ts_ls")
  local Lsp = require "utils.lsp"
  local ts_server = vim.g.lsp_typescript_server or "vtsls"

  -- Enable LSP servers per filetype (Neovim 0.11+)
  -- JS/TS lint is chosen per buffer from project markers (biome > oxlint > eslint).
  local lsp_by_ft = {
    lua = { "lua_ls" },
    json = { "json" },
    jsonc = { "json" },
    json5 = { "json" },
    -- Astral stack: ty (types) + ruff (lint/format)
    python = { "ty", "ruff" },
    go = { "gopls" },
    gomod = { "gopls" },
    gowork = { "gopls" },
    gotmpl = { "gopls" },
    rust = { "rust-analyzer" },
    javascript = { ts_server },
    javascriptreact = { ts_server },
    typescript = { ts_server },
    typescriptreact = { ts_server },
    html = { "tailwindcss" },
    css = { "tailwindcss" },
    scss = { "tailwindcss" },
    sass = { "tailwindcss" },
    less = { "tailwindcss" },
    postcss = { "tailwindcss" },
  }

  local enabled_lsp = {}
  local on_demands = vim.g.lsp_on_demands or {}
  local js_ts_filetypes = {
    javascript = true,
    javascriptreact = true,
    typescript = true,
    typescriptreact = true,
  }
  local json_filetypes = {
    json = true,
    jsonc = true,
    json5 = true,
  }

  local function enable_lsp(servers)
    if not servers or #servers == 0 then
      return
    end
    for _, server in ipairs(servers) do
      if not enabled_lsp[server] then
        enabled_lsp[server] = true
        vim.lsp.enable(server)
      end
    end
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("my_nvim_lsp_by_ft", { clear = true }),
    callback = function(event)
      local filetype = vim.bo[event.buf].filetype
      local servers = vim.list_extend({}, lsp_by_ft[filetype] or {})

      if js_ts_filetypes[filetype] or json_filetypes[filetype] then
        local linter = Lsp.detect_js_linter()
        if linter then
          table.insert(servers, linter)
        end
      end

      if (js_ts_filetypes[filetype] or json_filetypes[filetype]) and #on_demands > 0 then
        for _, server in ipairs(on_demands) do
          table.insert(servers, server)
        end
      end

      enable_lsp(servers)
    end,
  })
end
