-- Treesitter expand/shrink (+ optional labeled select under vscode-neovim).
-- Used by <C-Space>/<BS> in terminal and vscode, and by flash `S` under vscode.
-- Labels (select) use vscode.eval TextEditorDecorationType — not nvim virt_text.
local M = {}

---@type string
local LABELS = "asdfghjklqwertyuiopzxcvbnm"

---@type Flash.Match.TS[]|nil
local last_matches
local last_bufnr ---@type integer?
local last_idx = 1

-- Overridable for headless probes
M._getchar = function()
  return vim.fn.getcharstr()
end

---@return boolean
local function has_vscode_eval()
  if not vim.g.vscode then
    return false
  end
  local ok, vscode = pcall(require, "vscode")
  return ok and type(vscode.eval) == "function" and vim.g.vscode_channel ~= nil
end

---@param match Flash.Match.TS
local function select_match(match)
  if vim.fn.mode():find "[vV\x16]" then
    vim.cmd [[execute "normal! \<Esc>"]]
  end
  vim.fn.setpos("'<", { 0, match.pos[1], match.pos[2] + 1, 0 })
  vim.fn.setpos("'>", { 0, match.end_pos[1], match.end_pos[2] + 1, 0 })
  vim.cmd.normal { "gv", bang = true }

  local node = match.node
  if node and vim.g.vscode_treesitter_notify then
    vim.notify(string.format("ts: %s (depth %d)", node:type(), match.depth or 0), vim.log.levels.INFO, {
      title = "flash treesitter",
    })
  end
end

---@return Flash.Match.TS[]
local function current_matches()
  pcall(function()
    vim.treesitter.get_parser():parse(true)
  end)
  local ok, flash_ts = pcall(require, "flash.plugins.treesitter")
  if not ok then
    return {}
  end
  return flash_ts.get_nodes(vim.api.nvim_get_current_win())
end

---@param matches Flash.Match.TS[]
---@return table<string, Flash.Match.TS>
local function assign_labels(matches)
  local by_label = {}
  local i = 1
  for _, match in ipairs(matches) do
    local label = LABELS:sub(i, i)
    if label == "" then
      match.label = nil
      break
    end
    match.label = label
    by_label[label] = match
    i = i + 1
  end
  return by_label
end

local CLEAR_JS = [[
  if (globalThis.__nvimFlashTsDecos) {
    for (const d of globalThis.__nvimFlashTsDecos) d.dispose();
  }
  globalThis.__nvimFlashTsDecos = [];
  return true;
]]

local PAINT_JS = [[
  const editor = vscode.window.activeTextEditor;
  if (!editor) return false;
  if (globalThis.__nvimFlashTsDecos) {
    for (const d of globalThis.__nvimFlashTsDecos) d.dispose();
  }
  globalThis.__nvimFlashTsDecos = [];

  const items = args || [];
  for (const item of items) {
    const matchType = vscode.window.createTextEditorDecorationType({
      backgroundColor: item.current ? "rgba(255, 215, 0, 0.35)" : "rgba(255, 0, 124, 0.18)",
    });
    globalThis.__nvimFlashTsDecos.push(matchType);
    editor.setDecorations(matchType, [
      new vscode.Range(item.line, item.character, item.endLine, item.endCharacter),
    ]);

    if (item.label) {
      const labelType = vscode.window.createTextEditorDecorationType({});
      globalThis.__nvimFlashTsDecos.push(labelType);
      const end = new vscode.Position(item.endLine, item.endCharacter);
      editor.setDecorations(labelType, [
        {
          range: new vscode.Range(end, end),
          renderOptions: {
            after: {
              contentText: " " + item.label,
              color: "#ff007c",
              backgroundColor: "rgba(0, 0, 0, 0.75)",
              fontWeight: "bold",
              margin: "0 0 0 1px",
            },
          },
        },
      ]);
    }
  }
  return items.length;
]]

local function clear_vscode_labels()
  if not has_vscode_eval() then
    return
  end
  pcall(function()
    require("vscode").eval(CLEAR_JS, {}, 2000)
  end)
end

---@param matches Flash.Match.TS[]
---@param current Flash.Match.TS?
local function paint_vscode_labels(matches, current)
  if not has_vscode_eval() then
    return false
  end
  ---@type table[]
  local items = {}
  for _, match in ipairs(matches) do
    table.insert(items, {
      line = match.pos[1] - 1,
      character = match.pos[2],
      endLine = match.end_pos[1] - 1,
      endCharacter = match.end_pos[2] + 1,
      label = match.label,
      current = current == match,
    })
  end
  local ok, n = pcall(function()
    return require("vscode").eval(PAINT_JS, { args = items }, 2000)
  end)
  return ok and type(n) == "number" and n > 0
end

local function find_index(matches, current)
  for i, m in ipairs(matches) do
    if m == current then
      return i
    end
  end
  return 1
end

--- Expand: innermost node, then parents on repeat (no labels).
function M.expand()
  clear_vscode_labels()
  local matches = current_matches()
  if #matches == 0 then
    vim.notify("No treesitter node under cursor", vim.log.levels.WARN, { title = "flash treesitter" })
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local idx = 1
  if last_matches and last_bufnr == bufnr and vim.fn.mode():find "[vV\x16]" then
    idx = math.min((last_idx or 1) + 1, #matches)
  end
  last_matches = matches
  last_bufnr = bufnr
  last_idx = idx
  select_match(matches[idx])
end

--- Shrink toward the innermost node.
function M.shrink()
  clear_vscode_labels()
  local matches = current_matches()
  if #matches == 0 then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local idx = 1
  if last_matches and last_bufnr == bufnr then
    idx = math.max((last_idx or 1) - 1, 1)
  end
  last_matches = matches
  last_bufnr = bufnr
  last_idx = idx
  select_match(matches[idx])
end

--- Flash-like labeled treesitter select via VS Code decorations.
--- Falls back to expand() when vscode.eval is unavailable.
function M.select()
  local matches = current_matches()
  if #matches == 0 then
    vim.notify("No treesitter node under cursor", vim.log.levels.WARN, { title = "flash treesitter" })
    return
  end

  if not has_vscode_eval() then
    M.expand()
    return
  end

  local by_label = assign_labels(matches)
  ---@type Flash.Match.TS
  local current = matches[1]
  for _, m in ipairs(matches) do
    if m.depth and (not current.depth or m.depth > current.depth) then
      current = m
    end
  end

  if not paint_vscode_labels(matches, current) then
    -- Decorations failed — keep working expand UX
    M.expand()
    return
  end

  while true do
    local ok, char = pcall(M._getchar)
    if not ok or not char or char == "" then
      clear_vscode_labels()
      return
    end

    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    if char == esc then
      clear_vscode_labels()
      return
    end

    if char == ";" then
      local idx = find_index(matches, current)
      current = matches[math.min(idx + 1, #matches)]
      paint_vscode_labels(matches, current)
    elseif char == "," then
      local idx = find_index(matches, current)
      current = matches[math.max(idx - 1, 1)]
      paint_vscode_labels(matches, current)
    elseif char == "\r" or char == "\n" then
      clear_vscode_labels()
      select_match(current)
      return
    else
      local target = by_label[char:lower()]
      if target then
        clear_vscode_labels()
        select_match(target)
        return
      end
      clear_vscode_labels()
      return
    end
  end
end

--- Test helper: label assignment without UI (no vscode channel needed).
function M.debug_labels()
  local matches = current_matches()
  local by_label = assign_labels(matches)
  return matches, by_label
end

return M
