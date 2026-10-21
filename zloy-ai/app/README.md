# ZLOY.AI — Flutter client

This is the Android client. Project-wide documentation, build instructions,
signing notes and the honest status report live in the repository root:

**→ [`../README.md`](../README.md)**

Quick checks from this folder:

```bash
flutter pub get
flutter analyze
flutter test
```

The optional live test against a running backend:

```bash
ZLOY_API_URL=http://127.0.0.1:8000 flutter test test/integration/live_backend_test.dart
```
