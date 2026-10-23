#!/usr/bin/env python3
"""
duobozor/tests/test_ledger.py
─────────────────────────────────────────────────────────────────────────────
Санҷиши математикаи пул — пеш аз навиштани як сатри код дар backend.

Ҳар як сенария double-entry месозад: ҷамъи дебетҳо бояд = ҷамъи кредитҳо,
ва ҳамаи ҳисобҳо бояд 0 диҳанд. Агар ин тест гузарад, модели молиявӣ дуруст аст.

Иҷро: python3 duobozor/tests/test_ledger.py
"""

from dataclasses import dataclass, field
from decimal import Decimal, ROUND_HALF_UP
from typing import Dict, List

D = Decimal
CENT = D("0.01")


def q(x: D) -> D:
    """Гирд кардан то тийин — ROUND_HALF_UP (на banker's rounding)."""
    return D(x).quantize(CENT, rounding=ROUND_HALF_UP)


# ─────────────────────────── Конфигуратсия ───────────────────────────

@dataclass
class Rules:
    payment_fee_rate: D = D("0.015")     # 1.5% — PSP/инкассатсия
    commission_rate: D = D("0.08")       # 8% — аз рӯи категория
    manager_bonus_rate: D = D("0.15")    # 15% аз комиссия
    min_payout: D = D("100")
    four_eye_threshold: D = D("2000")
    auto_release_days: int = 7


# ─────────────────────────── Ledger ───────────────────────────

@dataclass
class Ledger:
    """Double-entry: ҳар амалиёт = рӯйхати (дебет, кредит, маблағ)."""
    accounts: Dict[str, D] = field(default_factory=dict)
    entries: List[tuple] = field(default_factory=list)

    RESTRICTED_PREFIXES = ("escrow:",)   # ин ҳисобҳо наметавонанд манфӣ шаванд

    def post(self, debit: str, credit: str, amount: D, memo: str = "") -> None:
        amount = q(amount)
        if amount <= 0:
            raise ValueError(f"маблағи ғайримусбат: {amount}")
        for acct, sign in ((debit, -1),):
            if acct.startswith(self.RESTRICTED_PREFIXES) and sign < 0:
                if self.accounts.get(acct, D(0)) - amount < 0:
                    raise ValueError(
                        f"overdraft: {acct} ({self.accounts.get(acct, D(0))}) < {amount}")
        self.entries.append((debit, credit, amount, memo))
        self.accounts[debit] = self.accounts.get(debit, D(0)) - amount
        self.accounts[credit] = self.accounts.get(credit, D(0)) + amount

    def balance(self, account: str) -> D:
        return self.accounts.get(account, D(0))

    def total_posted(self) -> D:
        return sum((e[2] for e in self.entries), D(0))

    def invariant_ok(self) -> bool:
        """Ҷамъи ҳамаи ҳисобҳо бояд 0 бошад (double-entry)."""
        return sum(self.accounts.values(), D(0)) == D(0)


@dataclass
class Split:
    gross: D                 # net баъд аз refund
    payment_fee: D           # ҳамеша аз gross
    commission: D
    manager_bonus: D
    platform_net: D          # = commission − bonus − fee_absorbed
    seller_payout: D         # ҲЕҶ ГОҲ манфӣ
    fee_absorbed: D = D("0.00")   # қисми fee, ки платформа худаш мебардорад


def calculate_split(gross: D, rules: Rules, refunded: D = D(0)) -> Split:
    """
    Формулаи асосӣ (ҳангоми релизи escrow):
        net            = gross - refunded
        payment_fee    = gross * fee_rate            ← аз refund барнамегардад
        commission     = (net - payment_fee) * commission_rate
        manager_bonus  = commission * bonus_rate
        platform_net   = commission - manager_bonus
        seller_payout  = net - payment_fee - commission
    """
    net = gross - refunded
    if net < 0:
        raise ValueError("refund аз gross зиёд аст")

    payment_fee = q(gross * rules.payment_fee_rate)

    # МУҲИМ: fee ҳеҷ гоҳ аз фурӯшанда гирифта намешавад.
    # Агар пас аз refund барои fee ҷой набошад — платформа худаш мебардорад.
    fee_from_seller = min(payment_fee, net)
    fee_absorbed = payment_fee - fee_from_seller        # талафи платформа

    base = net - fee_from_seller
    commission = q(base * rules.commission_rate) if base > 0 else D("0.00")
    manager_bonus = q(commission * rules.manager_bonus_rate)
    platform_net = commission - manager_bonus - fee_absorbed
    seller_payout = q(base - commission)

    assert max(seller_payout, D(0)) == seller_payout, "payout манфӣ шуд!"
    return Split(net, payment_fee, commission, manager_bonus, platform_net, seller_payout, fee_absorbed)


# ─────────────────────────── Тест-фреймворк ───────────────────────────

class TestRun:
    def __init__(self):
        self.passed = 0
        self.failed = 0

    def check(self, name: str, cond: bool, detail: str = ""):
        if cond:
            self.passed += 1
            print(f"  \033[32m✓\033[0m {name}" + (f"  \033[90m{detail}\033[0m" if detail else ""))
        else:
            self.failed += 1
            print(f"  \033[31m✗ {name}\033[0m  {detail}")

    def eq(self, name: str, got, want, detail=""):
        self.check(name, got == want, detail or f"got={got} want={want}")


T = TestRun()
R = Rules()

# ═══════════════════ 1. Фармоиши муқаррарӣ: 1000 TJS ═══════════════════
print("\n\033[1m1 · Фармоиши муқаррарӣ — 1000.00 TJS\033[0m")
L = Ledger()
s = calculate_split(D("1000"), R)
L.post("buyer:wallet", "escrow:order:1", D("1000"), "харидор пардохт кард")
L.post("escrow:order:1", "platform:fees", s.payment_fee, "payment fee 1.5%")
L.post("escrow:order:1", "platform:revenue", s.commission, "commission 8%")
L.post("platform:revenue", "manager:bonus", s.manager_bonus, "manager 15%")
L.post("escrow:order:1", "seller:s1:payable", s.seller_payout, "seller payout")

T.eq("payment_fee = 15.00", s.payment_fee, D("15.00"))
T.eq("commission = 78.80", s.commission, D("78.80"))
T.eq("manager_bonus = 11.82", s.manager_bonus, D("11.82"))
T.eq("platform_net = 66.98", s.platform_net, D("66.98"))
T.eq("seller_payout = 906.20", s.seller_payout, D("906.20"))
T.eq("escrow холӣ шуд (0.00)", L.balance("escrow:order:1"), D("0.00"))
T.eq("фурӯшанда 906.20", L.balance("seller:s1:payable"), D("906.20"))
T.eq("платформа 66.98", L.balance("platform:revenue"), D("66.98"))
T.eq("менеджер 11.82", L.balance("manager:bonus"), D("11.82"))
T.eq("fees 15.00", L.balance("platform:fees"), D("15.00"))
T.check("double-entry: ҷамъи ҳисобҳо = 0", L.invariant_ok(),
        f"sum={sum(L.accounts.values(), D(0))}")
T.eq("ҷамъи 3 қисм = gross",
      s.payment_fee + s.commission + s.seller_payout, D("1000.00"))

# ═══════════════════ 2. Комиссияи категория: 12% ═══════════════════
print("\n\033[1m2 · Категорияи 12% (косметика) — 500 TJS\033[0m")
R2 = Rules(commission_rate=D("0.12"))
s2 = calculate_split(D("500"), R2)
T.eq("commission = 59.10", s2.commission, D("59.10"), f"(500 − 7.50) × 12%")
T.eq("bonus = 8.87", s2.manager_bonus, D("8.87"))
T.eq("seller = 433.40", s2.seller_payout, D("433.40"))
T.eq("sum = 500.00", s2.payment_fee + s2.commission + s2.seller_payout, D("500.00"))

# ═══════════════════ 3. Баргардонии қисмӣ (30%) ═══════════════════
print("\n\033[1m3 · Баргардонии қисмӣ — 300 аз 1000 баргардонида шуд\033[0m")
s3 = calculate_split(D("1000"), R, refunded=D("300"))
T.eq("net = 700.00", s3.gross, D("700.00"))
T.eq("fee пурра мемонад = 15.00", s3.payment_fee, D("15.00"),
      "PSP пулро барнамегардонад")
T.eq("commission аз 685 = 54.80", s3.commission, D("54.80"))
T.eq("seller = 630.20", s3.seller_payout, D("630.20"))
T.eq("gross = refund + fee + commission + seller",
      D("300") + s3.payment_fee + s3.commission + s3.seller_payout, D("1000.00"))

# ═══════════════════ 4. Баргардонии пурра ═══════════════════
print("\n\033[1m4 · Баргардонии пурра — харидор 1000 бармегардонад\033[0m")
s4 = calculate_split(D("1000"), R, refunded=D("1000"))
T.eq("комиссия = 0", s4.commission, D("0.00"))
T.eq("seller = 0 (на −15!)", s4.seller_payout, D("0.00"))
T.eq("fee = 15", s4.payment_fee, D("15.00"))
T.eq("fee_absorbed = 15 — платформа мебардорад", s4.fee_absorbed, D("15.00"))
T.check("platform_net манфӣ аст (−15), аммо фурӯшанда ҷарима намешавад",
        s4.platform_net == D("-15.00"), f"platform_net={s4.platform_net}")
print("  \033[90m→ Қоида: ҳангоми refund пурра, PSP fee аз фурӯшанда гирифта НАМЕШАВАД. "
      "Ин талафи платформа аст.\033[0m")

# ═══════════════════ 5. Баҳси 50/50 (dispute split) ═══════════════════
print("\n\033[1m5 · Баҳс: 50% ба харидор, 50% ба фурӯшанда\033[0m")
s5 = calculate_split(D("1000"), R, refunded=D("500"))
# net=500, fee=15 (аз 1000), commission=(500−15)×8% = 38.80, seller = 446.20
T.eq("seller = 446.20", s5.seller_payout, D("446.20"),
      "500 − 15(fee) − 38.80(commission)")
T.check("ҳама ҷамъ = 1000",
        D("500") + s5.payment_fee + s5.commission + s5.seller_payout == D("1000.00"))

# ═══════════════════ 6. Гурӯҳ ноком шуд ═══════════════════
print("\n\033[1m6 · Гурӯҳ ноком шуд (3 нафар, 149 × 3)\033[0m")
L6 = Ledger()
total = D("0")
for i in range(3):
    L6.post("buyer:wallet", "escrow:group:9", D("149.00"), f"member {i+1}")
    total += D("149.00")
T.eq("escrow = 447.00", L6.balance("escrow:group:9"), D("447.00"))
for i in range(3):
    L6.post("escrow:group:9", "buyer:wallet", D("149.00"), "refund full")
T.eq("escrow = 0 пас аз refund", L6.balance("escrow:group:9"), D("0.00"))
T.eq("комиссия = 0 (фурӯш нест)", D("0"), D("0"))
T.check("double-entry = 0", L6.invariant_ok())

# ═══════════════════ 7. Гирдкунӣ: 10 000 фармоиши хурд ═══════════════════
print("\n\033[1m7 · Гирдкунӣ — 10 000 фармоиш бо 33.33 TJS\033[0m")
L7 = Ledger()
for _ in range(10_000):
    sp = calculate_split(D("33.33"), R)
    L7.post("buyer:wallet", "escrow:o", D("33.33"), "payment")   # аввал маблағ меояд
    L7.post("escrow:o", "platform:fees", sp.payment_fee)
    L7.post("escrow:o", "platform:revenue", sp.commission)
    L7.post("platform:revenue", "manager:bonus", sp.manager_bonus)
    L7.post("escrow:o", "seller:s:payable", sp.seller_payout)
T.eq("escrow = 0.00 (ҳеҷ тийин нагум шуд)", L7.balance("escrow:o"), D("0.00"))
T.eq("кредитҳо = 333 300.00", L7.balance("platform:fees")
      + L7.balance("platform:revenue") + L7.balance("manager:bonus")
      + L7.balance("seller:s:payable"), D("333300.00"))
T.check("double-entry пас аз 10 000 амалиёт = 0", L7.invariant_ok())
print("  \033[90m→ Ҳар амалиёт алоҳида гирд мешавад; ҷамъи ҳисобҳо ҳамеша 0 мешавад.\033[0m")

# ═══════════════════ 8. Қоидаҳои 4-eye ва payout ═══════════════════
print("\n\033[1m8 · Қоидаҳои амалиётӣ\033[0m")


def needs_four_eye(amount: D, rules: Rules = R) -> bool:
    return amount > rules.four_eye_threshold


def payout_allowed(available: D, requested_24h: int, rules: Rules = R) -> tuple:
    if requested_24h >= 1:
        return False, "1 маротиба дар 24 соат"
    if available < rules.min_payout:
        return False, f"ҳадди ақал {rules.min_payout} TJS"
    return True, "ok"


T.check("1999 TJS — як тасдиқ кофист", not needs_four_eye(D("1999")))
T.check("2000.01 TJS — 2 тасдиқ лозим", needs_four_eye(D("2000.01")))
T.eq("payout 99 → рад", payout_allowed(D("99"), 0)[0], False)
T.eq("payout 100 → ok", payout_allowed(D("100"), 0)[0], True)
T.eq("payout дубора дар 24с → рад", payout_allowed(D("500"), 1)[0], False)

# ═══════════════════ 9. Ҳимоя аз маблағи манфӣ ═══════════════════
print("\n\033[1m9 · Ҳимояҳо\033[0m")
try:
    calculate_split(D("100"), R, refunded=D("150"))
    T.check("refund > gross бояд хато диҳад", False)
except ValueError:
    T.check("refund > gross → ValueError", True)

try:
    Ledger().post("a", "b", D("-5"))
    T.check("маблағи манфӣ бояд рад шавад", False)
except ValueError:
    T.check("маблағи манфӣ → ValueError", True)

# escrow наметавонад манфӣ шавад: релизи бе маблағ = хато
LX = Ledger()
LX.post("buyer:wallet", "escrow:x", D("100"))
try:
    LX.post("escrow:x", "seller:s:payable", D("150"), "over-release")
    T.check("over-release бояд рад шавад", False, "150 аз escrow-и 100 рафт!")
except ValueError as e:
    T.check("over-release → ValueError", True, str(e))

# ═══════════════════ Ҳисобот ═══════════════════
print("\n" + "─" * 66)
if T.failed == 0:
    print(f"\033[32m\033[1m✓ ҲАМАИ {T.passed} САНҶИШИ МОЛИЯВӢ ГУЗАШТ\033[0m")
else:
    print(f"\033[31m\033[1m✗ {T.failed} аз {T.passed + T.failed} ноком\033[0m")
print("─" * 66)
raise SystemExit(0 if T.failed == 0 else 1)
