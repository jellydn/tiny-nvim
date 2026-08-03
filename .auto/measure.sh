#!/usr/bin/env bash
# Frozen Neovim 0.13 compatibility benchmark. Do not soften assertions after baseline.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

NVIM="${NVIM_BIN:-/Users/huynhdung/.local/share/mise/installs/neovim/nightly/bin/nvim}"
FIX="$ROOT/.auto/fixtures"
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/nvim13-measure.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

mkdir -p "$FIX" "$WORKDIR"

# --- fixtures (create once; do not change after baseline freeze) ---
if [[ ! -f "$FIX/sample.lua" ]]; then
  cat >"$FIX/sample.lua" <<'EOF'
local M = {}
function M.hello()
  return "ok"
end
return M
EOF
fi
if [[ ! -f "$FIX/sample.md" ]]; then
  cat >"$FIX/sample.md" <<'EOF'
# Hello

A markdown fixture for filetype and treesitter checks.
EOF
fi

fail_binary=0
fail_startup=0
fail_messages=0
fail_deprecated=0
fail_loadfile=0
fail_fixture_lua=0
fail_fixture_md=0
fail_vim_loop=0
fail_treesitter=0
fail_ai=0
fail_lsp=0

# Python helper: run with timeout (macOS may lack GNU timeout)
run_to() {
  local secs="$1"
  shift
  python3 - "$secs" "$@" <<'PY'
import subprocess, sys
timeout = float(sys.argv[1])
cmd = sys.argv[2:]
try:
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    sys.stdout.write(p.stdout or "")
    sys.stderr.write(p.stderr or "")
    sys.exit(p.returncode)
except subprocess.TimeoutExpired as e:
    sys.stderr.write(f"TIMEOUT after {timeout}s: {' '.join(cmd)}\n")
    if e.stdout:
        sys.stdout.write(e.stdout if isinstance(e.stdout, str) else e.stdout.decode())
    if e.stderr:
        sys.stderr.write(e.stderr if isinstance(e.stderr, str) else e.stderr.decode())
    sys.exit(124)
PY
}

# --- 1) Binary is Neovim 0.13 ---
ver_out="$("$NVIM" --version 2>/dev/null | head -n 1 || true)"
if ! echo "$ver_out" | grep -qE 'NVIM v0\.13\.'; then
  fail_binary=1
  echo "ASSERT binary_version FAIL: $ver_out" >&2
fi

# --- 2) Normal headless startup (no --clean, no -u NONE) ---
startup_log="$WORKDIR/startup.log"
startup_err="$WORKDIR/startup.err"
if ! run_to 25 "$NVIM" --headless \
  +"lua vim.g.autoresearch_bench=true" \
  +"lua vim.defer_fn(function() print('STARTUP_OK'); vim.cmd('qa!') end, 2000)" \
  >"$startup_log" 2>"$startup_err"; then
  fail_startup=1
  echo "ASSERT startup FAIL exit" >&2
fi
if ! grep -q 'STARTUP_OK' "$startup_log"; then
  fail_startup=1
  echo "ASSERT startup FAIL missing STARTUP_OK" >&2
fi

# --- 3) Startup messages: no hard errors / tracebacks / deprecation warnings ---
msg_log="$WORKDIR/messages.log"
run_to 25 "$NVIM" --headless \
  +"lua vim.g.autoresearch_bench=true" \
  +"lua vim.defer_fn(function() local o=vim.api.nvim_exec2('messages',{output=true}).output; print('MSGS_BEGIN'); print(o); print('MSGS_END'); vim.cmd('qa!') end, 2500)" \
  >"$msg_log" 2>"$WORKDIR/messages.err" || true
msgs="$(sed -n '/MSGS_BEGIN/,/MSGS_END/p' "$msg_log" | sed '1d;$d' || true)"
if echo "$msgs" | grep -Eiq 'E[0-9]{3,}:|stack traceback|is deprecated|Vim%(script%)? error'; then
  # Ignore known env LSP noise
  if echo "$msgs" | grep -Eiv 'TypeScript installation|rust-analyzer quit|tsserver' | grep -Eiq 'E[0-9]{3,}:|stack traceback|is deprecated|Vim%(script%)? error'; then
    fail_messages=1
    echo "ASSERT messages FAIL" >&2
    echo "$msgs" | head -n 40 >&2
  fi
fi

# --- 4) vim.deprecated health buffer ---
dep_file="$WORKDIR/deprecated.txt"
run_to 30 "$NVIM" --headless \
  +"checkhealth vim.deprecated" \
  +"lua vim.fn.writefile(vim.api.nvim_buf_get_lines(0,0,-1,false), '$dep_file')" \
  +qa \
  >"$WORKDIR/dep.out" 2>"$WORKDIR/dep.err" || true
if [[ ! -f "$dep_file" ]] || ! grep -q 'No deprecated functions detected' "$dep_file"; then
  if [[ -f "$dep_file" ]] && grep -Eiq 'WARNING|ERROR|deprecated' "$dep_file"; then
    fail_deprecated=1
    echo "ASSERT deprecated FAIL" >&2
    cat "$dep_file" >&2
  elif [[ ! -f "$dep_file" ]]; then
    fail_deprecated=1
    echo "ASSERT deprecated FAIL: no health buffer" >&2
  fi
fi

# --- 5) loadfile all tracked lua ---
load_log="$WORKDIR/load.log"
run_to 20 "$NVIM" --headless -u NONE \
  +"lua local root=[[$ROOT]]; local bad=0; local files=vim.fn.glob(root..'/{init.lua,lua/**/*.lua,lsp/*.lua}', false, true); for _,p in ipairs(files) do local ok,err=loadfile(p); if not ok then bad=bad+1; print('LOAD_FAIL '..p..' :: '..tostring(err)) end end; print('LOAD_FAILS='..bad); vim.cmd('qa!')" \
  >"$load_log" 2>"$WORKDIR/load.err" || true
load_fails="$(grep -E '^LOAD_FAILS=' "$load_log" | tail -n1 | cut -d= -f2 || echo 1)"
load_fails="${load_fails:-1}"
if [[ "$load_fails" != "0" ]]; then
  fail_loadfile=1
  echo "ASSERT loadfile FAIL count=$load_fails" >&2
  grep 'LOAD_FAIL ' "$load_log" >&2 || true
fi

# --- 6) Fixture opens (lua + markdown only; avoid env LSP noise) ---
ft_lua_log="$WORKDIR/ft_lua.log"
run_to 25 "$NVIM" --headless "$FIX/sample.lua" \
  +"lua vim.defer_fn(function() print('FT='..vim.bo.filetype); vim.cmd('qa!') end, 1500)" \
  >"$ft_lua_log" 2>"$WORKDIR/ft_lua.err" || true
if ! grep -q 'FT=lua' "$ft_lua_log"; then
  fail_fixture_lua=1
  echo "ASSERT fixture_lua FAIL" >&2
fi

ft_md_log="$WORKDIR/ft_md.log"
run_to 25 "$NVIM" --headless "$FIX/sample.md" \
  +"lua vim.defer_fn(function() print('FT='..vim.bo.filetype); vim.cmd('qa!') end, 1500)" \
  >"$ft_md_log" 2>"$WORKDIR/ft_md.err" || true
if ! grep -q 'FT=markdown' "$ft_md_log"; then
  fail_fixture_md=1
  echo "ASSERT fixture_md FAIL" >&2
fi

# --- 7) Static policy: bare vim.loop (not vim.uv or vim.loop fallbacks only) ---
# Count direct `vim.loop.` usages that are not part of `(vim.uv or vim.loop)`
loop_hits="$(rg -n --glob '!*.auto/**' --glob '!.git/**' 'vim\.loop\.' "$ROOT" \
  | grep -v 'vim\.uv or vim\.loop' \
  | grep -v '^\.auto/' \
  || true)"
loop_count="$(printf '%s\n' "$loop_hits" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "${loop_count:-0}" -gt 0 ]]; then
  fail_vim_loop=1
  echo "ASSERT vim_loop FAIL ($loop_count direct uses):" >&2
  echo "$loop_hits" >&2
fi

# --- 8) Treesitter support ---
ts_log="$WORKDIR/ts.log"
run_to 30 "$NVIM" --headless \
  +"lua vim.g.autoresearch_bench=true" \
  +"lua vim.defer_fn(function()
      local ok_mod = pcall(require, 'nvim-treesitter')
      local has_api = vim.treesitter ~= nil and type(vim.treesitter.start) == 'function'
      local in_lock = vim.fn.filereadable(vim.fn.stdpath('config') .. '/lazy-lock.json') == 1
      local lock = in_lock and table.concat(vim.fn.readfile(vim.fn.stdpath('config') .. '/lazy-lock.json'), '\\n') or ''
      local lock_ok = lock:find('nvim%-treesitter', 1, false) ~= nil
      print(string.format('TS_MOD=%s TS_API=%s TS_LOCK=%s', tostring(ok_mod), tostring(has_api), tostring(lock_ok)))
      vim.cmd('qa!')
    end, 3000)" \
  >"$ts_log" 2>"$WORKDIR/ts.err" || true
if ! grep -q 'TS_MOD=true' "$ts_log" || ! grep -q 'TS_API=true' "$ts_log" || ! grep -q 'TS_LOCK=true' "$ts_log"; then
  fail_treesitter=1
  echo "ASSERT treesitter FAIL" >&2
  cat "$ts_log" >&2
fi

# --- 9) AI (sidekick) support ---
ai_log="$WORKDIR/ai.log"
run_to 30 "$NVIM" --headless \
  +"lua vim.g.autoresearch_bench=true" \
  +"lua vim.defer_fn(function()
      local ok_mod = pcall(require, 'sidekick')
      local lock = table.concat(vim.fn.readfile(vim.fn.stdpath('config') .. '/lazy-lock.json'), '\\n')
      local lock_ok = lock:find('sidekick%.nvim', 1, false) ~= nil
      local spec_ok = vim.fn.filereadable(vim.fn.stdpath('config') .. '/lua/plugins/ai.lua') == 1
      print(string.format('AI_MOD=%s AI_LOCK=%s AI_SPEC=%s', tostring(ok_mod), tostring(lock_ok), tostring(spec_ok)))
      vim.cmd('qa!')
    end, 3000)" \
  >"$ai_log" 2>"$WORKDIR/ai.err" || true
if ! grep -q 'AI_MOD=true' "$ai_log" || ! grep -q 'AI_LOCK=true' "$ai_log" || ! grep -q 'AI_SPEC=true' "$ai_log"; then
  fail_ai=1
  echo "ASSERT ai FAIL" >&2
  cat "$ai_log" >&2
fi

# --- 10) LSP support ---
lsp_log="$WORKDIR/lsp.log"
run_to 30 "$NVIM" --headless \
  +"lua vim.g.autoresearch_bench=true" \
  +"lua vim.defer_fn(function()
      local has_enable = type(vim.lsp.enable) == 'function'
      local configs = vim.fn.glob(vim.fn.stdpath('config') .. '/lsp/*.lua', false, true)
      local has_configs = #configs > 0
      local init = table.concat(vim.fn.readfile(vim.fn.stdpath('config') .. '/init.lua'), '\\n')
      local init_ok = init:find('vim%.lsp%.enable', 1, false) ~= nil
      print(string.format('LSP_ENABLE=%s LSP_CONFIGS=%s LSP_INIT=%s', tostring(has_enable), tostring(has_configs), tostring(init_ok)))
      vim.cmd('qa!')
    end, 2500)" \
  >"$lsp_log" 2>"$WORKDIR/lsp.err" || true
if ! grep -q 'LSP_ENABLE=true' "$lsp_log" || ! grep -q 'LSP_CONFIGS=true' "$lsp_log" || ! grep -q 'LSP_INIT=true' "$lsp_log"; then
  fail_lsp=1
  echo "ASSERT lsp FAIL" >&2
  cat "$lsp_log" >&2
fi

# --- Warm startup median (secondary) ---
times=()
for _ in 1 2 3; do
  t0="$(python3 -c 'import time; print(time.time())')"
  run_to 20 "$NVIM" --headless \
    +"lua vim.defer_fn(function() vim.cmd('qa!') end, 500)" \
    >/dev/null 2>&1 || true
  t1="$(python3 -c 'import time; print(time.time())')"
  ms="$(python3 -c "print(int(($t1-$t0)*1000))")"
  times+=("$ms")
done
IFS=$'\n' sorted=($(printf '%s\n' "${times[@]}" | sort -n))
startup_ms="${sorted[1]}"

compat_failures=$((fail_binary + fail_startup + fail_messages + fail_deprecated + fail_loadfile + fail_fixture_lua + fail_fixture_md + fail_vim_loop + fail_treesitter + fail_ai + fail_lsp))

echo "METRIC compat_failures=$compat_failures"
echo "METRIC startup_ms=$startup_ms"
echo "METRIC fail_binary=$fail_binary"
echo "METRIC fail_startup=$fail_startup"
echo "METRIC fail_messages=$fail_messages"
echo "METRIC fail_deprecated=$fail_deprecated"
echo "METRIC fail_loadfile=$fail_loadfile"
echo "METRIC fail_fixture_lua=$fail_fixture_lua"
echo "METRIC fail_fixture_md=$fail_fixture_md"
echo "METRIC fail_vim_loop=$fail_vim_loop"
echo "METRIC fail_treesitter=$fail_treesitter"
echo "METRIC fail_ai=$fail_ai"
echo "METRIC fail_lsp=$fail_lsp"
