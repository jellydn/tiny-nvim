if not vim.g.vscode then
  return {}
end

local enabled = {
  "lazy.nvim",
  "nvim-treesitter",
  "ts-comments.nvim",
  "nvim-treesitter",
  "nvim-treesitter-textobjects",
  "nvim-ts-context-commentstring",
  "vim-repeat",
}

local Config = require "lazy.core.config"
Config.options.checker.enabled = false
Config.options.change_detection.enabled = false
Config.options.defaults.cond = function(plugin)
  return vim.tbl_contains(enabled, plugin.name) or plugin.vscode
end

-- Add some vscode specific keymaps
-- Refer to https://github.com/vscode-neovim/vscode-neovim#code-navigation-bindings for default keymaps
vim.api.nvim_create_autocmd("User", {
  pattern = "NvimIdeKeymaps", -- This pattern will be called when the plugin is loaded
  callback = function()
    local vscode = require "vscode"
    -- +File
    -- Find file
    vim.keymap.set("n", "<leader><space>", "<cmd>Find<cr>")

    -- Find recent open files
    vim.keymap.set("n", "<leader>fr", function()
      vscode.action "workbench.action.showAllEditorsByMostRecentlyUsed"
    end)

    -- Need to install https://github.com/jellydn/vscode-fzf-picker
    vim.keymap.set("n", "<leader>ff", function()
      vscode.action "fzf-picker.findFiles"
    end)
    -- Find word
    vim.keymap.set({ "n", "v" }, "<leader>fw", function()
      vscode.action "fzf-picker.findWithinFiles"
    end)
    vim.keymap.set("n", "<leader>fw", function()
      vscode.action "editor.action.addSelectionToNextFindMatch"
      vscode.action "fzf-picker.findWithinFiles"
    end)
    -- Find file from git status
    vim.keymap.set("n", "<leader>fg", function()
      vscode.action "fzf-picker.pickFileFromGitStatus"
    end)
    -- Resume last search
    vim.keymap.set("n", "<leader>fR", function()
      vscode.action "fzf-picker.resumeSearch"
    end)
    -- Find todo/fixme
    vim.keymap.set("n", "<leader>fx", function()
      vscode.action "fzf-picker.findTodoFixme"
    end)

    -- Open other files
    vim.keymap.set("n", "<leader>,", function()
      vscode.action "workbench.action.showAllEditors"
    end)
    -- Find in files
    vim.keymap.set("n", "<leader>/", function()
      vscode.action "workbench.action.findInFiles"
    end)
    -- Open file explorer in left sidebar
    vim.keymap.set("n", "<leader>e", function()
      vscode.action "workbench.view.explorer"
    end)

    -- +Search
    -- Open symbol
    vim.keymap.set("n", "<leader>ss", function()
      vscode.action "workbench.action.gotoSymbol"
    end)
    -- Search word under cursor
    vim.keymap.set("n", "<leader>sw", function()
      vscode.action "editor.action.addSelectionToNextFindMatch"
      vscode.action "workbench.action.findInFiles"
      -- Or send as the param like this: code.action("workbench.action.findInFiles", { args = { query = vim.fn.expand("<cword>") } })
    end)

    -- Keep undo/redo lists in sync with VsCode
    vim.keymap.set("n", "u", "<Cmd>call VSCodeNotify('undo')<CR>")
    vim.keymap.set("n", "<C-r>", "<Cmd>call VSCodeNotify('redo')<CR>")
    -- Navigate VSCode tabs like lazyvim buffers
    vim.keymap.set("n", "<S-h>", "<Cmd>call VSCodeNotify('workbench.action.previousEditor')<CR>")
    vim.keymap.set("n", "<S-l>", "<Cmd>call VSCodeNotify('workbench.action.nextEditor')<CR>")

    -- Search work in current buffer
    vim.keymap.set("n", "<leader>sb", function()
      vscode.action "actions.find"
    end)

    -- +Code
    -- Code Action
    vim.keymap.set("n", "<leader>ca", function()
      vscode.action "editor.action.codeAction"
    end)
    -- Source Action
    vim.keymap.set("n", "<leader>cA", function()
      vscode.action "editor.action.sourceAction"
    end)
    -- Code Rename
    vim.keymap.set("n", "<leader>cr", function()
      vscode.action "editor.action.rename"
    end)
    -- Quickfix shortcut
    vim.keymap.set("n", "<leader>.", function()
      vscode.action "editor.action.quickFix"
    end)
    -- Code format
    vim.keymap.set("n", "<leader>cf", function()
      vscode.action "editor.action.formatDocument"
    end)
    -- Refactor
    vim.keymap.set("n", "<leader>cR", function()
      vscode.action "editor.action.refactor"
    end)

    -- +Terminal
    -- Open terminal
    vim.keymap.set("n", "<leader>ft", function()
      vscode.action "workbench.action.terminal.focus"
    end)

    -- +LSP
    -- View problem
    vim.keymap.set("n", "<leader>xx", function()
      vscode.action "workbench.actions.view.problems"
    end)
    -- Go to next/prev error
    vim.keymap.set("n", "]e", function()
      vscode.action "editor.action.marker.next"
    end)
    vim.keymap.set("n", "[e", function()
      vscode.action "editor.action.marker.prev"
    end)

    -- Find references
    vim.keymap.set("n", "gr", function()
      vscode.action "references-view.find"
    end)

    -- +Git
    -- Git status
    vim.keymap.set("n", "<leader>gs", function()
      vscode.action "workbench.view.scm"
    end)
    -- Go to next/prev change
    vim.keymap.set("n", "]h", function()
      vscode.action "workbench.action.editor.nextChange"
    end)
    vim.keymap.set("n", "[h", function()
      vscode.action "workbench.action.editor.previousChange"
    end)

    -- Revert change
    vim.keymap.set("v", "<leader>ghr", function()
      vscode.action "git.revertSelectedRanges"
    end)

    -- +Buffer
    -- Switch buffer
    vim.keymap.set("n", "<leader>`", function()
      vscode.action "workbench.action.quickOpenPreviousRecentlyUsedEditor"
      vscode.action "list.select"
    end)

    -- Close buffer
    vim.keymap.set("n", "<leader>bd", function()
      vscode.action "workbench.action.closeActiveEditor"
    end)
    -- Close other buffers
    vim.keymap.set("n", "<leader>bo", function()
      vscode.action "workbench.action.closeOtherEditors"
    end)

    -- +Project
    vim.keymap.set("n", "<leader>fp", function()
      vscode.action "workbench.action.openRecent"
    end)

    -- Markdown preview
    vim.keymap.set("n", "<leader>mp", function()
      vscode.action "markdown.showPreviewToSide"
    end)

    -- Hurl runner, https://github.com/jellydn/vscode-hurl-runner
    vim.keymap.set("n", "<leader>ha", function()
      vscode.action "vscode-hurl-runner.runHurl"
    end)
    vim.keymap.set("n", "<leader>hr", function()
      vscode.action "vscode-hurl-runner.rerunLastCommand"
    end)
    vim.keymap.set("n", "<leader>hA", function()
      vscode.action "vscode-hurl-runner.runHurlFile"
    end)
    vim.keymap.set("n", "<leader>he", function()
      vscode.action "vscode-hurl-runner.runHurlFromBegin"
    end)
    vim.keymap.set("n", "<leader>hE", function()
      vscode.action "vscode-hurl-runner.runHurlToEnd"
    end)
    vim.keymap.set("n", "<leader>hg", function()
      vscode.action "vscode-hurl-runner.manageInlineVariables"
    end)
    vim.keymap.set("n", "<leader>hh", function()
      vscode.action "vscode-hurl-runner.viewLastResponse"
    end)
    vim.keymap.set("v", "<leader>hh", function()
      vscode.action "vscode-hurl-runner.runHurlSelection"
    end)

    -- Run task
    vim.keymap.set("n", "<leader>rt", function()
      vscode.action "workbench.action.tasks.runTask"
    end)
    -- Re-run
    vim.keymap.set("n", "<leader>rr", function()
      vscode.action "workbench.action.tasks.reRunTask"
    end)

    -- Debug typescript type, used with https://marketplace.visualstudio.com/items?itemName=Orta.vscode-twoslash-queries
    vim.keymap.set("n", "<leader>dd", function()
      vscode.action "orta.vscode-twoslash-queries.insert-twoslash-query"
    end)

    -- Other keymaps will be used with https://github.com/VSpaceCode/vscode-which-key, so we don't need to define them here
    -- Trigger which-key by pressing <CMD+Space>, refer more default keymaps https://github.com/VSpaceCode/vscode-which-key/blob/15c5aa2da5812a21210c5599d9779c46d7bfbd3c/package.json#L265

    -- Multiple cursors
    vim.keymap.set({ "n", "x", "i" }, "<C-m>", function()
      require("vscode-multi-cursor").addSelectionToNextFindMatch()
    end)
  end,
})

return {
  {
    "xiyaowong/fast-cursor-move.nvim",
    vscode = true,
    enabled = vim.g.vscode,
    init = function()
      -- Disable acceleration, use key repeat settings instead
      vim.g.fast_cursor_move_acceleration = false
    end,
  },
  -- Refer https://github.com/vscode-neovim/vscode-multi-cursor.nvim to more usages
  -- gcc: clear multi cursors
  -- gc: create multi cursors
  -- mi/mI/ma/MA: insert text at each cursor
  {
    "vscode-neovim/vscode-multi-cursor.nvim",
    event = "VeryLazy",
    cond = not not vim.g.vscode,
    opts = {},
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { highlight = { enable = false } },
  },
}
