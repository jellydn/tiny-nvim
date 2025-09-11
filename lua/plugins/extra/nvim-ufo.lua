local fold_text_handler = function(virtual_text, lnum, endLnum, width, truncate)
  local new_virtual_text = {}
  local suffix = (" 󰁂 %d "):format(endLnum - lnum)
  local suffix_width = vim.fn.strdisplaywidth(suffix)
  local target_width = width - suffix_width
  local current_width = 0
  for _, chunk in ipairs(virtual_text) do
    local chunkText = chunk[1]
    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
    if target_width > current_width + chunkWidth then
      table.insert(new_virtual_text, chunk)
    else
      chunkText = truncate(chunkText, target_width - current_width)
      local hlGroup = chunk[2]
      table.insert(new_virtual_text, { chunkText, hlGroup })
      chunkWidth = vim.fn.strdisplaywidth(chunkText)
      -- str width returned from truncate() may less than 2nd argument, need padding
      if current_width + chunkWidth < target_width then
        suffix = suffix .. (" "):rep(target_width - current_width - chunkWidth)
      end
      break
    end
    current_width = current_width + chunkWidth
  end
  table.insert(new_virtual_text, { suffix, "MoreMsg" })
  return new_virtual_text
end

return {
  -- UFO folding
  {
    "kevinhwang91/nvim-ufo",
    dependencies = {
      "kevinhwang91/promise-async",
    },
    event = "BufReadPost",
    opts = {
      provider_selector = function()
        return { "treesitter", "indent" }
      end,
      fold_virt_text_handler = fold_text_handler,
    },
    keys = {
      {
        "zR",
        function()
          require("ufo").openAllFolds()
        end,
        desc = "Open all folds",
      },
      {
        "zM",
        function()
          require("ufo").closeAllFolds()
        end,
        desc = "Close all folds",
      },
    },
    init = function()
      -- Setup UFO folding
      vim.o.foldcolumn = "0"
      vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
      vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
    end,
  },
}
