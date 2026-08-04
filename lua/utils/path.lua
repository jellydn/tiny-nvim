local M = {}

--- Check if path (or cwd) is inside a git work tree
---@param path? string
---@return boolean
function M.is_git_repo(path)
  local dir = path or vim.fn.getcwd()
  vim.fn.system { "git", "-C", dir, "rev-parse", "--is-inside-work-tree" }
  return vim.v.shell_error == 0
end

--- Get root directory of git project containing path (or cwd)
---@param path? string
---@return string|nil
function M.get_git_root(path)
  local dir = path or vim.fn.getcwd()
  local out = vim.fn.systemlist { "git", "-C", dir, "rev-parse", "--show-toplevel" }
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
