return {
  -- Folding preview, by default h and l keys are used.
  -- On first press of h key, when cursor is on a closed fold, the preview will be shown.
  -- On second press the preview will be closed and fold will be opened.
  -- When preview is opened, the l key will close it and open fold. In all other cases these keys will work as usual.
  {
    "anuvyklack/fold-preview.nvim",
    event = "BufReadPost",
    dependencies = "anuvyklack/keymap-amend.nvim",
    config = true,
  },
  -- Custom fold text with line count
  {
    "bbjornstad/pretty-fold.nvim",
    event = "BufReadPost",
    config = function()
      require("pretty-fold").setup({
        keep_indentation = false,
        fill_char = " ",
        sections = {
          left = {
            function()
              -- Calculate the fold level and return the appropriate string
              local level = vim.v.foldlevel
              if level == 0 then
                return "󰁚 "
              else
                return string.rep("  ", level - 1) .. "󰁚 "
              end
            end,
            "content",
          },
          right = {
            "󰁂 ",
            "number_of_folded_lines",
          },
        },
      })
    end,
  },
}
