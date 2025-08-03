return {
    {
        "ravitemer/mcphub.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        cmd = "MCPHub",          -- lazy load by default
        build = "bundled_build.lua", -- Use this and set use_bundled_binary = true in opts  (see Advanced configuration)
        opts = {
            use_bundled_binary = true,
            -- TODO: Use same config with Cursor
            config = vim.fn.expand "~/.config/nvim/lua/plugins/extra/mcphub.json", -- Absolute path to config file location (will create if not exists)
        },
    },
}
