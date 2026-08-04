local Path = require "utils.path"

local M = {}

-- Get default LSP keymaps without any plugin dependencies
function M.get_default_keymaps()
  return {
    { keys = "<leader>ca", func = vim.lsp.buf.code_action, desc = "Code Actions" },
    { keys = "<leader>.", func = vim.lsp.buf.code_action, desc = "Code Actions" },
    { keys = "<leader>cA", func = M.action.source, desc = "Source Actions" },
    { keys = "<leader>cr", func = vim.lsp.buf.rename, desc = "Code Rename" },
    { keys = "<leader>cf", func = vim.lsp.buf.format, desc = "Code Format" },
    { keys = "<leader>k", func = vim.lsp.buf.hover, desc = "Documentation", has = "hoverProvider" },
    { keys = "K", func = vim.lsp.buf.hover, desc = "Documentation", has = "hoverProvider" },
    { keys = "gd", func = vim.lsp.buf.definition, desc = "Goto Definition", has = "definitionProvider" },
    -- NOTE: Use snack UI for below keymaps
    -- { keys = "gD", func = vim.lsp.buf.declaration, desc = "Goto Declaration", has = "declarationProvider" },
    -- { keys = "gr", func = vim.lsp.buf.references, desc = "Goto References", has = "referencesProvider", nowait = true },
    -- { keys = "gi", func = vim.lsp.buf.implementation, desc = "Goto Implementation", has = "implementationProvider" },
    -- { keys = "gy", func = vim.lsp.buf.type_definition, desc = "Goto Type Definition", has = "typeDefinitionProvider" },
  }
end

-- Applied from LspAttach (all servers) and optional per-config on_attach.
-- Idempotent per buffer so dual wiring does not stack maps.
M.on_attach = function(client, buffer)
  local ok_var, attached = pcall(vim.api.nvim_buf_get_var, buffer, "_tiny_nvim_lsp_keymaps")
  if ok_var and attached then
    return
  end
  pcall(vim.api.nvim_buf_set_var, buffer, "_tiny_nvim_lsp_keymaps", true)

  local keymaps = M.get_default_keymaps()
  for _, keymap in ipairs(keymaps) do
    if not keymap.has or client.server_capabilities[keymap.has] then
      vim.keymap.set(keymap.mode or "n", keymap.keys, keymap.func, {
        buffer = buffer,
        desc = "LSP: " .. keymap.desc,
        nowait = keymap.nowait,
      })
    end
  end
end

M.action = setmetatable({}, {
  __index = function(_, action)
    return function()
      vim.lsp.buf.code_action {
        apply = true,
        context = {
          only = { action },
          diagnostics = {},
        },
      }
    end
  end,
})

-- Utils for conform
--- Get the path of the config file in the current directory or the root of the git repo
---@param filename string
---@return string | nil
local function get_config_path(filename)
  local current_dir = vim.fn.getcwd()
  local config_file = current_dir .. "/" .. filename
  if vim.fn.filereadable(config_file) == 1 then
    return current_dir
  end

  -- If the current directory is a git repo, check if the root of the repo
  -- contains a biome.json file
  local git_root = Path.get_git_root()
  if Path.is_git_repo() and git_root ~= current_dir then
    config_file = git_root .. "/" .. filename
    if vim.fn.filereadable(config_file) == 1 then
      return git_root
    end
  end

  return nil
end

M.biome_config_path = function()
  return get_config_path "biome.json"
end

M.biome_config_exists = function()
  local has_config = get_config_path "biome.json"
  return has_config ~= nil
end

M.dprint_config_path = function()
  return get_config_path "dprint.json"
end

M.dprint_config_exist = function()
  local has_config = get_config_path "dprint.json"
  return has_config ~= nil
end

M.deno_config_exist = function()
  local has_config = get_config_path "deno.json" or get_config_path "deno.jsonc"
  return has_config ~= nil
end

M.spectral_config_path = function()
  return get_config_path ".spectral.yaml"
end

return M
