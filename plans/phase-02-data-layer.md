# Phase 2 — Data Layer (SQLite + Firestore + Workers)

> **Goal:** Offline-first worker storage, CRUD UI, sync queue to Firestore, baseline docs per worker.

---

## Prerequisites

- Phase 1 ✅ complete
- Firestore rules deployed

---

## Dependencies

```bash
flutter pub add sqflite path
flutter pub add uuid intl
flutter pub add connectivity_plus
```

---

## Data models

| File | Purpose |
|------|---------|
| `lib/models/worker.dart` | Worker model + JSON |
| `lib/models/baseline.dart` | Baseline stats model |
| `lib/models/scan_record.dart` | Scan model (used Phase 3, define now) |
| `lib/models/sync_status.dart` | Enum: synced, pending, failed |

### Worker fields
```dart
id, name, employeeId?, role?, nfcId?, createdAt, lastStatus?, lastScanAt?
```

### Baseline fields (defaults for new worker)
```dart
muSalinity: 45.0, sigmaSalinity: 10.0
muTemp: 36.8, sigmaTemp: 0.4
shiftCount: 0, acclimatization: 1.0
```

---

## SQLite

| File | Purpose |
|------|---------|
| `lib/services/database_service.dart` | Open DB, migrations v1 |
| `lib/services/database_schema.dart` | Table DDL |

Tables:
- `workers` — mirror of worker model + `synced` flag
- `baselines` — one row per worker_id
- `scans` — for Phase 3, create table now
- `sync_queue` — pending Firestore writes

---

## Repositories

| File | Purpose |
|------|---------|
| `lib/repositories/worker_repository.dart` | CRUD local + enqueue sync |
| `lib/repositories/baseline_repository.dart` | Read/update baselines |
| `lib/services/sync_service.dart` | Push queue to Firestore when online |

Sync strategy:
1. **Write local first** (SQLite)
2. Add row to `sync_queue`
3. `SyncService` listens to connectivity → flushes queue
4. Firestore paths match MASTER_PLAN.md

---

## Firestore writes

```
users/{uid}/workers/{workerId}
users/{uid}/workers/{workerId}/baselines/current
```

On worker create → create baseline doc with defaults.

---

## Providers (Riverpod)

| File | Purpose |
|------|---------|
| `lib/providers/worker_providers.dart` | `workersListProvider`, CRUD notifiers |
| `lib/providers/sync_providers.dart` | Sync status stream |

---

## UI — Crew tab

| File | Purpose |
|------|---------|
| `lib/features/crew/screens/crew_screen.dart` | Replace placeholder |
| `lib/features/crew/screens/add_worker_screen.dart` | Form: name, optional employee ID, optional NFC ID |
| `lib/features/crew/screens/worker_detail_screen.dart` | Stub: name + "No scans yet" (Phase 4 fills history) |
| `lib/features/crew/widgets/worker_list_tile.dart` | Glass row, status dot (gray if no scans) |

Features:
- List all workers from SQLite (reactive)
- FAB or header "+" → Add Worker
- Tap worker → detail stub
- Swipe or menu → delete worker (confirm dialog)
- Empty state: friendly illustration text "Add your first worker"

---

## UI — Settings (partial)

| File | Purpose |
|------|---------|
| Update `settings_screen.dart` | Add sync status indicator (Synced / Pending / Offline) |

---

## Seed demo crew (optional toggle)

| File | Purpose |
|------|---------|
| `lib/services/demo_data_service.dart` | Insert 5 demo workers if crew empty |

Demo workers: Jake, Maria, Dev, Chris, Sam — triggered once from Settings "Load demo crew" button (dev-friendly).

---

## Acceptance criteria

- [ ] Add worker → appears in Crew list immediately (offline)
- [ ] Worker persists after app restart
- [ ] Firestore shows worker under `users/{uid}/workers` when online
- [ ] Baseline doc created with defaults
- [ ] Delete worker removes local + Firestore
- [ ] Sync indicator reflects offline/online state
- [ ] Demo crew button adds 5 workers

## Implemented (Phase 2 code)

- SQLite: `workers`, `baselines`, `scans`, `sync_queue` tables
- Offline-first worker CRUD + sync queue → Firestore
- Crew tab: list, add, detail stub, delete with confirm
- Settings: live sync status + **Load demo crew** (Jake, Maria, Dev, Chris, Sam)
- Pull-to-refresh on crew list triggers sync

---

## Testing (you)

1. **Add worker offline**
   - Enable airplane mode on simulator (Features → Cellular → no connection, or macOS network off)
   - Add worker "Test User"
   - Confirm appears in list

2. **Sync online**
   - Disable airplane mode
   - Wait few seconds or pull-to-refresh if implemented
   - Check Firestore Console for worker doc

3. **Persistence**
   - Hot restart (`R`) → worker still listed

4. **Delete**
   - Delete worker → gone from app and Firestore

---

## Firebase Console actions (you)

- None new if rules from Phase 1 deployed
- Verify worker docs appear under your user path

---

## Not in Phase 2

- Mock scan
- Risk engine
- Speech
- Weather
- Scan history charts

---

## Next phase

**"code phase 3"** → [phase-03-mock-scan-pipeline.md](./phase-03-mock-scan-pipeline.md)
