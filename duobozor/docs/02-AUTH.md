# DuoBozor — Системаи воридшавӣ (Identity & Auth)

> Принсипи асосӣ: **Аккаунт = user_id. Телефон, Telegram, Google — танҳо «калидҳо» ба он.**
> Барои ҳамин рақами телефон иваз шавад ҳам, фармоишҳо, ҳамён, баҳоҳо ва рейтинг
> бо ҳамон аккаунт мемонанд.

---

## 1. Мушкили аслӣ ва ҳалли он

### 1.1 Мушкил
Дар 90% барномаҳои маҳаллӣ `orders.user_phone = '+992921234567'` навишта мешавад.
Пас:
- корбар рақамашро иваз кард → **ҳисоби нав**, фармоишҳои кӯҳна гум мешаванд;
- як рақам бо форматҳои гуногун (`992921234567`, `+992 92 123-45-67`,
  `8 921 234 567`, `0921234567`) → **3–4 аккаунти гуногун**;
- корбар телефонро гум кард → ба ҳисоб дастрасӣ надорад, ҳарчанд Google-аш пайваст буд.

### 1.2 Ҳал — 4 қоида

| # | Қоида | Татбиқ |
|---|---|---|
| 1 | **Телефон = identity, на account** | `auth_identities(user_id, provider='phone', provider_uid='+992921234567')`. Як корбар метавонад 2–3 рақам дошта бошад. |
| 2 | **Ҳамеша E.164 каноникӣ** | Ҳар вуруд бо `libphonenumber` ба `+992XXXXXXXXX` табдил меёбад, пеш аз ҷустуҷӯ. `992…`, `0921…`, `+992 (92) 123-45-67` → як сатр. |
| 3 | **Бисёр калидҳо → як аккаунт** | Google, Telegram, Apple, Email, Phone — ҳама ба `user_id`-и ягона пайваст мешаванд. |
| 4 | **Ҳеҷ гоҳ дар Identity ягона нест** | `UNIQUE(provider, provider_uid)` — на дар `users`. Рақами кӯҳна дар `phone_history` боқӣ мемонад. |

---

## 2. Роҳҳои воридшавӣ (providers)

| Provider | Барои кӣ | Ҷараён | Ҷойгиршавӣ |
|---|---|---|---|
| 📱 **Phone OTP** | Ҳама, воситаи асосӣ | рақам → SMS-код (6 рақам, 2 дақиқа) → аккаунт | Ҳатмӣ |
| ✈️ **Telegram Login** | 80%+ корбарон (TJ бозор) | Telegram WebApp / Login Widget → `initData` бо HMAC-и бот-токен | Ҳатмӣ |
| 🔵 **Google** | Android-корбарон | OAuth 2.0 / ID token (Google Sign-In) | Ҳатмӣ |
| 🍎 **Apple Sign-In** | iOS (талаби Apple) | Sign in with Apple, `identityToken` | Барои iOS ҳатмӣ |
| ✉️ **Email + парол** | Фурӯшандагон, админҳо | email → парол + 2FA (TOTP) | Барои staff ҳатмӣ |
| 🆔 **Telegram Bot deep-link** | Даъватномаи гурӯҳӣ | `t.me/DuoBozorBot?start=grp_<id>` → ҳамроҳшавӣ ба гурӯҳ | Ҳатмӣ барои group-buy |

> **Тавсия:** аввалин экран 3 тугмаи калон: **Telegram** (асосӣ), **Google**, **Телефон**.
> Apple дар iOS автоматикан илова мешавад.

---

## 2.1 Telegram — се механизми гуногун (дарҳам намеомезанд!)

> Демои зинда: **`telegram-auth-demo.html`** · Код: `server/src/auth/telegram.service.ts`,
> `server/src/auth/telegram.bot.ts`, `expo/lib/telegramAuth.ts`

Telegram **як** роҳи вуруд надорад — се дорад, ва ҳар се ба `auth_identities`
менависанд, аммо ҷараёни техникиашон комилан фарқ мекунад.

### A. Bot + deep-link (nonce) ★ барои барномаи мобилӣ

```
БАРНОМА                     СЕРВЕР                        TELEGRAM
   │  POST /auth/telegram/start {device_id}
   │──────────────────────────▶│
   │                           │ nonce = random(16 bytes)
   │                           │ Redis: tg:nonce:<n> = {deviceId, TTL 300s}
   │  ◀── {nonce, deep_link} ──│
   │
   │ Linking.openURL("https://t.me/DuoBozorBot?start=login_<nonce>")
   │──────────────────────────────────────────────────────────▶│ бот кушода
   │                                                             │ /start login_<n>
   │                           │◀──── webhook ──────────────────│
   │                           │ onBotStart(nonce, tg_user)
   │                           │
   │                           │     бот: «✅ Тасдиқи вуруд?»
   │                           │◀──── callback confirm ─────────│ корбар пахш кард
   │                           │     бот: «📱 Рақами телефонро тасдиқ кун»
   │                           │◀──── contact (verified) ───────│
   │                           │ confirmFromBot(nonce, tg, phone)
   │                           │   ├─ identity(telegram, id) ёфт? → ҳамон аккаунт
   │                           │   ├─ identity(phone, +992…) ёфт? → ПАЙВАСТ
   │                           │   └─ не → аккаунти нав
   │                           │ nonce.status = 'confirmed'
   │  GET /auth/telegram/poll?nonce=…  (ҳар 1.5с, 90с)
   │──────────────────────────▶│
   │  ◀── {access, refresh} ───│  (nonce нест мешавад — якдафъаин)
```

**Чаро ин роҳ барои мобилӣ:** токен ҳеҷ гоҳ дар URL/redirect намегузарад; nonce
якдафъаин, TTL 5 дақиқа, ба `device_id` часпида; тасдиқ аз ҷониби худи корбар
дар дохили Telegram (пас линки дуздидашуда бефоида). Рақами телефонро Telegram
**худаш** тасдиқ мекунад (`request_contact` + санҷиши `contact.user_id === from.id`).

**Муҳим:** дар бот ҳатман тугмаи «✕ Ин ман нестам» бояд бошад — вагарна корбар
беихтиёр вуруд мекунад.

### B. Telegram Mini App (WebApp) — веб ва PWA

```js
// дар дохили mini app
const initData = window.Telegram.WebApp.initData;  // query_id=…&user=…&auth_date=…&hash=…
POST /api/v1/auth/telegram/miniapp { init_data, device_id }
```
Санҷиш дар сервер:
```ts
secret   = HMAC_SHA256("WebAppData", bot_token)
hash_calc= HMAC_SHA256(secret, data_check_string)   // калидҳо ба тартиби алифбо, \n
hash_calc === params.hash   &&   now - auth_date < 300
```
`data_check_string` = ҳамаи параметрҳо ба ғайр аз `hash`, сортишуда, бо `\n`.
**Хатои маъмул:** `secret = SHA256(bot_token)` — ин барои Widget, на барои WebApp!

### C. Login Widget — танҳо браузер (панели админ)

```html
<script async src="https://telegram.org/js/telegram-widget.js?22"
        data-telegram-login="DuoBozorBot" data-size="medium"
        data-auth-url="https://api.duobozor.tj/api/v1/auth/telegram/widget"></script>
```
```ts
secret    = SHA256(bot_token)                  // ← SHA256, на HMAC
hash_calc = HMAC_SHA256(secret, data_check_string)
```
Дар барномаи мобилӣ **кор намекунад** — браузер кушода намешавад.

### 2.2 Муқоиса

| | Bot + deep-link | Mini App | Login Widget |
|---|---|---|---|
| Барномаи мобилӣ (Expo) | ✅ ★ | ⚠️ танҳо WebView | ❌ |
| Веб / PWA | ✅ | ✅ | ✅ |
| Токен дар URL | ❌ не | ❌ не | ❌ не |
| Рақами тасдиқшуда аз Telegram | ✅ (`contact`) | ⚠️ не | ⚠️ не |
| Сохтани инфрасохтор | webhook + Redis | WebApp URL | домени тасдиқшуда |
| Мувофиқ барои viral/share | ✅ (start-payload) | ✅ | ❌ |

### 2.3 Танзимоти @BotFather (як маротиба)

```
/newbot                        → ном + username → ТОКЕН
/setdomain                     → duobozor.tj          (барои Login Widget)
/newapp                        → ном, URL-и веб-версия  (барои Mini App)
/setmenubutton                 → «🛍️ DuoBozor» → https://duobozor.tj/app
/setcommands                   → start - Вуруд ба барнома
/setdescription                → Маркетплейси гурӯҳхаридии DuoBozor
/setuserpic                    → логотип
/setwebhook                    → https://api.duobozor.tj/api/v1/auth/telegram/webhook
                                 ?secret_token=<INTERNAL_WEBHOOK_SECRET>
```
`.env`:
```env
TELEGRAM_BOT_TOKEN=1234567890:AAH...
TELEGRAM_BOT_USERNAME=DuoBozorBot
INTERNAL_WEBHOOK_SECRET=<random 32 bytes>
WEBAPP_URL=https://duobozor.tj/app
```
Webhook **ҳатман** бо `secret_token` санҷида шавад (`X-Telegram-Bot-Api-Secret-Token`),
вагарна ҳар кас метавонад update-и қалбакӣ фиристад.

### 2.4 Чӣ тавр Telegram ба аккаунти кӯҳна пайваст мешавад

```
Корбар соли 2024 бо рақами +992921234567 сабт шуда буд (247 фармоиш).
Имрӯз мехоҳад бо Telegram дарояд:
  1. Бот мепурсад: «📱 Рақами телефонро тасдиқ кун»
  2. Корбар contact-и худро медиҳад (Telegram рақамро тасдиқ мекунад)
  3. normalize_phone() → +992921234567
  4. auth_identities(provider='phone', uid='+992921234567') → user_id 7f3a…
  5. Telegram id ↔ ҳамон user_id  →  ПАЙВАСТ
  6. Корбар мебинад: «Хуш омадед, Фарзона · 247 фармоиш» ✓
```
Ҳеҷ фармоиш, ҳамён ё рейтинг гум намешавад — чунки ҳама ба `user_id` часпидаанд.

> Агар корбар рақамро надиҳад («⏭ Бе рақам идома») — аккаунти нав мекушояд, вале
> дар Танзимот метавонад баъдтар рақам илова карда, ду аккаунтро пайваст кунад.

---

## 3. Ҷараёни воридшавӣ (детерминистӣ)

```
                    ┌─────────────────────────┐
                    │   Экран 1: Хуш омадӣ    │
                    │  ✈️ Telegram            │
                    │  🔵 Google              │
                    │  📱 Телефон             │
                    └───────────┬─────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
  Telegram initData        Google ID token          Phone + OTP
        │                       │                       │
        └───────────┬───────────┴───────────┬───────────┘
                    ▼                       ▼
        ┌───────────────────┐   ┌───────────────────────────┐
        │ Identity ёфт шуд? │──▶│ ҲА → LOGIN                │
        └─────────┬─────────┘   │  (фармоишҳо, ҳамён, рейтинг)│
                  │ НЕ          └───────────────────────────┘
                  ▼
        ┌───────────────────────────────────────────────┐
        │ Оё ин identity ба аккаунти дигар пайваст аст? │
        └─────────┬─────────────────────────────────────┘
                  │ НЕ → CREATE USER (нав)
                  ▼
        ┌───────────────────────────────────────────────┐
        │ Экран 2: «Пайваст кардан» (Linking)           │
        │ Мо аккаунти мавҷудро бо ин телефон ёфтем:     │
        │   Фарзона · 247 фармоиш · аз 2024             │
        │   [ Ҳамин аккаунт — пайваст кун ]             │
        │   [ Ин аккаунти дигар аст → аккаунти нав ]    │
        └───────────────────────────────────────────────┘
```

**Қоидаи муҳими амният:** пайваст кардани identity ба аккаунти мавҷуд **танҳо
пас аз тасдиқи он аккаунт** мумкин аст (OTP ба рақами он, ё воридшавӣ тавассути
provider-и аллакай пайвастшуда). Дар акси ҳол — ғоратгарии аккаунт.

---

## 4. Телефон «формат шавад» — се сенария

### 4.1 Сенария A — Ҳамон рақам, формати гуногун ✅ (ҳал шудааст)
```
Корбар навишт:        992921234567
                      +992 92 123 45 67
                      0921234567
                      8 (92) 123-45-67
                            ↓  normalize_phone()
E.164:                +992921234567   ← ҲАМЕША як сатр
                            ↓
auth_identities:      user_id = 7f3a…  (Фарзона, 247 фармоиш)
```
Натиҷа: **ҳамон аккаунт**, ҳамон сабад, ҳамон фармоишҳо, ҳамон ҳамён.

### 4.2 Сенария B — Рақами нав (кӯҳнаро партофт) 🔁
```
Корбар: воридшавӣ бо рақами НАВ +992935556677
  ↓
Система: ин identity нав аст → аккаунти холӣ месозад (ё пешниҳоди пайваст)
  ↓
Экран: «Ҳисоби кӯҳна доред? Барои пайваст кардан ворид шавед:
        ✈️ Telegram   🔵 Google   📱 Рақами кӯҳна
        → Баъд аз воридшавӣ: Танзимот → Аккаунт → Илова кардани рақам»
  ↓
Ҳарду рақам ба ҳамон user_id пайваст → фармоишҳо як ҷо
```

### 4.3 Сенария C — Телефон гум шуд / SIM иваз шуд 🆘
```
Корбар: «Телефонам нест»
  ↓
Воридшавӣ тавассути provider-и дигари пайвастшуда:
   ✈️ Telegram  ё  🔵 Google  ё  📧 Email + 2FA
  ↓
Аккаунт кушода мешавад — фармоишҳо ҷояшон
  ↓
Танзимот → «Рақами нав илова кун» → OTP ба рақами нав → кӯҳна ғайрифаъол
   (кӯҳна дар phone_history мемонад, 3 сол)
```

> **Ҳеҷ гоҳ** фармоиш ба рақами телефон «часпонида» намешавад — танҳо ба `user_id`.
> Ин ягона роҳи дуруст аст.

---

## 5. Пайваст кардани аккаунтҳо (Account Linking)

```
Танзимот → Аккаунт ва амният
┌────────────────────────────────────────────────┐
│ 📱 +992 92 123 45 67      Асосӣ      ✓ Тасдиқ  │
│ ✈️ @farzona_tj           Пайваст     ✕ Ҷудо    │
│ 🔵 farzona@gmail.com     Пайваст     ✕ Ҷудо    │
│ 📧 — Ҳоло нест           Пайваст кун           │
├────────────────────────────────────────────────┤
│ 🔐 2FA: фаъол (TOTP)                           │
│ 🖥 Дастгоҳҳои фаъол: 2  → Дидан / Қатъ кардан  │
│ ⚠️ Амалҳои охирин: 23.10, 10:02 — Хуҷанд       │
└────────────────────────────────────────────────┘
```

**Қоидаҳо:**
1. Ҳамеша камаш **як** identity-и «recovery» бояд бошад (Google/Telegram/Email).
2. Ҷудо кардани identity-и охирин → блок (ба ғайр аз нест кардани аккаунт).
3. Ҷудо кардан → 7 рӯз «кӯл» барои бекор кардан.
4. Ҳар пайваст/ҷудокунӣ → `auth_events` + email/SMS-огоҳӣ.

---

## 6. Ҷадвали таъмини амният

| Хавф | Чора |
|---|---|
| Brute-force OTP | 5 кӯшиш / код, 3 код / 10 дақиқа / рақам, rate-limit бо Redis, IP+device |
| SIM-swap | Барои амалҳои ҳассос (payout, ивази рақам) — 2FA ё OTP ба рақами кӯҳна низ |
| Фиреби OTP | Код ҳеҷ гоҳ дар SMS-и дуюм намеояд; огоҳии «касе кӯшиш кард» |
| Telegram initData-и қалбакӣ | Санҷиши HMAC-SHA256 бо `bot_token`, `auth_date` ≤ 5 дақиқа, replay-cache |
| Google token | Санҷиши `aud` + `iss` + имзо тавассути JWKS-и Google |
| Session hijacking | access 15 дақиқа, refresh rotation, device binding, revocation |
| Аккаунти дугона | Аввал ҷустуҷӯи identity; пешниҳоди «пайваст кун» ҳангоми мувофиқат |
| Худкардаи referral | Device fingerprint + рақами ягона + KYC ҳангоми пардохт |

**Ҳуқуқи корбар:** дидани ҳамаи дастгоҳҳо, қатъ кардани ҷаласа, зеркашии маълумот,
нест кардани аккаунт (30 рӯз grace, баъд anonymize — `user_id` боқӣ мемонад барои
ҳисоботҳои молиявӣ).

---

## 7. Схемаи маълумот (ба database.sql илова шуд)

```
users                     ← аккаунт (id, статус, забон, referral_code)
auth_identities           ← калидҳо: provider + provider_uid → user_id
                            UNIQUE(provider, provider_uid)
phone_history             ← рақамҳои кӯҳна (3 сол), барои дедупликатсия
auth_events               ← ҳар кӯшиши воридшавӣ: навъ, натиҷа, IP, device
sessions / refresh_tokens ← ҷаласаҳо (device binding, rotation)
otp_codes                 ← кодҳои якдафъаина (hash, TTL)
kyc_documents             ← ҳуҷҷатҳо барои фурӯшанда
```

---

## 8. Намунаи API

```http
POST /api/v1/auth/phone/start
{ "phone": "0921234567" }            → { normalized: "+992921234567",
                                          exists: true,
                                          hint: "Фарзона · 247 фармоиш" }
POST /api/v1/auth/phone/verify
{ "phone": "+992921234567", "code": "481920" }  → { access, refresh, is_new:false }

POST /api/v1/auth/telegram
{ "initData": "query_id=...&hash=..." }        → { access, refresh }

POST /api/v1/auth/google
{ "idToken": "eyJhbGci..." }                   → { access, refresh }

POST /api/v1/auth/link/start
{ "provider": "google" }                        → { linkToken, redirectUrl }
POST /api/v1/auth/link/confirm
{ "linkToken": "...", "code": "..." }           → { linked: true }

POST /api/v1/auth/phone/change/start
{ "newPhone": "935556677" }                     → { otpSent: true }
POST /api/v1/auth/phone/change/confirm
{ "code": "112233" }                            → { phone: "+992935556677" }

GET  /api/v1/me/identities                      → [{provider, mask, verified, primary}]
DELETE /api/v1/me/identities/:id                → 409 агар охирин бошад
GET  /api/v1/me/sessions                        → дастгоҳҳо
DELETE /api/v1/me/sessions/:id
```

**Ҳамаи ҷавобҳо:** `access_token` (15 дақиқа, JWT дорад `sub`, `roles`, `sid`) +
`refresh_token` (30 рӯз, дар `expo-secure-store`).

---

## 9. Экрани мобилӣ (5 экран)

1. **Splash / Хуш омадӣ** — логотип + 3 тугмаи калон + «Давом додан = шартҳоро қабул мекунам»
2. **OTP** — 6 хона, auto-fill аз SMS, таймери 60с, «Ба рақами дигар»
3. **Linking** — «Ин аккаунт аз они шумост?» + омори аккаунт (фармоишҳо, сана)
4. **Профил** — ном, забон, шаҳр, суроғаи аввал
5. **Танзимот → Аккаунт ва амният** — identity-ҳо, 2FA, дастгоҳҳо, таърих

> Демои интерактивӣ: **`auth-tabbar-demo.html`** — 4 экрани auth + таб-бари аниматсиядор.

---

## 10. Таб-бар бо аниматсия (Morphing / Ripple / FAB)

### 10.1 Morphing Animation — индикатори ягона
Ба ҷои 5 underline-и алоҳида, **як «pill»** ҳаст, ки ҳангоми ивазшавии таб
**шакл ва ҷойи худро тағйир медиҳад** (morph):
- `width` 44 → 64px (васеъ мешавад барои матн)
- `borderRadius` 22 → 16
- `translateX` бо `withSpring({ damping: 18, stiffness: 220 })` — на `linear`
- Иконка: `outline → filled` + `scale 1 → 1.08`, ранг бо `interpolateColor`
- Матн: `opacity 0 → 1`, `translateY 6 → 0` бо `delay 60ms`

**Дарҳамии Reanimated:**
```ts
const x = useSharedValue(0);
const w = useSharedValue(44);

const onSelect = (i: number) => {
  x.value = withSpring(positions[i].x, { damping: 18, stiffness: 220 });
  w.value = withSpring(positions[i].w, { damping: 18, stiffness: 220 });
};
// индикатор:
<Animated.View style={[styles.pill, useAnimatedStyle(() => ({
  transform: [{ translateX: x.value }],
  width: w.value,
  borderRadius: interpolate(w.value, [44, 64], [22, 16]),
}))]} />
```

### 10.2 Ripple Effect — ҷавоби фаврӣ ба пахш
Ҳар пахш → доира аз нуқтаи пахш васеъ мешавад ва хира мешавад:
- `scale: 0 → 1` (200ms, `Easing.out(Easing.cubic)`)
- `opacity: 0.28 → 0` (450ms)
- Ҳаҷм = 2× калонтарини таб; `clip` дар дохили таб
- Дар iOS ҳам кор мекунад (на `TouchableNativeFeedback`-и Android-танҳо)
- + `Haptics.selectionAsync()` барои ҳисси физикӣ

### 10.3 Floating Action Button — тугмаи марказӣ
- `+` дар марказ, болотар аз таб-бар (`marginTop: -22`)
- Пахш → **3 амали асосӣ** бо `stagger 40ms`: «Гурӯҳ соз», «Сканери QR», «Даъвати дӯст»
- Аниматсия: `rotate 0 → 45deg`, `scale 1 → 1.1`, меню `translateY 20 → 0` + `opacity`
- Backdrop `rgba(0,0,0,.35)` + `blur` — тавассути `expo-blur`
- Пахши дубора ё backdrop → бармегардад

### 10.4 Қоидаҳои UX
| Қоида | Сабаб |
|---|---|
| Аниматсия ≤ 300ms | Дар телефонҳои арзон (Redmi 9A) ҳам равон |
| `useNativeDriver` / Reanimated 3 дар UI-thread | JS-thread банд нашавад ҳангоми боркунии feed |
| `Reduce Motion` (дастрасӣ) | Аниматсияҳо хомӯш мешаванд, ҳолатҳо фаврӣ иваз |
| Таб-бар ҳеҷ гоҳ пинҳон нашавад ҳангоми scroll | Корбар роҳро гум накунад |
| FAB танҳо дар 4 таб (на дар checkout) | Дар checkout хатари пахши нодуруст |
| Ripple танҳо дар пахш (на hover) | Мобилӣ |
