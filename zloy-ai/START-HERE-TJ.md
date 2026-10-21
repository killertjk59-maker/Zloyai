# ZLOY.AI — АЗ ZIP ТО APK (10 дақиқа)

Ин файл барои он аст, ки ҳама чизро **аз телефон** анҷом диҳед.
Ҳамаи фармонҳоро метавонед нусхабардорӣ (copy) ва гузоштан (paste) кунед.

---

## Қадами 1 — ZIP-ро кушоед

Файли `zloy-ai.zip`-ро дар телефони худ зеркашӣ кунед ва кушоед. Дар дохили он
як папка бо номи **`zloy-ai/`** ва дар дохили он инҳо ҳастанд:

```
zloy-ai/
├── app/          ← барномаи Flutter
├── backend/      ← сервери FastAPI (ихтиёрӣ)
├── .github/      ← workflow-ҳо (CI + Android build)
├── README.md     ← дастури пурра
├── LICENSE
├── .gitignore
└── .env.example
```

> Муҳим: папкаи `.github` бояд **дар решаи репозиторий** бошад, вагарна GitHub
> workflow-ро намебинад. Агар аз дохили папка push кунед, ҳамин тавр мешавад.

---

## Қадами 2 — Ба GitHub гузоштан

### Роҳи A — бо телефон (Termux)

1. Аз **F-Droid** барномаи **Termux**-ро насб кунед (на аз Play Store — версияи он
   кӯҳна аст).
2. Дар Termux:

```bash
pkg update -y && pkg install -y git unzip
termux-setup-storage          # иҷозати дастрасӣ ба файлҳоро диҳед
```

3. ZIP-ро кушоед (роҳро мувофиқи ҷои зеркашии худ иваз кунед):

```bash
cd ~/storage/downloads
unzip zloy-ai.zip
cd zloy-ai
```

4. Токени GitHub созед: GitHub → **Settings** → **Developer settings** →
   **Personal access tokens** → **Tokens (classic)** → **Generate new token** →
   scope: **`repo`** → нусхабардорӣ кунед (онро дигар боз намебинед).

5. Репозиторийи холии нав дар GitHub созед (бе README, бе .gitignore).

6. Пас дар Termux:

```bash
git init -b main
git config user.name "ZLOY"
git config user.email "you@example.com"
git add .
git commit -m "ZLOY.AI: Flutter app + FastAPI backend"
git remote add origin https://github.com/<USERNAME>/<REPO>.git
git push -u origin main
```

Вақте ки `Username` ва `Password` пурсад: **Username** = номи GitHub-и шумо,
**Password** = **токен** (на пароли аккаунт).

### Роҳи B — бо компютер

```bash
cd zloy-ai
git init -b main
git add .
git commit -m "ZLOY.AI: Flutter app + FastAPI backend"
git remote add origin https://github.com/<USERNAME>/<REPO>.git
git push -u origin main
```

Ё тавассути вебсайт: GitHub → репозиторий → **Add file** → **Upload files** →
папкаҳои `app`, `backend`, `.github` ва файлҳои решаро кашида гузоред (дар
браузери компютер кор мекунад).

> Ҳеҷ гоҳ `git push --force` накунед ва таърихро тағйир надиҳед.

---

## Қадами 3 — APK-ро аз GitHub гирифтан

1. Дар GitHub ба таб **Actions** дароед.
2. Workflow-и **«Android build»** худаш оғоз мешавад (агар нашуд: **Run workflow**).
3. Интизор шавед, ки чек **сабз** шавад — бори аввал ~4–8 дақиқа.
4. Поёни саҳифаи ҳамон run → **Artifacts**:

| Artifact | Дар дохилаш | Барои чӣ |
|---|---|---|
| `zloy-debug-apk` | **`zloy-debug.apk`** | Барои насб кардан — **инро гиред** |
| `zloy-release-apk` | **`zloy-release.apk`** | Версияи оптимизатсияшуда |
| `zloy-aab` | **`zloy.aab`** | Формати Google Play |

5. Artifact ҳамчун `.zip` зеркашӣ мешавад. Онро дар Files кушоед ва **extract**
   кунед — баъд файли `.apk`-ро мебинед.

Агар чек **сурх** шуд — ба қадами «Хатоҳо» нигаред; ман дар ҷавоб навиштаам, ки
чиро тафтиш кардан лозим.

---

## Қадами 4 — Насб дар телефон

1. `zloy-debug.apk`-ро клик кунед.
2. Android мепурсад: **«Allow from this source»** → иҷозат диҳед (танҳо барои
   ҳамон барномае, ки файлро кушод).
3. **Install** → **Open**.
4. Агар Play Protect огоҳӣ диҳад — **Install anyway** (барои барномаҳои
   худсохта муқаррарӣ аст).

Build-и debug бо package-и `ai.zloy.app.debug` насб мешавад, release бо
`ai.zloy.app` — ҳар ду якҷоя зиндагӣ карда метавонанд.

---

## Қадами 5 (ихтиёрӣ) — Backend бо AI-и воқеӣ

Бе backend барнома кор мекунад (қоидаҳои offline), аммо барои AI:

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env
# дар .env: OPENROUTER_API_KEY=... ва OPENROUTER_MODEL=google/gemma-4-31b-it:free
uvicorn app.main:app --port 8000
```

Сипас дар барнома: **Settings → General → Backend URL** →
`http://<IP-и-компютер>:8000` → **Save & test**.

Калиди API ҳеҷ гоҳ дар барнома нест ва ба git намеравад (`.env` git-ignored аст).

---

## Хатоҳо ва ҳалли онҳо

| Хато | Ҳал |
|---|---|
| `git push` паролро қабул намекунад | Ба ҷои парол **токен**-и `repo`-ро истифода баред |
| Actions workflow-ро намебинад | `.github/workflows/` бояд дар решаи репозиторий бошад |
| `flutter pub get` fail | `app/pubspec.lock` бояд commit шуда бошад (дар zip ҳаст) |
| `Unsupported class file major version` | Workflow JDK 17-ро истифода мебарад; онро иваз накунед |
| `OutOfMemoryError` дар Gradle | `app/android/gradle.properties` → `-Xmx4G` (дар CI кифоя аст) |
| Дар барнома «Backend is not configured» | Settings → General → Backend URL → Save & test |
| `503 model_unavailable` | Модели ройгон тамом шуд — дигарро интихоб кунед: `/api/v1/models/free` |
| Микрофон кор намекунад | Иҷозати микрофон, ё хизмати шинохти нутқ дар Android, ё танҳо нависед |

---

## Барои донистан

- **Тестҳо:** 79 тести Flutter + 133 тести backend гузаштаанд (санҷида шуда).
- **APK** ҳоло сохта нашудааст — онро аввалин бор GitHub Actions месозад
  (ин sandbox барои Gradle RAM надошт).
- **Release APK** бо debug key имзо мешавад, то вақте ки keystore-и худро дар
  Secrets илова кунед. Он барои насби оддӣ кор мекунад, аммо барои Google Play
  мувофиқ **нест**.
