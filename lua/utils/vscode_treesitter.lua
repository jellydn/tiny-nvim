-- Treesitter select for vscode-neovim with flash-like letter marks.
-- Labels sit after each node end (flash `label.after`) so nested starts do not collide.
local M = {}

local NS = vim.api.nvim_create_namespace "vscode_treesitter_flash"

---@type string
local LABELS = "asdfghjklqwertyuiopzxcvbnm"

-- Overridable for headless probes
M._getchar = function()
  return vim.fn.getcharstr()
end

---@param match Flash.Match.TS
local function select_match(match)
  if vim.fn.mode():find "[vV\x16]" then
    vim.cmd [[execute "normal! \<Esc>"]]
  end
  vim.fn.setpos("'<", { 0, match.pos[1], match.pos[2] + 1, 0 })
  vim.fn.setpos("'>", { 0, match.end_pos[1], match.end_pos[2] + 1, 0 })
  vim.cmd.normal { "gv", bang = true }
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

---@param matches Flash.Match.TS[]
---@param current Flash.Match.TS?
function M.paint(matches, current)
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
  pcall(require, "flash.highlight")

  ---@type table<string, {row:integer,col:integer,text:string[][]}>
  local label_marks = {}

  for _, match in ipairs(matches) do
    local is_current = current and match == current
    pcall(vim.api.nvim_buf_set_extmark, buf, NS, match.pos[1] - 1, match.pos[2], {
      end_row = match.end_pos[1] - 1,
      end_col = match.end_pos[2] + 1,
      hl_group = is_current and "FlashCurrent" or "FlashMatch",
      strict = false,
      priority = 5000,
    })

    if match.label then
      local row = match.end_pos[1] - 1
      local col = match.end_pos[2] + 1
      local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
      if col > #line then
        col = #line
      end
      local key = row .. ":" .. col
      label_marks[key] = label_marks[key] or { row = row, col = col, text = {} }
      -- Keep assignment order: innermost labels first (flash stacks at same cell)
      table.insert(label_marks[key].text, { match.label, "FlashLabel" })
    end
  end

  for _, mark in pairs(label_marks) do
    pcall(vim.api.nvim_buf_set_extmark, buf, NS, mark.row, mark.col, {
      virt_text = mark.text,
      virt_text_pos = "inline",
      hl_mode = "combine",
      strict = false,
      priority = 5003,
    })
  end

  vim.cmd.redraw()
end

local function clear()
  vim.api.nvim_buf_clear_namespace(vim.api.nvim_get_current_buf(), NS, 0, -1)
  vim.cmd.redraw()
end

local function find_index(matches, current)
  for i, m in ipairs(matches) do
    if m == current then
      return i
    end
  end
  return 1
end

--- Flash-like treesitter select: show marks, press label (or ;/, / CR / Esc).
function M.select()
  local matches = current_matches()
  if #matches == 0 then
    vim.notify("No treesitter node under cursor", vim.log.levels.WARN, { title = "flash treesitter" })
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

  M.paint(matches, current)

  while true do
    local ok, char = pcall(M._getchar)
    if not ok or not char or char == "" then
      clear()
      return
    end

    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    if char == esc then
      clear()
      return
    end

    if char == ";" then
      local idx = find_index(matches, current)
      current = matches[math.min(idx + 1, #matches)]
      M.paint(matches, current)
    elseif char == "," then
      local idx = find_index(matches, current)
      current = matches[math.max(idx - 1, 1)]
      M.paint(matches, current)
    elseif char == "\r" or char == "\n" then
      clear()
      select_match(current)
      return
    else
      local target = by_label[char:lower()]
      if target then
        clear()
        select_match(target)
        return
      end
      clear()
      return
    end
  end
end

function M.expand()
  M.select()
end

function M.shrink()
  local matches = current_matches()
  if #matches == 0 then
    return
  end
  select_match(matches[1])
end

--- Test helper: matches + label map without UI loop.
function M.debug_labels()
  local matches = current_matches()
  local by_label = assign_labels(matches)
  M.paint(matches, matches[1])
  return matches, by_label
end

return M
