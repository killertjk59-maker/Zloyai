#!/usr/bin/env bash
# End-to-end smoke test against a running ZLOY.AI backend.
#
#   ./scripts/smoke_test.sh                        # http://127.0.0.1:8000
#   ./scripts/smoke_test.sh https://my.host.example
#
# Exits non-zero on the first failure. Prints response bodies, never secrets.
set -euo pipefail

BASE="${1:-http://127.0.0.1:8000}"
BASE="${BASE%/}"
fail=0

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }

check_status() {
  local label="$1" expected="$2" method="$3" path="$4" data="${5:-}"
  local body status
  if [[ -n "$data" ]]; then
    body=$(curl -sS -o /tmp/zloy_body.json -w '%{http_code}' -X "$method" \
      -H 'Content-Type: application/json' -d "$data" "$BASE$path")
  else
    body=$(curl -sS -o /tmp/zloy_body.json -w '%{http_code}' -X "$method" "$BASE$path")
  fi
  status="$body"
  if [[ "$status" == "$expected" ]]; then
    printf '  \033[32mPASS\033[0m %-42s %s\n' "$label" "$status"
  else
    printf '  \033[31mFAIL\033[0m %-42s got %s, expected %s\n' "$label" "$status" "$expected"
    head -c 400 /tmp/zloy_body.json; echo
    fail=1
  fi
}

say "1. Health"
check_status "GET /api/v1/health" 200 GET /api/v1/health
python3 - <<'PY' || fail=1
import json, sys
body = json.load(open("/tmp/zloy_body.json"))
required = {"status", "provider", "model", "mock"}
missing = required - body.keys()
if missing:
    print(f"  FAIL health payload missing: {sorted(missing)}"); sys.exit(1)
print(f"  provider={body['provider']} model={body['model']} mock={body['mock']}")
if body["mock"]:
    print("  note: running the deterministic mock provider (no OpenRouter key).")
PY

say "2. Correct a sentence (Tajik explanation)"
check_status "POST /api/v1/tutor/correct" 200 POST /api/v1/tutor/correct \
  '{"text":"She go to school.","explanation_language":"tg","personality":"strict"}'
python3 - <<'PY' || fail=1
import json, sys
body = json.load(open("/tmp/zloy_body.json"))
correction = body.get("correction") or {}
if correction.get("corrected") != "She goes to school.":
    print(f"  FAIL unexpected correction: {correction.get('corrected')!r}"); sys.exit(1)
if not correction.get("explanation"):
    print("  FAIL correction has no explanation"); sys.exit(1)
print(f"  corrected: {correction['corrected']}")
PY

say "3. Chat with a mistake (Russian explanation, roast + profanity)"
check_status "POST /api/v1/tutor/chat" 200 POST /api/v1/tutor/chat \
  '{"message":"My brother play football.","explanation_language":"ru","personality":"roast","profanity":true}'

say "4. Clean sentence must NOT produce an invented correction"
check_status "POST /api/v1/tutor/correct (clean)" 200 POST /api/v1/tutor/correct \
  '{"text":"I went to the market yesterday.","explanation_language":"en"}'
python3 - <<'PY' || fail=1
import json, sys
body = json.load(open("/tmp/zloy_body.json"))
if body.get("correction") is not None:
    print("  FAIL a clean sentence was 'corrected' anyway"); sys.exit(1)
print("  correction is null, as it should be")
PY

say "5. Validation errors are typed"
check_status "POST /api/v1/tutor/chat (empty)" 422 POST /api/v1/tutor/chat '{"message":"   "}'

say "6. Free-model discovery (needs internet)"
if curl -sS -m 20 -o /tmp/zloy_models.json -w '%{http_code}' "$BASE/api/v1/models/free" | grep -q 200; then
  python3 - <<'PY'
import json
body = json.load(open("/tmp/zloy_models.json"))
print(f"  {body['count']} zero-priced models listed at {body['checked_at']}")
for model in body["models"][:5]:
    print(f"   - {model['id']}")
PY
else
  echo "  SKIP (no outbound network from the server, or rate limited by OpenRouter)"
fi

if [[ "$fail" -ne 0 ]]; then
  printf '\n\033[31mSmoke test FAILED\033[0m\n'; exit 1
fi
printf '\n\033[32mAll smoke checks passed\033[0m against %s\n' "$BASE"
