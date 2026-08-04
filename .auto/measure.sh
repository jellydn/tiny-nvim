#!/usr/bin/env bash
# Frozen Neovim 0.13 compatibility benchmark. Do not soften assertions after baseline.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Prefer uv tool bins (ty/ruff) over shadowed Homebrew stubs on PATH
export PATH="${HOME}/.local/bin:${PATH}"

# Prefer NVIM_BIN; otherwise resolve `nvim` from PATH (portable across hosts/CI).
NVIM="${NVIM_BIN:-$(command -v nvim 2>/dev/null || true)}"
if [[ -z "$NVIM" || ! -x "$NVIM" ]]; then
  echo "nvim not found on PATH; set NVIM_BIN to a Neovim 0.13 binary" >&2
  exit 1
fi
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
fail_miniai=0

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

# --- 2) Normal headless startup ---
startup_mark="$WORKDIR/startup.ok"
run_to 30 "$NVIM" --headless \
  +"lua vim.g.autoresearch_bench=true" \
  +"lua vim.defer_fn(function() vim.fn.writefile({'STARTUP_OK'}, [[$startup_mark]]); vim.cmd('qa!') end, 2500)" \
  >"$WORKDIR/startup.log" 2>"$WORKDIR/startup.err" || true
if [[ ! -f "$startup_mark" ]]; then
  fail_startup=1
  echo "ASSERT startup FAIL" >&2
  tail -n 40 "$WORKDIR/startup.err" >&2 || true
fi

# --- 3) Startup messages: no hard errors / tracebacks / deprecation warnings ---
msg_file="$WORKDIR/messages.txt"
run_to 30 "$NVIM" --headless \
  +"lua vim.g.autoresearch_bench=true" \
  +"lua vim.defer_fn(function() local o=vim.api.nvim_exec2('messages',{output=true}).output; vim.fn.writefile(vim.split(o, '\\n', {plain=true}), [[$msg_file]]); vim.cmd('qa!') end, 3000)" \
  >"$WORKDIR/messages.log" 2>"$WORKDIR/messages.err" || true
# Exact missing-workspace tooling signatures (environment noise only).
# Keep narrow: any other TS/Rust init error still fails fail_messages.
ENV_LSP_NOISE='TypeScript installation|rust-analyzer quit|tsserver|Could not find a valid TypeScript'
if [[ -f "$msg_file" ]]; then
  filtered="$(grep -Eiv "$ENV_LSP_NOISE" "$msg_file" || true)"
  if echo "$filtered" | grep -Eiq 'E[0-9]{3,}:|stack traceback|is deprecated|Can not get query|error_treesitter'; then
    fail_messages=1
    echo "ASSERT messages FAIL" >&2
    echo "$filtered" | head -n 40 >&2
  fi
fi

# --- 4) vim.deprecated health buffer ---
dep_file="$WORKDIR/deprecated.txt"
run_to 35 "$NVIM" --headless \
  +"checkhealth vim.deprecated" \
  +"lua vim.fn.writefile(vim.api.nvim_buf_get_lines(0,0,-1,false), [[$dep_file]])" \
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

# --- 5) loadfile all tracked lua (separate globs; brace expansion is invalid here) ---
load_mark="$WORKDIR/load.txt"
run_to 25 "$NVIM" --headless -u NONE \
  +"lua local root=[[$ROOT]]; local bad=0; local files={}; for _,pat in ipairs({root..'/init.lua', root..'/lua/**/*.lua', root..'/lsp/*.lua'}) do for _,p in ipairs(vim.fn.glob(pat, false, true)) do table.insert(files,p) end end; for _,p in ipairs(files) do local ok,err=loadfile(p); if not ok then bad=bad+1; vim.fn.writefile({('LOAD_FAIL '..p..' :: '..tostring(err))}, [[$load_mark]], 'a') end end; vim.fn.writefile({'LOAD_FAILS='..bad}, [[$load_mark]], 'a'); vim.cmd('qa!')" \
  >"$WORKDIR/load.log" 2>"$WORKDIR/load.err" || true
load_fails="$(grep -E '^LOAD_FAILS=' "$load_mark" 2>/dev/null | tail -n1 | cut -d= -f2 || echo 1)"
load_fails="${load_fails:-1}"
if [[ "$load_fails" != "0" ]]; then
  fail_loadfile=1
  echo "ASSERT loadfile FAIL count=$load_fails" >&2
  grep 'LOAD_FAIL ' "$load_mark" >&2 || true
fi

# --- 6) Fixture opens (lua + markdown only) ---
ft_lua="$WORKDIR/ft_lua.txt"
run_to 30 "$NVIM" --headless "$FIX/sample.lua" \
  +"lua vim.defer_fn(function() vim.fn.writefile({'FT='..vim.bo.filetype}, [[$ft_lua]]); vim.cmd('qa!') end, 2000)" \
  >"$WORKDIR/ft_lua.log" 2>"$WORKDIR/ft_lua.err" || true
if ! grep -q 'FT=lua' "$ft_lua" 2>/dev/null; then
  fail_fixture_lua=1
  echo "ASSERT fixture_lua FAIL" >&2
fi

ft_md="$WORKDIR/ft_md.txt"
run_to 30 "$NVIM" --headless "$FIX/sample.md" \
  +"lua vim.defer_fn(function() vim.fn.writefile({'FT='..vim.bo.filetype}, [[$ft_md]]); vim.cmd('qa!') end, 2000)" \
  >"$WORKDIR/ft_md.log" 2>"$WORKDIR/ft_md.err" || true
if ! grep -q 'FT=markdown' "$ft_md" 2>/dev/null; then
  fail_fixture_md=1
  echo "ASSERT fixture_md FAIL" >&2
fi

# --- 7) Static policy: bare vim.loop (not vim.uv or vim.loop fallbacks) ---
loop_hits="$(rg -n --glob '!.auto/**' --glob '!.git/**' 'vim\.loop\.' "$ROOT" \
  | grep -v 'vim\.uv or vim\.loop' \
  || true)"
loop_count="$(printf '%s\n' "$loop_hits" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "${loop_count:-0}" -gt 0 ]]; then
  fail_vim_loop=1
  echo "ASSERT vim_loop FAIL ($loop_count direct uses):" >&2
  echo "$loop_hits" >&2
fi

# --- 8) Treesitter support ---
ts_mark="$WORKDIR/ts.txt"
run_to 35 "$NVIM" --headless \
  +"lua vim.g.autoresearch_bench=true" \
  +"lua vim.defer_fn(function()
      local ok_mod = pcall(require, 'nvim-treesitter')
      local has_api = vim.treesitter ~= nil and type(vim.treesitter.start) == 'function'
      local lock = table.concat(vim.fn.readfile(vim.fn.stdpath('config') .. '/lazy-lock.json'), '\\n')
      local lock_ok = lock:find('nvim%-treesitter', 1, false) ~= nil
      local to_ok = lock:find('nvim%-treesitter%-textobjects', 1, false) ~= nil
      vim.fn.writefile({string.format('TS_MOD=%s TS_API=%s TS_LOCK=%s TS_TEXTOBJ_LOCK=%s', tostring(ok_mod), tostring(has_api), tostring(lock_ok), tostring(to_ok))}, [[$ts_mark]])
      vim.cmd('qa!')
    end, 3500)" \
  >"$WORKDIR/ts.log" 2>"$WORKDIR/ts.err" || true
if ! grep -q 'TS_MOD=true' "$ts_mark" 2>/dev/null \
  || ! grep -q 'TS_API=true' "$ts_mark" 2>/dev/null \
  || ! grep -q 'TS_LOCK=true' "$ts_mark" 2>/dev/null \
  || ! grep -q 'TS_TEXTOBJ_LOCK=true' "$ts_mark" 2>/dev/null; then
  fail_treesitter=1
  echo "ASSERT treesitter FAIL" >&2
  cat "$ts_mark" 2>/dev/null >&2 || true
fi

# --- 9) AI (sidekick) support ---
ai_mark="$WORKDIR/ai.txt"
run_to 35 "$NVIM" --headless \
  +"lua vim.g.autoresearch_bench=true" \
  +"lua vim.defer_fn(function()
      local ok_mod = pcall(require, 'sidekick')
      local lock = table.concat(vim.fn.readfile(vim.fn.stdpath('config') .. '/lazy-lock.json'), '\\n')
      local lock_ok = lock:find('sidekick%.nvim', 1, false) ~= nil
      local spec_ok = vim.fn.filereadable(vim.fn.stdpath('config') .. '/lua/plugins/ai.lua') == 1
      vim.fn.writefile({string.format('AI_MOD=%s AI_LOCK=%s AI_SPEC=%s', tostring(ok_mod), tostring(lock_ok), tostring(spec_ok))}, [[$ai_mark]])
      vim.cmd('qa!')
    end, 3500)" \
  >"$WORKDIR/ai.log" 2>"$WORKDIR/ai.err" || true
if ! grep -q 'AI_MOD=true' "$ai_mark" 2>/dev/null \
  || ! grep -q 'AI_LOCK=true' "$ai_mark" 2>/dev/null \
  || ! grep -q 'AI_SPEC=true' "$ai_mark" 2>/dev/null; then
  fail_ai=1
  echo "ASSERT ai FAIL" >&2
  cat "$ai_mark" 2>/dev/null >&2 || true
fi

# --- 10) LSP support (config load + smoke client attach on temp fixtures) ---
# Temp fixtures live under WORKDIR (do not mutate frozen .auto/fixtures/).
lsp_ws="$WORKDIR/lsp_ws"
mkdir -p "$lsp_ws/rustproj/src" "$lsp_ws/tsproj"
printf '%s\n' 'local x = 1' 'return x' >"$lsp_ws/a.lua"
printf '%s\n' '{"a":1}' >"$lsp_ws/a.json"
printf '%s\n' 'x = 1' >"$lsp_ws/a.py"
: >"$lsp_ws/pyproject.toml"
printf '%s\n' 'package main' 'func main() {}' >"$lsp_ws/main.go"
printf '%s\n' '[package]' 'name = "probe"' 'version = "0.1.0"' 'edition = "2021"' >"$lsp_ws/rustproj/Cargo.toml"
printf '%s\n' 'fn main() {}' >"$lsp_ws/rustproj/src/main.rs"
printf '%s\n' '{"name":"probe","private":true}' >"$lsp_ws/tsproj/package.json"
printf '%s\n' 'const x: number = 1' >"$lsp_ws/tsproj/a.ts"
printf '%s\n' 'const z = 1' >"$lsp_ws/a.js"
printf '%s\n' '.x { color: red; }' >"$lsp_ws/a.css"
# Linter config markers for attach smoke (mirrors smart detect)
printf '%s\n' '{}' >"$lsp_ws/biome.json"
printf '%s\n' '{}' >"$lsp_ws/.oxlintrc.json"
printf '%s\n' 'export default [];' >"$lsp_ws/eslint.config.js"
# Prefer workspace typescript@5 for ts_ls when global TS7 lacks tsserver.js
if command -v npm >/dev/null 2>&1; then
  (cd "$lsp_ws/tsproj" && npm install --no-fund --no-audit --silent typescript@5.9.3) >/dev/null 2>&1 || true
fi

lsp_mark="$WORKDIR/lsp.txt"
run_to 120 "$NVIM" --headless \
  +"lua vim.g.autoresearch_bench=true" \
  +"lua vim.defer_fn(function()
      local has_enable = type(vim.lsp.enable) == 'function'
      local configs = vim.fn.glob(vim.fn.stdpath('config') .. '/lsp/*.lua', false, true)
      table.sort(configs)
      local has_configs = #configs > 0
      local init = table.concat(vim.fn.readfile(vim.fn.stdpath('config') .. '/init.lua'), '\\n')
      local init_ok = init:find('vim%.lsp%.enable', 1, false) ~= nil
      local bad, details = 0, {}
      for _, p in ipairs(configs) do
        local name = vim.fn.fnamemodify(p, ':t:r')
        local cfg = vim.lsp.config[name]
        if type(cfg) ~= 'table' or type(cfg.cmd) ~= 'table' or not cfg.cmd[1] then
          bad = bad + 1
          table.insert(details, name)
        else
          pcall(vim.lsp.enable, name)
        end
      end
      local all_ok = bad == 0

      -- Smoke-attach: open a temp fixture and wait for client.initialized
      local ws = [[$lsp_ws]]
      local fixtures = {
        lua_ls = { path = ws .. '/a.lua', ft = 'lua' },
        json = { path = ws .. '/a.json', ft = 'json' },
        biome = { path = ws .. '/a.json', ft = 'json' },
        ty = { path = ws .. '/a.py', ft = 'python' },
        ruff = { path = ws .. '/a.py', ft = 'python' },
        gopls = { path = ws .. '/main.go', ft = 'go' },
        ['rust-analyzer'] = { path = ws .. '/rustproj/src/main.rs', ft = 'rust' },
        ts_ls = { path = ws .. '/tsproj/a.ts', ft = 'typescript' },
        vtsls = { path = ws .. '/tsproj/a.ts', ft = 'typescript' },
        oxlint = { path = ws .. '/a.js', ft = 'javascript' },
        eslint = { path = ws .. '/a.js', ft = 'javascript' },
        tailwindcss = { path = ws .. '/a.css', ft = 'css' },
      }
      local function wait_attach(name, timeout_ms)
        local t0 = vim.uv.hrtime()
        while (vim.uv.hrtime() - t0) / 1e6 < timeout_ms do
          for _, c in ipairs(vim.lsp.get_clients({ name = name })) do
            if c.initialized then return true end
          end
          vim.wait(50)
        end
        return false
      end
      local attach_fail, attach_skip, attach_ok = 0, 0, 0
      local attach_ok_names, attach_fail_names, attach_skip_names = {}, {}, {}
      for _, p in ipairs(configs) do
        local name = vim.fn.fnamemodify(p, ':t:r')
        local cfg = vim.lsp.config[name]
        local fx = fixtures[name]
        if type(cfg) ~= 'table' or type(cfg.cmd) ~= 'table' or not cfg.cmd[1] then
          -- already counted in bad
        elseif vim.fn.executable(cfg.cmd[1]) ~= 1 then
          attach_skip = attach_skip + 1
          table.insert(attach_skip_names, name .. ':no_bin')
        elseif not fx then
          attach_skip = attach_skip + 1
          table.insert(attach_skip_names, name .. ':no_fixture')
        else
          for _, c in ipairs(vim.lsp.get_clients({ name = name })) do
            pcall(function() c:stop(true) end)
          end
          pcall(vim.lsp.enable, name)
          pcall(vim.cmd.edit, fx.path)
          vim.bo.filetype = fx.ft
          pcall(vim.lsp.enable, name)
          if wait_attach(name, 10000) then
            attach_ok = attach_ok + 1
            table.insert(attach_ok_names, name)
          else
            attach_fail = attach_fail + 1
            table.insert(attach_fail_names, name)
          end
          for _, c in ipairs(vim.lsp.get_clients({ name = name })) do
            pcall(function() c:stop(true) end)
          end
          pcall(vim.cmd.bwipeout, '!')
        end
      end
      local attach_ok_flag = attach_fail == 0
      vim.fn.writefile({
        string.format('LSP_ENABLE=%s LSP_CONFIGS=%s LSP_INIT=%s LSP_ALL_OK=%s LSP_BAD=%d', tostring(has_enable), tostring(has_configs), tostring(init_ok), tostring(all_ok), bad),
        'LSP_BAD_NAMES=' .. table.concat(details, ','),
        string.format('LSP_ATTACH_OK=%s LSP_ATTACH_N=%d LSP_ATTACH_FAIL=%d LSP_ATTACH_SKIP=%d', tostring(attach_ok_flag), attach_ok, attach_fail, attach_skip),
        'LSP_ATTACH_OK_NAMES=' .. table.concat(attach_ok_names, ','),
        'LSP_ATTACH_FAIL_NAMES=' .. table.concat(attach_fail_names, ','),
        'LSP_ATTACH_SKIP_NAMES=' .. table.concat(attach_skip_names, ','),
      }, [[$lsp_mark]])
      vim.cmd('qa!')
    end, 2500)" \
  >"$WORKDIR/lsp.log" 2>"$WORKDIR/lsp.err" || true
# Always surface attach smoke report (pass or fail)
if [[ -f "$lsp_mark" ]]; then
  echo "=== LSP attach smoke ===" >&2
  cat "$lsp_mark" >&2 || true
fi
if ! grep -q 'LSP_ENABLE=true' "$lsp_mark" 2>/dev/null \
  || ! grep -q 'LSP_CONFIGS=true' "$lsp_mark" 2>/dev/null \
  || ! grep -q 'LSP_INIT=true' "$lsp_mark" 2>/dev/null \
  || ! grep -q 'LSP_ALL_OK=true' "$lsp_mark" 2>/dev/null \
  || ! grep -q 'LSP_ATTACH_OK=true' "$lsp_mark" 2>/dev/null; then
  fail_lsp=1
  echo "ASSERT lsp FAIL" >&2
  tail -n 40 "$WORKDIR/lsp.err" 2>/dev/null >&2 || true
fi

# Emit attach counts as secondary METRIC-friendly diagnostics (parsed via METRIC lines later)
if [[ -f "$lsp_mark" ]]; then
  attach_n="$(sed -n 's/.*LSP_ATTACH_N=\([0-9]*\).*/\1/p' "$lsp_mark" | head -1)"
  attach_fail_n="$(sed -n 's/.*LSP_ATTACH_FAIL=\([0-9]*\).*/\1/p' "$lsp_mark" | head -1)"
  attach_skip_n="$(sed -n 's/.*LSP_ATTACH_SKIP=\([0-9]*\).*/\1/p' "$lsp_mark" | head -1)"
  : "${attach_n:=0}" "${attach_fail_n:=0}" "${attach_skip_n:=0}"
fi

# --- 11) mini.ai treesitter textobjects for lua (the user-reported failure) ---
ai_to="$WORKDIR/miniai.txt"
run_to 40 "$NVIM" --headless "$FIX/sample.lua" \
  +"lua vim.g.autoresearch_bench=true" \
  +"lua vim.defer_fn(function()
      -- Ensure VeryLazy plugins (mini.ai + textobjects) are loaded
      pcall(function() require('lazy').load({ plugins = { 'mini.ai', 'nvim-treesitter-textobjects' } }) end)
      vim.defer_fn(function()
        local files = vim.treesitter.query.get_files('lua', 'textobjects') or {}
        local query = vim.treesitter.query.get('lua', 'textobjects')
        local ok_ai, err = pcall(function()
          require('mini.ai')
          -- Attempt function textobject selection; must not raise query error
          vim.cmd('normal! gg')
          require('mini.ai').select_textobject('a', 'f', { n_times = 1, search_method = 'cover_or_next' })
        end)
        local msg = tostring(err or '')
        local query_err = msg:find('Can not get query', 1, true) ~= nil or msg:find('error_treesitter', 1, true) ~= nil
        vim.fn.writefile({
          string.format('MINIAI_QUERY_FILES=%d', #files),
          string.format('MINIAI_HAS_QUERY=%s', tostring(query ~= nil)),
          string.format('MINIAI_SELECT_OK=%s', tostring(ok_ai)),
          string.format('MINIAI_QUERY_ERR=%s', tostring(query_err)),
          'MINIAI_ERR=' .. msg:gsub('\\n', ' | '),
        }, [[$ai_to]])
        vim.cmd('qa!')
      end, 1500)
    end, 2500)" \
  >"$WORKDIR/miniai.log" 2>"$WORKDIR/miniai.err" || true
if ! grep -q 'MINIAI_HAS_QUERY=true' "$ai_to" 2>/dev/null \
  || ! grep -q 'MINIAI_QUERY_ERR=false' "$ai_to" 2>/dev/null; then
  fail_miniai=1
  echo "ASSERT miniai FAIL" >&2
  cat "$ai_to" 2>/dev/null >&2 || true
  tail -n 30 "$WORKDIR/miniai.err" 2>/dev/null >&2 || true
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
sorted=()
while IFS= read -r line; do
  sorted+=("$line")
done < <(printf '%s\n' "${times[@]}" | sort -n)
startup_ms="${sorted[1]}"

compat_failures=$((fail_binary + fail_startup + fail_messages + fail_deprecated + fail_loadfile + fail_fixture_lua + fail_fixture_md + fail_vim_loop + fail_treesitter + fail_ai + fail_lsp + fail_miniai))

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
echo "METRIC fail_miniai=$fail_miniai"
