-- NOTE: npm i -g vscode-langservers-extracted
return {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  init_options = {
    provideFormatter = true,
  },
  root_markers = {
    "package.json",
    "tsconfig.json",
    "jsconfig.json",
    "biome.json",
    "biome.jsonc",
    ".git",
  },
}
