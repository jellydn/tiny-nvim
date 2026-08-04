local M = {}

--- Check if current directory is a git repo
---@return boolean
function M.is_git_repo()
  vim.fn.system "git rev-parse --is-inside-work-tree"
  return vim.v.shell_error == 0
end

--- Get root directory of git project
---@return string|nil
function M.get_git_root()
  local out = vim.fn.systemlist "git rev-parse --show-toplevel"
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
    return nil
  end
  return out[1]
end

--- Get root directory of git project or fallback to current directory
---@return string|nil
function M.get_root_directory()
  if M.is_git_repo() then
    return M.get_git_root()
  end

  return vim.fn.getcwd()
end

return M
