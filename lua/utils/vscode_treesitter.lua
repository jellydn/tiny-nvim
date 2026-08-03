-- Treesitter expand/shrink for vscode-neovim.
-- Uses flash.plugins.treesitter.get_nodes so node detection matches terminal flash `S`.
-- No letter-label overlay: vscode-neovim virt_text marks were unreliable and broke jumps.
local M = {}

---@type Flash.Match.TS[]|nil
local last_matches
local last_bufnr ---@type integer?
local last_idx = 1

---@param match Flash.Match.TS
local function select_match(match)
  -- Leave visual first; otherwise `gv` can keep the previous range.
  if vim.fn.mode():find "[vV\x16]" then
    vim.cmd [[execute "normal! \<Esc>"]]
  end
  vim.fn.setpos("'<", { 0, match.pos[1], match.pos[2] + 1, 0 })
  vim.fn.setpos("'>", { 0, match.end_pos[1], match.end_pos[2] + 1, 0 })
  vim.cmd.normal { "gv", bang = true }

  local node = match.node
  if node then
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

--- Expand: innermost node, then parents on repeat (same chain as flash `S`).
function M.expand()
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

-- Alias kept so older call sites still work
function M.select()
  M.expand()
end

return M
