require "config.options"

-- Load project setting if available, e.g: .nvim-config.lua
-- This file is not tracked by git
-- It can be used to set project specific settings
local project_setting = vim.fn.getcwd() .. "/.nvim-config.lua"
-- Check if the file exists and load it
if vim.loop.fs_stat(project_setting) then
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
    require("kanagawa").load "wave"

    local ts_server = vim.g.lsp_typescript_server or "ts_ls" -- "ts_ls" or "vtsls" for TypeScript

    -- Enable LSP servers for Neovim 0.11+
    vim.lsp.enable {
        ts_server,
        "lua_ls",      -- Lua
        "biome",       -- Biome = Eslint + Prettier
        "json",        -- JSON
        "pyright",     -- Python
        "gopls",       -- Go
        "tailwindcss", -- Tailwind CSS
    }

    -- Load Lsp on-demand, e.g: eslint is disable by default
    -- e.g: We could enable eslint by set vim.g.lsp_on_demands = {"eslint"}
    if vim.g.lsp_on_demands then
        vim.lsp.enable(vim.g.lsp_on_demands)
    end
end
