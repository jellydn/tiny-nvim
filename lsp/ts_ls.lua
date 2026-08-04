local Lsp = require "utils.lsp"
-- LEGACY: prefer vtsls (default). Enable with vim.g.lsp_typescript_server = "ts_ls"
-- NOTE: npm install -g typescript@5 typescript-language-server
-- TypeScript 7+ dropped classic lib/tsserver.js; pin TS 5.x for ts_ls.
local tsserver = Lsp.tsserver_js_path()
local init_options = { hostInfo = "neovim" }
if tsserver then
  init_options.tsserver = { path = tsserver }
end
return {
  init_options = init_options,
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
  settings = {
    typescript = {
      -- Inlay Hints preferences
      inlayHints = {
        -- You can set this to 'all' or 'literals' to enable more hints
        includeInlayParameterNameHints = "literals", -- 'none' | 'literals' | 'all'
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = false,
        includeInlayVariableTypeHints = false,
        includeInlayVariableTypeHintsWhenTypeMatchesName = false,
        includeInlayPropertyDeclarationTypeHints = false,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
      -- Code Lens preferences
      implementationsCodeLens = {
        enabled = true,
      },
      referencesCodeLens = {
        enabled = true,
        showOnAllFunctions = true,
      },
      format = {
        indentSize = vim.o.shiftwidth,
        convertTabsToSpaces = vim.o.expandtab,
        tabSize = vim.o.tabstop,
      },
    },
    javascript = {
      -- Inlay Hints preferences
      inlayHints = {
        -- You can set this to 'all' or 'literals' to enable more hints
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all'
        includeInlayVariableTypeHints = true,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHintsWhenTypeMatchesName = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
      -- Code Lens preferences
      implementationsCodeLens = {
        enabled = true,
      },
      referencesCodeLens = {
        enabled = true,
        showOnAllFunctions = true,
      },
      format = {
        indentSize = vim.o.shiftwidth,
        convertTabsToSpaces = vim.o.expandtab,
        tabSize = vim.o.tabstop,
      },
    },
    completions = {
      completeFunctionCalls = true,
    },
  },
}
