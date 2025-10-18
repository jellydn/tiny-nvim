-- This configuration sets up scooter with which-key integration and custom keybindings.
local mapping_key_prefix = vim.g.search_prefix_key or "<leader>s"
local scooter_term = nil

-- Called by scooter to open the selected file at the correct line from the scooter search list
_G.EditLineFromScooter = function(file_path, line)
  if scooter_term and scooter_term:buf_valid() then
    scooter_term:hide()
  end

  local current_path = vim.fn.expand "%:p"
  local target_path = vim.fn.fnamemodify(file_path, ":p")

  if current_path ~= target_path then
    vim.cmd.edit(vim.fn.fnameescape(file_path))
  end

  vim.api.nvim_win_set_cursor(0, { line, 0 })
end

local function is_terminal_running(term)
  if not term or not term:buf_valid() then
    return false
  end
  local channel = vim.fn.getbufvar(term.buf, "terminal_job_id")
  return channel and vim.fn.jobwait({ channel }, 0)[1] == -1
end

local function open_scooter()
  if scooter_term and is_terminal_running(scooter_term) then
    scooter_term:toggle()
  else
    scooter_term = require("snacks").terminal.open("scooter", {
      win = { position = "float" },
    })
  end
end

local function open_scooter_with_text(search_text)
  if scooter_term and scooter_term:buf_valid() then
    scooter_term:close()
  end

  local escaped_text = vim.fn.shellescape(search_text:gsub("\r?\n", " "))
  scooter_term = require("snacks").terminal.open("scooter --fixed-strings --search-text " .. escaped_text, {
    win = { position = "float" },
  })
end

return {
  -- Disable grug-far if using scooter
  {
    "MagicDuck/grug-far.nvim",
    enabled = false,
  },
  -- Register scooter keybindings in which-key
  {
    "folke/which-key.nvim",
    optional = true,
    dependencies = {
      "folke/snacks.nvim",
    },
    opts = {
      spec = {
        {
          mapping_key_prefix .. "r",
          open_scooter,
          desc = "Open scooter",
          mode = "n",
        },
        {
          mapping_key_prefix .. "r",
          function()
            local selection = vim.fn.getreg '"'
            vim.cmd 'normal! "ay'
            open_scooter_with_text(vim.fn.getreg "a")
            vim.fn.setreg('"', selection)
          end,
          desc = "Search selected text in scooter",
          mode = "v",
        },
      },
    },
  },
}
