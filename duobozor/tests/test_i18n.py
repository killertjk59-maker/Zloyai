#!/usr/bin/env python3
"""
duobozor/tests/test_i18n.py
─────────────────────────────────────────────────────────────────────────────
Санҷиши локализатсия: ҳар элементе, ки data-tj дорад, бояд data-ru низ дошта
бошад (ва баръакс). Ин кафолат медиҳад, ки ҳангоми иваз кардани забон
ҳеҷ матн «сакт» намемонад.

Иҷро: python3 duobozor/tests/test_i18n.py
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HTML = sorted((ROOT / "docs").glob("*.html"))

# Теги кушодашударо мегирем ва дар дохили он data-tj / data-ru меҷӯем
TAG_RE = re.compile(r"<([a-zA-Z][\w-]*)\b([^>]*)>", re.S)
ATTR_RE = re.compile(r'data-(tj|ru)="([^"]*)"', re.S)

passed, failed = 0, 0


def check(name, cond, detail=""):
    global passed, failed
    if cond:
        passed += 1
        print(f"  \033[32m✓\033[0m {name}" + (f"  \033[90m{detail}\033[0m" if detail else ""))
    else:
        failed += 1
        print(f"  \033[31m✗ {name}\033[0m  {detail}")


total_strings = 0

for f in HTML:
    print(f"\n\033[1m{f.name}\033[0m")
    html = f.read_text(encoding="utf-8")

    only_tj, only_ru, both = [], [], 0
    for m in TAG_RE.finditer(html):
        attrs = m.group(2)
        langs = {k: v for k, v in ATTR_RE.findall(attrs)}
        if not langs:
            continue
        snippet = (m.group(1) + " " + " ".join(f"{k}={v[:38]}" for k, v in langs.items()))
        if "tj" in langs and "ru" in langs:
            both += 1
            # дарозии матнҳо набояд хеле фарқ кунанд (нишони тарҷумаи нопурра)
            if langs["tj"] and not langs["ru"].strip():
                only_ru.append(("ru холӣ", snippet))
        elif "tj" in langs:
            only_tj.append(snippet)
        else:
            only_ru.append(("ru бе tj", snippet))

    total_strings += both + len(only_tj) + len(only_ru)
    check(f"{both} сатри дузабона", both > 0, f"{both} элемент")
    check("ҳамаи data-tj дорои data-ru", not only_tj,
          "" if not only_tj else f"{len(only_tj)}: {only_tj[:3]}")
    check("ҳамаи data-ru дорои data-tj", not only_ru,
          "" if not only_ru else f"{len(only_ru)}: {only_ru[:3]}")

    # HTML бояд як <html lang> дошта бошад
    check("html lang муайян шудааст", bool(re.search(r"<html lang=\"(tj|ru)\"", html)))

    # Ҳеҷ матни «to be translated»/«TODO» намонда бошад
    check("ҳеҷ TODO/Lorem намонад",
          not re.search(r"(TODO|Lorem ipsum|XXX|FIXME)", html, re.I))

print("\n\033[1mУмумии файлҳо\033[0m")
check("Ҳамаи файлҳои HTML мавҷуданд", len(HTML) >= 3, f"{len(HTML)} файл")
check("Ҳаҷми калон: ≥ 150 сатри тарҷумашуда", total_strings >= 150, f"{total_strings} сатр")

print("\n" + "─" * 66)
if failed == 0:
    print(f"\033[32m\033[1m✓ ҲАМАИ {passed} САНҶИШИ i18n ГУЗАШТ\033[0m")
else:
    print(f"\033[31m\033[1m✗ {failed} аз {passed + failed} ноком\033[0m")
print("─" * 66)
sys.exit(0 if failed == 0 else 1)
