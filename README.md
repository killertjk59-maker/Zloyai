# 📱 DuoBozor APK — дар ҳамин репозиторий

Барномаи нави **DuoBozor** (гурӯҳхаридии тоҷикӣ + escrow) дар папкаи [`duobozor/`](duobozor/) ҷойгир аст.

- **APK-и омода:** [Releases → duobozor-1.0.0.apk](https://github.com/killertjk59-maker/Zloyai/releases/latest)
- CI: `.github/workflows/duobozor-apk.yml` · Бот: `.github/workflows/duobozor-bot.yml`
- Дастур: [`duobozor/README.md`](duobozor/README.md)

---

# ZLOY.AI — an AI language tutor with attitude

A complete Android language-learning app: a Flutter (Material 3, dark) client that
works offline, an honest pronunciation checker, a custom animated mascot, and an
optional self-hosted FastAPI backend that talks to OpenRouter.

**Target language:** English · **Explanation languages:** Tajik, Russian, English ·
**Levels:** A1 → C1 · **Personalities:** Normal, Strict, Roast, Shout (profanity toggleable).

> This README is written to be read on a phone. Every command is copy-pasteable.
> There is a Tajik quick start at the very bottom.

---

## 1. What was actually verified (and what was not)

Honest status — no marketing:

| Thing | Status | How it was checked |
|---|---|---|
| Flutter code compiles, no analyzer warnings | ✅ verified | `flutter analyze` → **No issues found!** |
| Flutter unit + widget tests | ✅ verified | `flutter test` → **79 passed, 4 skipped** (the 4 are opt-in live-backend tests) |
| Code formatting | ✅ verified | `dart format --set-exit-if-changed lib test` → clean |
| Python backend lint | ✅ verified | `ruff check .` and `ruff format --check .` → clean |
| Backend tests | ✅ verified | `pytest` → **133 passed** |
| App ↔ backend contract, real HTTP | ✅ verified | `ZLOY_API_URL=http://127.0.0.1:8011 flutter test test/integration/live_backend_test.dart` → **4 passed** against a real running uvicorn |
| Backend end-to-end script | ✅ verified | `backend/scripts/smoke_test.sh` → all checks passed (mock provider) |
| APK / AAB built | ❌ **not yet** | A local build **was attempted** in this sandbox: JDK 17, Android SDK 36 and AGP 9.1 all installed and configured, but `flutter build apk --debug` ended with *"Gradle build daemon disappeared unexpectedly"* — the sandbox has 2 GB RAM and no swap. GitHub Actions (7 GB) builds them; that workflow has not run yet because there is no remote repo. |
| Running on a real phone | ❌ **not yet** | No Android device or emulator was available here. |
| Real OpenRouter model answering | ❌ **not yet** | No API key was available. The OpenRouter path is tested against a scripted HTTP transport (21 tests), not a live model. |
| Google Play upload | ❌ out of scope | The release APK is signed with the **debug** key unless you add your own keystore. |

So: the app is **finished and tested as code**; the installable `.apk` is produced by
CI the first time you push this repo to GitHub (section 5).

---

## 2. What the app does

### Screens (19)

| # | Screen | What it does |
|---|---|---|
| 1 | Splash | Boots, restores your local profile, then routes to onboarding or home |
| 2 | Onboarding | Language, explanation language, level, goals, learning style, daily goal |
| 3 | Home | Mascot, streak, today's goal, entry points to every mode |
| 4 | Tutor (chat) | Send a sentence or message; get a correction, rule, examples, exercise |
| 5 | Voice | Speak instead of typing; edit the recognised text before sending |
| 6 | Practice hub | All exercise modes in one grid |
| 7 | Practice runner | Runs offline exercises, records real results |
| 8 | Grammar | Grammar rules in your explanation language |
| 9 | Vocabulary | Word list with translations |
| 10 | Reading | Short texts with a tap-to-translate style flow |
| 11 | Daily challenge | One bounded set of questions per day |
| 12 | Progress | Real counters only: XP, streak, accuracy, mistakes |
| 13 | History | Your previous tutor exchanges (stored on the device) |
| 14 | Settings hub | Root of the six settings screens |
| 15 | Personality | Normal / Strict / Roast / Shout + profanity toggle |
| 16 | Voice settings | TTS rate/pitch, auto-speak, platform recognition opt-out |
| 17 | General settings | Backend URL + "Save & test", offline-only mode |
| 18 | Privacy | Exactly what is stored where, in plain words |
| 19 | About | Version, licences, honest limitations |

### Learning engine
- **4 personalities.** Normal, Strict, Roast, Shout. Every mode is enforced by the
  backend prompt *and* by the mock provider, and the jokes are always aimed at the
  **mistake**, never at the person.
- **Profanity toggle.** Off = no swearing at all. On = mild "damn/hell" level,
  still never a slur, still never at the learner.
- **Languages.** English is the target language; explanations in Tajik, Russian or
  English. Every correction, rule name and example is served in the chosen
  explanation language.
- **5 levels.** A1 → C1 with level-specific guidance sent to the model.
- **Offline engine.** 17 deterministic grammar rules in `app/lib/data/offline_rules.dart`
  (en/ru/tg) so the app teaches something with no network and no key.
- **Pronunciation.** Uses the platform speech recogniser and compares what it heard
  with the target phrase. When the platform gives no confidence value the app says
  **"no score available"** instead of inventing a number.

### Voice
- Android `SpeechRecognizer` via `speech_to_text`; microphone permission is requested
  **only when you tap the mic**, and denial is handled without crashing.
- TTS via `flutter_tts` (rate/pitch sliders, auto-speak toggle).
- No raw audio is stored by the app. Note: Android's recogniser may send audio to the
  platform provider — the privacy screen says so, and you can turn it off.

### Mascot
A custom-painted (no image assets) mascot with **9 states** — idle, listening,
thinking, happy, strict, roasting, shouting, sad, celebrate — animated with
`AnimatedBuilder`/`CustomPainter`, driven by what the tutor is actually doing.

---

## 3. Project layout

```
.
├── app/                        Flutter client (Android)
│   ├── lib/
│   │   ├── app/                ZloyApp, routes, provider tree
│   │   ├── theme/              Material 3 dark theme + design tokens
│   │   ├── models/             Domain models + enums (wire codes live here)
│   │   ├── services/           backend client, offline tutor, speech, TTS, storage
│   │   ├── data/               Offline rules and bundled content
│   │   ├── state/              ChangeNotifiers: settings, progress, tutor
│   │   ├── widgets/            Mascot, chat bubbles, mic button, shared UI
│   │   └── features/           The 19 screens
│   └── test/                   Unit, widget and (opt-in) live-backend tests
├── backend/                    FastAPI service
│   ├── app/
│   │   ├── api/                /api/v1 routes
│   │   ├── core/               settings, typed errors, rate limiting
│   │   ├── schemas/            Pydantic request/response contracts
│   │   └── services/           prompts, offline checker, ai/{base,openrouter,mock}
│   ├── tests/                  133 tests, no network needed
│   └── scripts/smoke_test.sh   End-to-end curl checks
└── .github/workflows/          ci.yml + android-build.yml
```

---

## 4. Run the backend locally

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt
cp .env.example .env               # then edit .env if you have an OpenRouter key
uvicorn app.main:app --reload --port 8000
```

Open <http://127.0.0.1:8000/docs> for interactive API docs.

```bash
curl -s http://127.0.0.1:8000/api/v1/health
# {"status":"ok","provider":"mock","model":"mock-rules-v1","mock":true,...}
```

### With a real AI (free OpenRouter model)

1. Create a free key at <https://openrouter.ai/keys>.
2. Check which models are free **right now** — never trust a hard-coded list:

   ```bash
   curl -s https://openrouter.ai/api/v1/models \
     | python3 -c "import json,sys; [print(m['id']) for m in json.load(sys.stdin)['data'] if m['pricing']['prompt'] in ('0','0.0')]"
   ```

   Or ask this backend: `curl -s http://127.0.0.1:8000/api/v1/models/free`
3. Put the key in `backend/.env` (never in the app, never in git):

   ```ini
   OPENROUTER_API_KEY=sk-or-v1-...your key...
   OPENROUTER_MODEL=google/gemma-4-31b-it:free
   ```
4. Restart uvicorn. `/api/v1/health` now reports `"provider":"openrouter","mock":false`.

Free models rotate without notice. If a model disappears you get a clear
`503 model_unavailable` from the API — pick another slug; nothing else changes.

### Deploy it for free (optional)

The backend is a normal ASGI app, so any free container host works. Included:
`Dockerfile`, `Procfile`, and `render.yaml` (Render free tier — verify current limits
yourself; free instances sleep when idle). Set `OPENROUTER_API_KEY` in the host's
dashboard, never in the repo. After deploying, put the public `https://…` URL into
**Settings → General → Backend URL** in the app and tap **Save & test**.

---

## 5. Get the APK onto your phone (no Android SDK needed)

The GitHub Actions workflow builds all three artifacts on GitHub's free runners.

### One-time: push this project to GitHub

From a terminal on a computer (or Termux on the phone):

```bash
cd <this folder>
git init -b main
git add .
git commit -m "ZLOY.AI: Flutter app + FastAPI backend"
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

If `git push` asks for a password, use a **Personal Access Token** (GitHub → Settings →
Developer settings → Tokens), not your account password.

> Nothing here deletes history or force-pushes: `git init` + `git push` on a fresh
> repository. If your repo already exists with commits you want to keep, use
> `git pull --rebase origin main` before pushing, never `--force`.

### Then: download the APK

1. Open your repo on GitHub → **Actions** tab.
2. Click the newest **“Android build”** run (it starts automatically after the push;
   if not, press **Run workflow**, which allows `all` / `debug-only` / `release-only`).
3. Wait for the green check (first run ≈ 4–8 minutes; later runs are faster).
4. Scroll to **Artifacts** and download:
   - **`zloy-debug-apk`** → contains **`zloy-debug.apk`** ← start with this one
   - **`zloy-release-apk`** → contains **`zloy-release.apk`**
   - **`zloy-aab`** → contains **`zloy.aab`** (Play Store format)
5. Artifacts download as `.zip`. On the phone, open the zip with the Files app and
   extract it (GitHub only zips artifact downloads; the workflow itself produces the
   exact `.apk` / `.aab` names).

### Install on Android

1. Tap `zloy-debug.apk`.
2. Android asks to allow installs from your browser/file manager → allow it for that
   app only.
3. Tap **Install** → **Open**.
4. If Play Protect shows a warning (normal for self-signed apps), choose
   **Install anyway**. If it refuses, temporarily disable Play Protect, install, then
   re-enable it.

The debug build has package id `ai.zloy.app.debug`, the release build `ai.zloy.app`,
so you can install both side by side.

### Signing (read before you think about Play Store)

Without extra setup, **`zloy-release.apk` is signed with Flutter's debug key**. It
installs and runs fine, but Google Play will reject it, and it must never be
distributed as an official release.

To sign properly (still free), create a keystore once:

```bash
keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias zloy
base64 -w0 release-keystore.jks > keystore.b64   # copy this text
```

Then add four repository secrets (GitHub → Settings → Secrets and variables → Actions):
`ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
`ANDROID_KEY_PASSWORD`. The workflow restores the keystore, never prints it, and the
build summary states the real signing status. Locally, the same thing works via
`app/android/key.properties` (git-ignored).

Publishing to Play additionally requires a developer account, a store listing and
Google's review. That is **not** included here and nothing in this repo bypasses it.

---

## 6. Run the app from source (optional, needs a computer)

```bash
cd app
flutter pub get
flutter run                     # needs an Android device or emulator
flutter build apk --debug       # or build it yourself
```

Toolchain used here and in CI: **Flutter 3.47.7 / Dart 3.13.5, JDK 17, AGP 9.1.0,
Gradle 9.3.1, Kotlin 2.4.0**, `minSdk 23`.

---

## 7. Tests

```bash
# Flutter
cd app
flutter analyze
flutter test

# the opt-in live test against a real backend
cd ../backend && uvicorn app.main:app --port 8011 &
cd ../app && ZLOY_API_URL=http://127.0.0.1:8011 flutter test test/integration/live_backend_test.dart

# Backend
cd ../backend
source .venv/bin/activate
ruff check . && ruff format --check .
pytest -q
./scripts/smoke_test.sh http://127.0.0.1:8000
```

Coverage highlights:

| Suite | Count | Focus |
|---|---|---|
| Flutter unit | 51 | models, offline engine, backend client, controllers, pronunciation |
| Flutter widget | 28 | onboarding, navigation, tutor, practice, settings, 320dp small screen |
| Flutter live (opt-in) | 4 | real HTTP against a running backend |
| Backend | 133 | rules, prompts, OpenRouter error mapping, rate limiting, no-secret-leak |

The small-screen tests run at **320×568** and text scale **1.3** — real overflow bugs
were found and fixed that way (home tiles, voice buttons, onboarding goal chips).

---

## 8. Security & privacy

- **No API key in the app.** `BackendClient` only knows a URL; it never sends an
  `Authorization` header. The OpenRouter key lives only in the backend environment.
- **`.env` is git-ignored**, `key.properties` and `*.jks` too, and CI fails if any of
  them ever gets tracked.
- **Local-only progress.** Profile, settings, XP, streaks and mistakes live in
  `SharedPreferences` on the device. There is no account, no cloud sync, no analytics,
  no ads.
- **Rate limiting** (default 30 requests/minute per client) protects the shared model
  quota; `/api/v1/health` is never rate-limited.
- **Errors are typed and safe**: the API returns short codes (`rate_limited`,
  `model_unavailable`, `provider_not_configured`, …) and never upstream stack traces
  or credentials.
- **Degrades gracefully**: with no key the backend answers honestly from the rule
  engine and labels every answer `source: "mock"`; with no backend at all the app
  keeps working from its offline rules.

---

## 9. Honest limitations

1. The **mock provider is not an AI**. It is a rule table. Answers are labelled `mock`
   in the API response and shown as such in the app.
2. The **offline checker only knows 17 rules** (18 in the backend incl. the singular
   noun rule). If it finds nothing it says so instead of inventing an error.
3. **No pronunciation score** is produced when the platform recogniser gives no
   confidence value.
4. Personalities are **textual**. "Shout" means capitalised, energetic text — the app
   never claims the voice actually shouts.
5. **Free model IDs rotate.** The app never assumes a model stays free; the backend
   exposes `/api/v1/models/free` for a live check.
6. Rate limiting is **in-process**, so it is per-instance. Fine for one free instance,
   not a distributed limiter.
7. The SQLite `DATABASE_URL` setting is reserved for future server-side features; no
   endpoint uses a database today.

---

## 10. Troubleshooting

| Symptom | Fix |
|---|---|
| Actions run fails at `flutter pub get` | Check `app/pubspec.yaml` is committed; run `flutter pub get` locally to regenerate `pubspec.lock`. |
| Gradle fails with `Unsupported class file major version` | The workflow pins **JDK 17**; don't switch to 21+ with AGP 9. |
| Build fails with `OutOfMemoryError` | `app/android/gradle.properties` sets `-Xmx4G`; raise it if you have more RAM. |
| App says “Backend is not configured” | Settings → General → Backend URL, then **Save & test**. Offline mode still works. |
| `503 model_unavailable` | Your `OPENROUTER_MODEL` is gone or no longer free — pick another slug from `/api/v1/models/free`. |
| `429 rate_limited` | You hit the per-minute limit; wait and retry, or raise `RATE_LIMIT_REQUESTS`. |
| Mic does nothing | Grant microphone permission, make sure a speech service is installed (Android Settings → System → Languages → Speech), or just type. |

---

## 11. Тез оғоз (Tajik quick start)

**Барнома чӣ кор мекунад:** забони англисиро бо 4 хислат (Normal, Strict, Roast,
Shout) таълим медиҳад, талаффузро месанҷад, ва бе интернет ҳам кор мекунад.

**Барои гирифтани APK:**

1. Ин папкаро ба GitHub гузоред:

   ```bash
   git init -b main
   git add .
   git commit -m "ZLOY.AI"
   git remote add origin https://github.com/<номи-шумо>/<номи-репозиторий>.git
   git push -u origin main
   ```

2. Дар GitHub ба **Actions** → **Android build** дароед ва интизор шавед, ки чекҳо
   сабз шаванд (4–8 дақиқа).
3. Дар поёни саҳифа **Artifacts** → **`zloy-debug-apk`**-ро зеркашӣ кунед.
4. Файли `.zip`-ро кушоед → `zloy-debug.apk` → клик кунед → **Install**.
5. Агар Android иҷозат пурсад, **Allow from this source** ва баъд **Install**-ро
   пахш кунед. Огоҳии Play Protect муқаррарӣ аст — **Install anyway**.

**Backend (ихтиёрӣ, барои AI):**

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env      # калиди OpenRouter-ро ин ҷо гузоред
uvicorn app.main:app --port 8000
```

Баъд дар барнома: **Settings → General → Backend URL** → `http://<IP-и-компютер>:8000`
→ **Save & test**. Бе калид ҳам backend кор мекунад, аммо ҷавобҳо `mock` ҳастанд.

**Муҳим:** калиди API ҳеҷ гоҳ дар барнома ё репозиторий нест — танҳо дар `.env`-и
backend, ки ба git дохил намешавад.

---

## 12. Licence

MIT — see [`LICENSE`](LICENSE). Third-party packages keep their own licences; the
in-app **About → Open source licenses** screen lists them from the actual build.
