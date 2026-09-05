# Veltra — Master Build Plan

> Track progress here. Each phase has its own detailed plan file. Say **"code phase N"** to implement that phase.

## Product decisions (locked)

| Decision | Choice |
|----------|--------|
| Brand | **Veltra** |
| Risk engine (MVP) | **Dart rule engine** (port of `veltra_ml/generate_model.py` → `label_risk()`) |
| Scan flow | **Scan first** → voice match worker name → results |
| Worker ID (MVP) | **`speech_to_text`** — phone STT, match against crew roster |
| Shift timer | **Auto-start on first scan of the day** |
| Weather | **Open-Meteo** (free, no API key) |
| NFC hardware | **Deferred** — `MockScanDataSource` now, swap later |
| ML / TFLite | **Deferred** — after athletic trials |
| Backend | **Firebase** (Auth + Firestore) on free Spark plan |
| Local DB | **SQLite** (`sqflite`) offline-first |
| State | **Riverpod** |
| Design | See [`DESIGN.md`](../DESIGN.md) — warm construction glass, not dark corporate |

---

## Phase index

| Phase | File | Status | Depends on |
|-------|------|--------|------------|
| **0** | [phase-00-prerequisites.md](./phase-00-prerequisites.md) | ✅ User setup done | — |
| **1** | [phase-01-skeleton-auth.md](./phase-01-skeleton-auth.md) | ✅ Done | Phase 0 |
| **2** | [phase-02-data-layer.md](./phase-02-data-layer.md) | ✅ Coded — test workers + sync | Phase 1 |
| **3** | [phase-03-mock-scan-pipeline.md](./phase-03-mock-scan-pipeline.md) | ✅ Done | Phase 2 |
| **4** | [phase-04-crew-history.md](./phase-04-crew-history.md) | ✅ Done | Phase 3 |
| **5** | [phase-05-settings-polish.md](./phase-05-settings-polish.md) | ✅ Done | Phase 4 |

**Status key:** ⬜ Not started · 🟡 In progress · ✅ Done

---

## Architecture overview

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/           # DESIGN.md tokens
│   ├── widgets/         # GlassCard, VeltraNavBar, buttons
│   ├── constants/
│   └── utils/
├── features/
│   ├── auth/
│   ├── onboarding/
│   ├── scan/
│   ├── crew/
│   └── settings/
├── models/
├── services/
│   ├── mock_scan_service.dart
│   ├── risk_engine.dart
│   ├── weather_service.dart
│   ├── shift_service.dart
│   ├── baseline_service.dart
│   ├── speech_worker_matcher.dart
│   └── sync_service.dart
├── repositories/
└── providers/
```

---

## Firebase structure

```
users/{uid}
  email, crewName, createdAt

users/{uid}/workers/{workerId}
  name, employeeId, role, nfcId, createdAt

users/{uid}/workers/{workerId}/baselines/current
  muSalinity, sigmaSalinity, muTemp, sigmaTemp, shiftCount, acclimatization

users/{uid}/scans/{scanId}
  workerId, timestamp, skinTemp, sweatRate, salinity, sweatVolume,
  wbgt, status, recommendation, zScore, tempRate, elapsedHours

users/{uid}/meta/shift
  currentShiftStartedAt, lastScanDate
```

---

## Deferred (post-MVP)

- Real NFC (`flutter_nfc_kit`)
- Offline Vosk voice
- TFLite XGBoost inference
- React safety director dashboard
- OSHA PDF export
- FCM push on RED
- Worker photos / Storage uploads
- CSV export
- Multi-site management

---

## How to use these plans

1. Complete **Phase 0** (your machine + Firebase setup)
2. Say **"code phase 1"** → agent implements `phase-01-skeleton-auth.md`
3. Run **Testing** section at bottom of that phase doc
4. Mark phase ✅ in this file
5. Repeat for phases 2–5

---

## Related docs

- [`DESIGN.md`](../DESIGN.md) — UI/UX system
- [`VELTRA.md`](../VELTRA.md) — product context
- [`software_plan.pdf`](../software_plan.pdf) — original software spec
