# Phase 5 — Settings, Polish & Demo Readiness

> **Goal:** Complete settings, TTS voice confirmation, animations polish, privacy page, demo mode — competition-ready mockup.

---

## Prerequisites

- Phase 4 ✅ complete

---

## Dependencies

```bash
flutter pub add flutter_tts
flutter pub add share_plus
flutter pub add package_info_plus
```

---

## Settings screen (full)

Grouped glass sections:

### Account
- Email display (read-only)
- Logout

### Crew
- Link to manage workers (→ Crew tab)
- "Load demo crew" button (if empty)
- Worker count summary

### Shift
- Display current shift start time
- "End shift" button (manual reset — optional for demos)
- Tomorrow auto-resets via ShiftService

### Developer / Demo (collapsible)
- Force mock scan outcome: GREEN | AMBER | RED
- Toggle TTS on/off

### Sync & About
- Sync status with last synced time
- Privacy policy (static markdown in app)
- App version from `package_info_plus`

| File | Purpose |
|------|---------|
| `lib/features/settings/screens/settings_screen.dart` | Full layout |
| `lib/features/settings/screens/privacy_screen.dart` | Static privacy text |
| `lib/services/tts_service.dart` | "Jake. Green." on results |

---

## Voice confirmation (TTS)

After results shown (optional, on by default):
- Speak: `"{workerName}. {status}."`
- Uses `flutter_tts` — works on simulator and device
- Lighter than Vosk STT; complements speech **input** from Phase 3

---

## Share result (RED)

Alert button:
- `share_plus` shares text: `Veltra Alert — {name} — RED — Rest 15 min in shade — {timestamp}`

---

## Animation polish pass

Apply across app:
- Scan button idle pulse (2s loop)
- Tab transitions via shell
- List stagger on crew load
- Results slide-up entrance
- Nav pill active indicator animation

Use `flutter_animate` per DESIGN.md timing table.

---

## Privacy policy content (minimal)

Static screen covering:
- What data is collected (scan metrics, worker names)
- Stored locally + Firebase
- Not a medical device — screening only
- Contact email placeholder

---

## App icon & name (optional)

- Update `pubspec.yaml` app title to **Veltra**
- Replace default Flutter launcher icon later

---

## Acceptance criteria

- [x] Settings fully navigable, matches DESIGN.md
- [x] TTS speaks result on scan complete
- [x] Share works on RED Alert
- [x] Privacy policy accessible
- [x] Version number shown
- [x] Demo force RED/AMBER/GREEN works from Settings
- [x] App feels smooth — no jank on tab switch
- [x] Full demo path works: signup → add crew → scan → voice → result → log → see history

---

## Testing (you) — full demo rehearsal

Run this script once before showing anyone:

1. Fresh signup (or use test account)
2. Load demo crew OR add 3 workers
3. Scan → say name → GREEN result → Log & Next
4. Force AMBER in settings → scan again
5. Check crew filters and worker detail chart
6. Toggle airplane mode → scan still works → sync when back online
7. Settings → verify sync timestamp updated

---

## Firebase Console actions (you)

- Optional: switch Firestore from test mode to production rules (already scoped in Phase 1)
- Review Auth users — delete test accounts if needed

---

## Post-MVP roadmap (don't code yet)

| Item | When |
|------|------|
| TFLite model | After athletic trials |
| Real NFC | When Lucas has hardware |
| Vosk offline STT | Before field pilot |
| React dashboard | Separate sprint |
| OSHA PDF | Phase 6+ |

---

## Competition demo checklist

- [ ] iPhone charged, app installed via `flutter run --release` on device
- [ ] Test account credentials ready
- [ ] Demo crew pre-loaded
- [ ] Speech tested in noisy environment
- [ ] Force RED demo rehearsed
- [ ] Firestore showing live data (optional screen recording of Console)

---

## Done 🎉

Mark all phases ✅ in [MASTER_PLAN.md](./MASTER_PLAN.md)
