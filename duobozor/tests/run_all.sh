#!/usr/bin/env bash
# duobozor/tests/run_all.sh
# ─────────────────────────────────────────────────────────────────────────────
#  Ҳамаи санҷишҳо якҷоя.  Иҷро:  bash duobozor/tests/run_all.sh
#
#  Пешниёзҳо:
#    pip install pglast            (танҳо барои тақсими дурусти SQL-ба-statement)
#    cd duobozor/tests && npm i    (pglite + typescript)
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail
cd "$(dirname "$0")"

RED=$'\033[31m'; GREEN=$'\033[32m'; DIM=$'\033[90m'; BOLD=$'\033[1m'; RST=$'\033[0m'
FAILED=0
declare -a RESULTS=()

run() {
  local name="$1"; shift
  printf '\n%s━━━ %s %s\n' "$BOLD" "$name" "$RST"
  if "$@"; then
    RESULTS+=("${GREEN}✓${RST} $name")
  else
    RESULTS+=("${RED}✗${RST} $name")
    FAILED=$((FAILED + 1))
  fi
}

# ── 0. Тайёр кардани statements.json (pglast — то функсияҳои $$ … $$ нашикананд)
printf '%s► Тайёрсозии statements.json%s\n' "$DIM" "$RST"
if python3 -c "import pglast" 2>/dev/null; then
  python3 - <<'PY'
import pglast, json, re, sys, pathlib
root = pathlib.Path(__file__).resolve().parent if False else pathlib.Path('.')
sql = (root / '..' / 'docs' / 'database.sql').read_text()
prep = []
for s in pglast.split(sql):
    s2 = re.sub(r'CREATE EXTENSION[^;]+;?', '', s, flags=re.I)
    s2 = re.sub(r'\bcitext\b', 'text', s2, flags=re.I)
    if re.search(r'gin_trgm_ops', s2, re.I):
        continue                      # pg_trgm дар PGlite нест
    s2 = s2.strip()
    if s2:
        prep.append(s2)
json.dump(prep, open(root / 'pg' / 'statements.json', 'w'), ensure_ascii=False)
print(f'  {len(prep)} statement омода шуд')
PY
else
  echo "  ${RED}pglast насб нест${RST}: pip install pglast"
  FAILED=$((FAILED + 1))
fi

run "1/6 · Схемаи база дар Postgres-и воқеӣ" node pg/run_schema.mjs
run "2/6 · Математикаи пул (escrow, ledger, refund)" python3 test_ledger.py
run "3/6 · Тасдиқи Telegram (HMAC, nonce, replay)" python3 test_telegram.py
run "4/6 · Outbox-и оффлайн (FIFO, backoff, 409)" node test_offline_queue.mjs
run "5/6 · Локализатсия (tj/ru parity)" python3 test_i18n.py
run "6/6 · Синтаксиси TypeScript + қоидаҳои код" node ts_syntax.mjs

printf '\n%s%s%s\n' "$BOLD" "══════════════════════════════════════════════════════════════════" "$RST"
printf '%s  ҲУЛОСА%s\n' "$BOLD" "$RST"
for r in "${RESULTS[@]}"; do printf '   %b\n' "$r"; done
if [ "$FAILED" -eq 0 ]; then
  printf '\n   %s%s✓ ҲАМАИ 6 ГУРӮҲ САНҶИШ ГУЗАШТ%s\n' "$GREEN" "$BOLD" "$RST"
else
  printf '\n   %s%s✗ %d гурӯҳ ноком%s\n' "$RED" "$BOLD" "$FAILED" "$RST"
fi
printf '%s══════════════════════════════════════════════════════════════════%s\n' "$BOLD" "$RST"
exit "$FAILED"
