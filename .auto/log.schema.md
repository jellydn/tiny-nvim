# `.auto/log.jsonl` record schema (schema_version 1)

Historical and current experiment logs use **three** JSONL record shapes. Do not
infer a reduced check set from older rows that omit fields.

## Common

| Field | Meaning |
| --- | --- |
| `schema_version` | Integer contract version. **1** = this document. Optional on historical rows. |
| `event` | Present on `init` / early `result` only |
| `run` | Present on full iteration `run` records |

When writing new records (harness / `log_experiment`), include `schema_version: 1`.

## `init`

Metadata for the session (goal, branch, prompt hash). Not a metrics row.

## `result` (early / partial)

May include only a **subset** of `fail_*` keys (e.g. treesitter/ai/lsp/miniai).
`compat_failures: 0` on a partial `result` does **not** mean every check in
`measure.sh` was green.

## `run` (full iteration)

Full secondary metric set from `./.auto/measure.sh`, including at least:

`fail_binary`, `fail_startup`, `fail_messages`, `fail_deprecated`, `fail_loadfile`,
`fail_fixture_lua`, `fail_fixture_md`, `fail_vim_loop`, `fail_treesitter`,
`fail_ai`, `fail_lsp`, `fail_miniai`, plus `compat_failures` and `startup_ms`.

Treat `status: keep|discard` as the experiment decision for that run.
