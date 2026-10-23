# DuoBozor 🛍️

**Гурӯҳхаридии тоҷикӣ бо escrow** — «гурӯҳ соз, нархи паст гир».
Стратегияи Pinduoduo барои бозори Тоҷикистон: нархи мол вобаста ба андозаи гурӯҳ аст,
пул то қабули мол дар escrow ҳифз мешавад, фурӯшанда баъд аз тасдиқ маблағ мегирад.

---

## 📱 APK гирифтан

1. Ба [Releases](https://github.com/killertjk59-maker/Zloyai/releases) гузаред
2. `duobozor-1.1.0.apk`-ро зеркашӣ кунед
3. Дар телефон кушоед → «Install unknown apps»-ро барои браузер иҷозат диҳед

APK аз ҷониби **GitHub Actions** сохта мешавад (`.github/workflows/duobozor-apk.yml`):
Node 20 → JDK 17 → `expo prebuild` → `gradlew assembleRelease` → artifact + release.

---

## 🧩 Чӣ кор мекунад

| Модул | Тафсилот |
|---|---|
| **Гурӯҳхаридӣ** | Нархҳои зинавӣ: танҳо / ҷуфт (2) / гурӯҳ (5). Таймери 24 соат. Гурӯҳ пур шуд → нархи паст; пур нашуд → пул бармегардад |
| **Escrow** | `харидор → платформа → фурӯшанда` танҳо пас аз «Гирифтам». Автоозодкунӣ баъд аз 7 рӯз |
| **Ledger** | Ҳисобҳои дутарафа (double-entry) бо **тийин** (адади бутун). Σ ҳамаи ҳисобҳо = 0 |
| **Комиссия** | PSP 1.5%, комиссияи категория 5–12%, бонуси менеҷер 15% аз комиссия |
| **Нақшҳо** | `buyer` · `seller` · `manager` · `admin` (панелҳои алоҳида дар барнома) |
| **Воридшавӣ** | Telegram · Google · телефон · **админ (рақам + рамз)**. Ҳангоми сабти ном **ном, насаб, синну сол** пурсида мешавад |
| **Админ** | `+992 92 111 22 33` · рамз `admin2026` → панели пурра (escrow, комиссия, payout, аудит) |
| **Забон** | Тоҷикӣ + Русӣ (130 калид, пурра) |
| **Оффлайн** | Навбати амалҳо дар AsyncStorage, `REQUIRES_NETWORK` guard, синхронӣ |
| **Аниматсия** | Tab bar: morph (spring pill) + ripple + FAB; ҳар экран fade+slide; кортҳо бо stagger; скайли пахш; аниматсияи «ба сабад» |
| **Устуворӣ** | ErrorBoundary дар ҳар экран; вибратсия хомӯш карда шуд; бе Intl (Hermes-хатар) |

## 💰 Қоидаҳои пул

```
gross            = маблағи пардохти харидор
paymentFee       = 1.5% (PSP)
commission       = rate(category) × (gross − fee)
managerBonus     = 15% × commission
sellerPayout     = gross − fee − commission
platformNet      = commission − managerBonus − feeAbsorbed

min payout       = 100 c.        four-eye = 2000 c.
auto-release     = 7 рӯз          payout cooldown = 24 соат
```

Ҳама дар тийин (`1 TJS = 100 tiyn`), ҳеҷ гоҳ float.
Санҷиш: `cd mobile && npm test` → **60 санҷиш** + `npm run test:ui` → **8 санҷиши render/пахш**.

## 🔐 Телефон = identity

```
92 123 45 67  →  +992921234567
0921234567    →  +992921234567
+992 92 123 45 67 → +992921234567
8 92 123 45 67 →  +992921234567
```
Ҳамон рақам → ҳамон `user_id` → фармоишҳо ва ҳамён гум намешаванд.

## 🤖 Бот

[@Bozoronline_bot](https://t.me/Bozoronline_bot) — `/start`, `/catalog`, `/group`, `/escrow`, `/app`, `/admin`.
Поллинг аз `.github/workflows/duobozor-bot.yml` (ҳар 10 дақиқа), offset дар `scripts/.bot-state.json`.

> ⚠️ Барои гирифтани паёмҳои админ, админ бояд як бор ба бот **/start** нависад —
> то он вақт Telegram `chat not found` медиҳад (маҳдудияти худи Telegram).

## 🗂 сохтор

```
duobozor/
├── mobile/            ← барномаи Expo (RN 0.74)
│   ├── App.js         ← auth gate + tab bar + stack
│   ├── src/store.js   ← ҳамаи мантиқ (auth, cart, group, escrow, admin)
│   ├── src/lib/       ← money.js (tiyn+ledger), offlineQueue.js
│   ├── src/screens/   ← 12 экран
│   ├── src/components/← ui.js, TabBar.js (morph+ripple+FAB)
│   └── test/          ← 60 санҷиши мантиқ + 8 санҷиши UI (jest-expo)
├── docs/              ← нақша, auth, дизайн, тафтиш, offline
├── tests/             ← 6 гурӯҳи санҷиш (161 check)
└── scripts/           ← bot.mjs, notify.sh
```

## 🛠 Локалӣ

```bash
cd mobile
npm install
npm test          # 60 санҷиш
npx expo start    # QR → Expo Go
```

Барои APK-и локалӣ JDK 17 лозим аст: `npm run prebuild && npm run apk`.
