-- Treesitter select for vscode-neovim with flash-like letter marks.
-- vscode-neovim paints range highlights reliably; virt_text labels are best-effort,
-- so we also hl the first char of each node as a visible mark fallback.
local M = {}

local NS = vim.api.nvim_create_namespace "vscode_treesitter_flash"

---@type string
local LABELS = "asdfghjklqwertyuiopzxcvbnm"

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
local function paint(matches, current)
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)

  -- Ensure Flash* groups exist (flash.highlight sets vscode-specific colors)
  pcall(require, "flash.highlight")

  for _, match in ipairs(matches) do
    local is_current = current and match == current
    local hl = is_current and "FlashCurrent" or "FlashMatch"
    vim.api.nvim_buf_set_extmark(buf, NS, match.pos[1] - 1, match.pos[2], {
      end_row = match.end_pos[1] - 1,
      end_col = match.end_pos[2] + 1,
      hl_group = hl,
      strict = false,
      priority = 5000,
    })

    if match.label then
      -- Visible mark fallback: color first character like a hop/flash label cell
      vim.api.nvim_buf_set_extmark(buf, NS, match.pos[1] - 1, match.pos[2], {
        end_row = match.pos[1] - 1,
        end_col = match.pos[2] + 1,
        hl_group = "FlashLabel",
        strict = false,
        priority = 5002,
      })
      -- Letter mark (virt_text — vscode-neovim maps these to before-decorations)
      vim.api.nvim_buf_set_extmark(buf, NS, match.end_pos[1] - 1, match.end_pos[2] + 1, {
        virt_text = { { match.label, "FlashLabel" } },
        virt_text_pos = "inline",
        strict = false,
        priority = 5003,
      })
    end
  end

  vim.cmd.redraw()
end

local function clear()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
end

--- Flash-like treesitter select: show marks, press label (or ;/, / Esc).
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
    if not current.depth or (m.depth and m.depth > current.depth) then
      current = m
    end
  end

  paint(matches, current)

  while true do
    local ok, char = pcall(vim.fn.getcharstr)
    if not ok or char == "" or char == vim.api.nvim_replace_termcodes("<Esc>", true, false, true) then
      clear()
      return
    end

    if char == ";" then
      -- next parent (deeper → outer in flash treesitter order)
      local idx = 1
      for i, m in ipairs(matches) do
        if m == current then
          idx = i
          break
        end
      end
      current = matches[math.min(idx + 1, #matches)]
      paint(matches, current)
    elseif char == "," then
      local idx = 1
      for i, m in ipairs(matches) do
        if m == current then
          idx = i
          break
        end
      end
      current = matches[math.max(idx - 1, 1)]
      paint(matches, current)
    elseif char == "\r" or char == "\n" then
      clear()
      select_match(current)
      return
    elseif by_label[char] then
      clear()
      select_match(by_label[char])
      return
    else
      -- unknown key: abort like flash
      clear()
      return
    end
  end
end

--- Expand selection without labels (repeat `S` style). Kept for gS shrink pairing.
function M.expand()
  M.select()
end

function M.shrink()
  local matches = current_matches()
  if #matches == 0 then
    return
  end
  -- Innermost node
  select_match(matches[1])
end

return M
