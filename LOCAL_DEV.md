# Local development — quick reference

## One codebase, two platforms

Flutter uses **one** `lib/` folder. You do **not** write separate iOS and Android apps. The same Dart code runs on both; only native config (Firebase plist/json, permissions) differs.

---

## First-time run (after Phase 1 is coded)

```bash
cd /Users/SANSG/Desktop/veltra
flutter pub get
open -a Simulator
flutter run
```

---

## Daily workflow

```bash
cd /Users/SANSG/Desktop/veltra
flutter run          # pick device if multiple
# then in terminal:
#   r  = hot reload (UI tweaks)
#   R  = hot restart (state reset)
#   q  = quit
```

---

## See available devices

```bash
flutter devices
```

Examples:
- `iPhone 16 Pro (simulator)` — UI work, Firebase, most flows
- `Sanskar's iPhone (wireless)` — speech-to-text, haptics, NFC later

---

## When to use a physical iPhone

| Phase | Simulator OK? | Phone needed? |
|-------|-----------------|---------------|
| 1 Auth + UI | ✅ Yes | Optional |
| 2 Workers | ✅ Yes | Optional |
| 3 Scan + voice | ⚠️ Use manual picker | ✅ For speech match |
| 4–5 Polish | ✅ Mostly | ✅ For final demo rehearsal |

---

## Firebase setup (before Phase 1)

See [plans/phase-00-prerequisites.md](plans/phase-00-prerequisites.md)

Minimum:
1. Enable Email/Password auth
2. Create Firestore database
3. Register iOS + Android apps in Console
4. Run `flutterfire configure` in project root

---

## Common fixes

```bash
flutter clean && flutter pub get && flutter run
cd ios && pod install && cd ..
flutter doctor -v
```

---

## Plans

Say **"code phase N"** → agent follows [plans/phase-0N-*.md](plans/)

Track progress: [plans/MASTER_PLAN.md](plans/MASTER_PLAN.md)

Design: [DESIGN.md](DESIGN.md)
