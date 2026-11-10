return {
  "lalitmee/cobalt2.nvim",
  -- Load on any colorscheme command so colors/cobalt2.vim is on rtp in time
  event = { "ColorSchemePre" },
  dependencies = { { "tjdevries/colorbuddy.nvim", tag = "v1.0.0" } },
}
