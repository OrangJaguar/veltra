# Plan 1 — Local foundation

> **Status:** Done.
> **Goal:** The phone can store a crew, a check-in window, and a check-in without a network, without touching baselines or the cloud queue. The current app still opens and the old scan flow still runs.

Say **"code plan 1"** to start. Do not start plan 2 in the same pass.

## Adjusted before coding

The plan still matches the code. Three seams are tighter than the original wording:

- Quick Demo calls the new seed on every entry. An upgraded phone may already have Jake, Maria, Dev, Chris, and Sam, so “seed only when the worker list is empty” would skip the new crew. Those five rows stay. Settings → load demo crew still adds them.
- The three new workers use stable ids (Avery, Blake, Casey) and are inserted without a `sync_queue` row. Each gets a default baseline row so the existing scan screen can still open them. A check-in save does not change that baseline.
- Demo config is one device-local row. Firebase init is caught. If it fails, auth stays signed-out and Quick Demo still opens. Sign-in shows a connection error until Firebase is available.
- `google_fonts` moved to 6.x. Version 4 does not compile on the Flutter 3.47.9 SDK this Mac uses. Plus Jakarta Sans is unchanged.

## In scope

- SQLite upgrade from schema v4. Fresh install and upgraded install both keep working. Existing workers, scans, baselines, and sync-queue rows stay.
- New local records:
  - **Crew** — stable id, name, optional site label.
  - **Worker membership** — existing worker rows gain a crew id, active or archived, and an optional pod id. Old workers with no crew still load.
  - **Window** — stable id, crew id, opened time, optional closed time. At most one open window per crew.
  - **Check-in** — stable id, crew, worker, window, capture time stored in UTC, source, optional pod id, nullable measurements, per-channel availability, optional weather context. Units live on the field names: forehead °C, strip volume µL, conductivity µS/cm, rate µL/min.
  - **Attempt** — outcome and error, separate from a saved check-in.
  - **Follow-up** — worker, window, request time, optional note. Used by plan 3. The table exists now so plan 3 does not migrate again.
  - **Demo config** — selected crew, role, worker, scan source, scenario. Role values: `worker`, `supervisor`, `demoAdmin`.
- One save function. It writes the check-in in a single transaction. A second call with the same attempt id does not insert a second row.
- Demo check-ins do not update baselines and do not insert `sync_queue` rows.
- Quick Demo seeds three fictional workers and one open window under a stable demo crew id, and does not duplicate them on the next launch. Keep an empty-crew create function for plan 3. The five-name seed (Jake, Maria, Dev, Chris, Sam) stays available only for the old foreman demo if that path is still reachable. The new seed is three clearly fictional names and is the one plan 2 uses.
- App launch does not die when Firebase cannot reach the network. Real sign-in still uses Firebase when it is available.
- Tests for: migration, one open window, partial check-in (temperature set, volume and conductivity null), duplicate attempt id, demo save does not enqueue sync.

## Out of scope

- New screens, role switcher, and the HTML phone (plan 2)
- Scenario catalog, pod mismatch rules, roster status wording, reset (plan 3)
- Any NFC plugin, entitlement, or tag parsing (plan 4)
- Deleting the old scan, voice, or risk-engine code

## Files

| Area | Change |
|------|--------|
| `lib/services/database_schema.dart`, `lib/services/database_service.dart` | Version bump and explicit migration |
| `lib/models/`, `lib/repositories/` | Check-in, window, crew, attempt, demo config. Keep `ScanRecord` for old rows. |
| `lib/main.dart`, `lib/features/auth/screens/login_screen.dart`, `lib/services/demo_data_service.dart` | Offline-tolerant startup and the new three-worker seed |
| `test/` | The cases above |

## Acceptance

- Quick Demo opens with the network off after a force-quit.
- The three seeded workers and the open window are still there after a restart.
- A test insert of a temperature-only check-in round-trips through SQLite with the other channels null.
- Inserting the same attempt twice yields one check-in.
- That insert adds nothing to `sync_queue` and does not change the worker baseline.
- An existing v4 database still opens and still shows its old workers and scans.
- The current Scan / Crew / Settings UI still navigates.

## Notes for the next plan

Plan 2 should call `CheckInRepository.saveCheckIn` and stop sending demo check-ins through `scan_repository`’s baseline and cloud path. The seeded crew id is `veltra-demo-crew`. Workers are Avery, Blake, and Casey. Display times in local time. Capture time is already stored in UTC. Read role and selected worker from `demo_config`.
