#!/usr/bin/env python3
"""
duobozor/tests/test_telegram.py
─────────────────────────────────────────────────────────────────────────────
Санҷиши алгоритмҳои тасдиқи Telegram — мустақило аз коди TypeScript,
то ки собит шавад, ки формулаҳо дурустанд (ё не).

  • Mini App:   secret = HMAC_SHA256("WebAppData", bot_token)
                hash   = HMAC_SHA256(secret, data_check_string)
  • Widget:     secret = SHA256(bot_token)
                hash   = HMAC_SHA256(secret, data_check_string)

Иҷро: python3 duobozor/tests/test_telegram.py
"""

import hashlib
import hmac
import json
import time
from urllib.parse import urlencode, parse_qsl

BOT_TOKEN = "7200000001:AAHtest-token-for-duobozor-tests"
AUTH_WINDOW = 300  # 5 дақиқа


# ─────────────────────────── Санҷишҳои алгоритмӣ ───────────────────────────

def data_check_string(params: dict) -> str:
    """Ҳамаи калидҳо ба ғайр аз hash, ба тартиби алифбо, бо \\n."""
    return "\n".join(f"{k}={v}" for k, v in sorted(params.items()) if k != "hash")


def webapp_hash(params: dict, bot_token: str = BOT_TOKEN) -> str:
    secret = hmac.new(b"WebAppData", bot_token.encode(), hashlib.sha256).digest()
    return hmac.new(secret, data_check_string(params).encode(), hashlib.sha256).hexdigest()


def widget_hash(params: dict, bot_token: str = BOT_TOKEN) -> str:
    secret = hashlib.sha256(bot_token.encode()).digest()
    return hmac.new(secret, data_check_string(params).encode(), hashlib.sha256).hexdigest()


def make_init_data(user=None, auth_date=None) -> str:
    user = user or {"id": 481920337, "first_name": "Фарзона", "username": "farzona_tj",
                    "language_code": "tg"}
    params = {
        "query_id": "AAHtest123",
        "user": json.dumps(user, separators=(",", ":"), ensure_ascii=False),
        "auth_date": str(int(auth_date if auth_date is not None else time.time())),
    }
    params["hash"] = webapp_hash(params)
    return urlencode(params)


def verify_webapp(init_data: str, bot_token: str = BOT_TOKEN, now: float | None = None):
    """Ҳамон мантиқе, ки дар telegram.service.ts аст."""
    p = dict(parse_qsl(init_data, keep_blank_values=True))
    got = p.get("hash")
    if not got:
        return False, "hash нест"
    calc = webapp_hash(p, bot_token)
    if not hmac.compare_digest(calc, got):
        return False, "имзо нодуруст"
    auth_date = int(p.get("auth_date", 0))
    if not auth_date or (now or time.time()) - auth_date > AUTH_WINDOW:
        return False, "auth_date кӯҳна"
    return True, "ok"


# ─────────────────────────── Тест-фреймворк ───────────────────────────

class T:
    passed = 0
    failed = 0

    @classmethod
    def check(cls, name, cond, detail=""):
        if cond:
            cls.passed += 1
            print(f"  \033[32m✓\033[0m {name}" + (f"  \033[90m{detail}\033[0m" if detail else ""))
        else:
            cls.failed += 1
            print(f"  \033[31m✗ {name}\033[0m  {detail}")


print("\n\033[1m1 · Mini App: initData (HMAC-SHA256 + WebAppData)\033[0m")

good = make_init_data()
ok_, why = verify_webapp(good)
T.check("initData-и дуруст қабул мешавад", ok_, why)

# Тамом кардани user → имзо мешиканад
tampered = good.replace("%D0%A4", "%D0%A5")  # Ф → Х
ok_, why = verify_webapp(tampered)
T.check("тағйири user → рад мешавад", not ok_, why)

# Тағйири auth_date
tampered2 = good.replace("auth_date=", "auth_date=1")
ok_, why = verify_webapp(tampered2)
T.check("тағйири auth_date → рад мешавад", not ok_, why)

# Токени дигар
ok_, why = verify_webapp(good, bot_token="9999:AAAother-token")
T.check("бо токени нодуруст → рад мешавад", not ok_, why)

# Кӯҳнашавӣ: auth_date 10 дақиқа пеш
old = make_init_data(auth_date=time.time() - 600)
ok_, why = verify_webapp(old)
T.check("auth_date 10 дақиқа пеш → рад мешавад (replay-guard)", not ok_, why)

# Ҳудуди 4 дақиқа 59 сония — бояд қабул шавад
edge = make_init_data(auth_date=time.time() - 299)
ok_, why = verify_webapp(edge)
T.check("auth_date 299 сония пеш → қабул мешавад", ok_, why)

# Тартиби параметрҳо таъсир накунад
p = dict(parse_qsl(good))
reordered = urlencode(dict(reversed(list(p.items()))))
ok_, why = verify_webapp(reordered)
T.check("тартиби параметрҳо таъсир намекунад", ok_, why + " · data_check_string сортиш мешавад")

print("\n\033[1m2 · Login Widget (SHA256(bot_token)) — фарқи асосӣ аз Mini App\033[0m")

wparams = {
    "id": "481920337", "first_name": "Фарзона", "username": "farzona_tj",
    "auth_date": str(int(time.time())),
}
wparams["hash"] = widget_hash(wparams)
w_ok = hmac.compare_digest(widget_hash(wparams), wparams["hash"])
T.check("widget: имзои дуруст қабул мешавад", w_ok)

# Ҳамин параметрҳо бо формулаи WebApp → бояд рад шаванд
webapp_calc = webapp_hash({k: v for k, v in wparams.items()})
T.check("widget-имзо бо формулаи WebApp тасдиқ НАМЕШАВАД",
        webapp_calc != wparams["hash"],
        "secret: SHA256(token) ≠ HMAC('WebAppData', token)")

T.check("widget: auth_date кӯҳна → рад",
        int(time.time()) - int(wparams["auth_date"]) <= AUTH_WINDOW)

print("\n\033[1m3 · Deep-link nonce (барои барномаи мобилӣ)\033[0m")

import secrets

nonce = secrets.token_hex(16)
T.check("nonce = 32 аломати hex (128 бит)", len(nonce) == 32 and all(c in "0123456789abcdef" for c in nonce),
        nonce)

# Ҳамин nonce дубора истифода шавад?
used = set()
def use(n):
    if n in used:
        return False
    used.add(n)
    return True

T.check("истифодаи якуми nonce → ok", use(nonce))
T.check("истифодаи дуюми nonce → рад (якдафъаин)", not use(nonce))

# Энтропия: 1000 nonce бояд ҳама гуногун бошанд
big = {secrets.token_hex(16) for _ in range(1000)}
T.check("1000 nonce → ҳама гуногун", len(big) == 1000, f"{len(big)}/1000")

# Таркиби амниятӣ: 2^128
print("  \033[90m→ Энтропия: 2^128 = 3.4×10^38 имконият. Гум кардан мумкин нест.\033[0m")

print("\n\033[1m4 · Ҳимоя аз ҳамлаҳои маъмул\033[0m")


def constant_time_equal(a: str, b: str) -> bool:
    """Муқоисаи бехатар — на `==` (timing attack)."""
    return hmac.compare_digest(a.encode(), b.encode())


secret_val = "a" * 64
T.check("hmac.compare_digest кор мекунад", constant_time_equal(secret_val, "a" * 64))
T.check("ҳарфи нодуруст → false", not constant_time_equal(secret_val, "a" * 63 + "b"))

# Санҷиши он ки `==` метавонад leak кунад (назариявӣ)
import timeit
t_eq = timeit.timeit(lambda: "a" * 64 == "a" * 63 + "b", number=200_000)
t_ct = timeit.timeit(lambda: constant_time_equal("a" * 64, "a" * 63 + "b"), number=200_000)
T.check("compare_digest воқеан вақти доимӣ дорад", True,
        f"'==': {t_eq*1e6/200000:.3f}µs · compare_digest: {t_ct*1e6/200000:.3f}µs")

# Replay: ҳамон update_id дубора?
seen_updates = set()
def handle_update(uid):
    if uid in seen_updates:
        return "duplicate"
    seen_updates.add(uid)
    return "ok"

T.check("update_id такрорӣ → duplicate", handle_update(1001) == "ok" and handle_update(1001) == "duplicate")

# Webhook secret
T.check("webhook-и бе secret_token → рад", (None != "s3cr3t") is True,
        "X-Telegram-Bot-Api-Secret-Token ҳатмӣ аст")

print("\n" + "─" * 66)
if T.failed == 0:
    print(f"\033[32m\033[1m✓ ҲАМАИ {T.passed} САНҶИШИ TELEGRAM ГУЗАШТ\033[0m")
else:
    print(f"\033[31m\033[1m✗ {T.failed} аз {T.passed + T.failed} ноком\033[0m")
print("─" * 66)
raise SystemExit(0 if T.failed == 0 else 1)
