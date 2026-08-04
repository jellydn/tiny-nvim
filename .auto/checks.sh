#!/usr/bin/env bash
# Independent correctness checks — must NOT require compat_failures==0.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Shell syntax of measure script
bash -n .auto/measure.sh

# Parse all tracked Lua (syntax only)
NVIM="${NVIM_BIN:-$(command -v nvim 2>/dev/null || true)}"
if [[ -z "$NVIM" || ! -x "$NVIM" ]]; then
  echo "nvim not found on PATH; set NVIM_BIN to a Neovim 0.13 binary" >&2
  exit 1
fi
out="$("$NVIM" --headless -u NONE \
  +"lua local root=[[$ROOT]]; local bad=0; local files={}; for _,pat in ipairs({root..'/init.lua', root..'/lua/**/*.lua', root..'/lsp/*.lua'}) do for _,p in ipairs(vim.fn.glob(pat, false, true)) do table.insert(files,p) end end; for _,p in ipairs(files) do local ok,err=loadfile(p); if not ok then bad=bad+1; io.stderr:write('LOAD_FAIL '..p..' :: '..tostring(err)..'\\n') end end; if bad>0 then os.exit(1) end; vim.cmd('qa!')" \
  2>&1)" || {
  echo "$out" >&2
  exit 1
}

# Hard support invariants still present in source (not runtime score)
rg -q 'nvim-treesitter/nvim-treesitter' lua/plugins/ui.lua
rg -q 'nvim-treesitter-textobjects' lua/plugins/ui.lua
rg -q 'sidekick.nvim' lua/plugins/ai.lua
rg -q 'vim\.lsp\.enable' init.lua
rg -q 'mini\.ai' lua/plugins/coding.lua
test -d lsp && test "$(find lsp -name '*.lua' | wc -l | tr -d ' ')" -ge 1

exit 0
