# DuoBozor — барномаи мобилӣ (Expo SDK 51 / RN 0.74)

```bash
npm ci
npm test              # 60 санҷиши мантиқи пул
npx expo start        # дар Expo Go
```

APK: `.github/workflows/duobozor-apk.yml` (JDK 17 + prebuild + assembleRelease).

**Экранҳо:** Auth · Home · Search · Product · GroupBuy · Cart · Checkout ·
Orders · OrderDetail · Wallet · Profile · Seller · Admin

**Ҳолат:** ҳама дар `src/store.js` (AppProvider) — screens танҳо `useApp()`-ро мехонанд.
**Пул:** `src/lib/money.js`, тийин, double-entry ledger.
**Забон:** `src/i18n.js` — tj + ru.
