#!/usr/bin/env bash
# duobozor/scripts/notify.sh — паём ба админ аз терминал
#   usage: TELEGRAM_BOT_TOKEN=xxx ADMIN_CHAT_ID=8075805186 ./notify.sh "Матн"
set -euo pipefail
TOKEN="${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN лозим аст}"
CHAT="${ADMIN_CHAT_ID:-8075805186}"
TEXT="${1:-DuoBozor: тест}"

curl -sS -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
  -H 'content-type: application/json' \
  -d "$(python3 -c 'import json,sys;print(json.dumps({"chat_id":sys.argv[1],"text":sys.argv[2],"parse_mode":"HTML"}))' "$CHAT" "$TEXT")"
echo
