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

-- Applied from global LspAttach. Idempotent per buffer if also called from a
-- per-config on_attach (legacy dual wiring).
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

-- Utils for conform / smart JS linter detect

local biome_markers = { "biome.json", "biome.jsonc" }
local oxlint_markers = {
  "oxlintrc.json",
  "oxlintrc.jsonc",
  ".oxlintrc.json",
  ".oxlintrc.jsonc",
  "oxlint.config.ts",
  "oxlint.config.js",
  "oxlint.config.mjs",
  "oxlint.config.cjs",
}
local eslint_markers = {
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
  "eslint.config.ts",
  "eslint.config.mts",
  "eslint.config.cts",
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.yaml",
  ".eslintrc.yml",
  ".eslintrc.json",
}

-- Shared with lsp/*.lua root_markers so detect and attach stay in sync.
M.biome_root_markers = biome_markers
M.oxlint_root_markers = oxlint_markers
M.eslint_root_markers = eslint_markers

---@param dir string
---@param names string[]
---@return boolean
local function dir_has_marker(dir, names)
  for _, name in ipairs(names) do
    if vim.uv.fs_stat(dir .. "/" .. name) then
      return true
    end
  end
  return false
end

--- Start dir + stop dir for upward project-marker walks (buffer-scoped).
---@param bufnr? integer
---@return string, string
local function marker_walk_bounds(bufnr)
  bufnr = bufnr or 0
  local start = vim.fn.getcwd()
  local ok_buf = vim.api.nvim_buf_is_valid(bufnr)
  local name = ok_buf and vim.api.nvim_buf_get_name(bufnr) or ""
  if name ~= "" and vim.bo[bufnr].buftype == "" then
    start = vim.fs.dirname(vim.fs.abspath(name))
  end
  local stop = Path.get_git_root(start)
  if type(stop) ~= "string" or stop == "" then
    stop = vim.uv.os_homedir() or start
  end
  return start, stop
end

--- Find a config file upward from the buffer (or cwd), stopping at git root / $HOME.
---@param filename string
---@param bufnr? integer
---@return string | nil directory containing the config, if found
local function get_config_path(filename, bufnr)
  local start, stop = marker_walk_bounds(bufnr)

  local found = vim.fs.find(filename, {
    path = start,
    upward = true,
    type = "file",
    stop = stop,
    limit = 1,
  })
  if found[1] then
    return vim.fs.dirname(found[1])
  end
  return nil
end

M.biome_config_path = function()
  return get_config_path "biome.json" or get_config_path "biome.jsonc"
end

M.biome_config_exists = function()
  return M.biome_config_path() ~= nil
end

M.oxlint_config_exists = function()
  for _, name in ipairs(oxlint_markers) do
    if get_config_path(name) then
      return true
    end
  end
  return false
end

M.eslint_config_exists = function()
  for _, name in ipairs(eslint_markers) do
    if get_config_path(name) then
      return true
    end
  end
  return false
end

--- Prefer biome > oxlint > eslint at the *nearest* directory with any marker.
--- Never invent a linter. Override: vim.g.lsp_js_linter = "biome"|"oxlint"|"eslint"|false
---@param bufnr? integer buffer to resolve markers from (default: current)
---@return string|nil
function M.detect_js_linter(bufnr)
  local forced = vim.g.lsp_js_linter
  if forced == false then
    return nil
  end
  if type(forced) == "string" and forced ~= "" then
    if forced == "biome" or forced == "oxlint" or forced == "eslint" then
      return forced
    end
    vim.notify(
      ("lsp_js_linter=%q ignored; use biome|oxlint|eslint|false"):format(forced),
      vim.log.levels.WARN
    )
    -- Fall through to nearest-directory auto-detect.
  end

  local start, stop = marker_walk_bounds(bufnr)
  local dir = start
  while dir and dir ~= "" do
    if dir_has_marker(dir, biome_markers) then
      return "biome"
    end
    if dir_has_marker(dir, oxlint_markers) then
      return "oxlint"
    end
    if dir_has_marker(dir, eslint_markers) then
      return "eslint"
    end
    if dir == stop then
      break
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
  return nil
end

--- Resolve TypeScript LSP name. Default vtsls; legacy ts_ls via vim.g.lsp_typescript_server.
---@return string
function M.resolve_typescript_server()
  local name = vim.g.lsp_typescript_server or "vtsls"
  if name == "vtsls" or name == "ts_ls" then
    return name
  end
  vim.notify(
    ("lsp_typescript_server=%q ignored; use vtsls|ts_ls"):format(tostring(name)),
    vim.log.levels.WARN
  )
  return "vtsls"
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

--- Prefer a `ruff` that supports `ruff server` (Homebrew 0.1.x does not).
---@return string[]
function M.ruff_cmd()
  local candidates = {}
  local home = vim.fn.expand "~"
  -- uv tool / mise installs before PATH (Homebrew often shadows with old ruff)
  for _, path in ipairs {
    home .. "/.local/bin/ruff",
    home .. "/.local/share/mise/shims/ruff",
  } do
    if vim.uv.fs_stat(path) then
      table.insert(candidates, path)
    end
  end
  if vim.fn.executable "mise" == 1 then
    local out = vim.fn.system { "mise", "which", "ruff" }
    if vim.v.shell_error == 0 then
      local path = vim.trim(out)
      if path ~= "" then
        table.insert(candidates, path)
      end
    end
  end
  local on_path = vim.fn.exepath "ruff"
  if on_path ~= "" then
    table.insert(candidates, on_path)
  end
  for _, bin in ipairs(candidates) do
    if vim.fn.executable(bin) == 1 then
      local help = vim.fn.system { bin, "server", "--help" }
      if type(help) == "string" and help:find("language server", 1, true) then
        return { bin, "server" }
      end
    end
  end
  return { "ruff", "server" }
end

--- Prefer uv-installed `ty` when Homebrew/PATH is incomplete.
---@return string[]
function M.ty_cmd()
  local candidates = {}
  local home = vim.fn.expand "~"
  for _, path in ipairs {
    home .. "/.local/bin/ty",
    home .. "/.local/share/mise/shims/ty",
  } do
    if vim.uv.fs_stat(path) then
      table.insert(candidates, path)
    end
  end
  local on_path = vim.fn.exepath "ty"
  if on_path ~= "" then
    table.insert(candidates, on_path)
  end
  for _, bin in ipairs(candidates) do
    if vim.fn.executable(bin) == 1 then
      return { bin, "server" }
    end
  end
  return { "ty", "server" }
end

--- Absolute path to typescript/lib/tsserver.js when available (ts_ls needs TS 5.x layout).
---@return string|nil
function M.tsserver_js_path()
  local roots = {}
  if vim.fn.executable "npm" == 1 then
    local root = vim.trim(vim.fn.system { "npm", "root", "-g" })
    if vim.v.shell_error == 0 and root ~= "" then
      table.insert(roots, root)
    end
  end
  local node = vim.fn.exepath "node"
  if node ~= "" then
    -- sibling lib/node_modules next to node binary (mise layout)
    local lib = vim.fn.fnamemodify(node, ":h:h") .. "/lib/node_modules"
    table.insert(roots, lib)
  end
  for _, root in ipairs(roots) do
    local path = root .. "/typescript/lib/tsserver.js"
    if vim.uv.fs_stat(path) then
      return path
    end
  end
  return nil
end

return M
