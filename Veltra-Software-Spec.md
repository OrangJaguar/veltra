# Veltra software specification

Implementation brief for `OrangJaguar/veltra` · Source baseline `b2840f5` · November 2026

## 1. What to build

Build one Flutter app around a worker checking their own hard-hat sensor during a break. The worker opens Veltra, taps **Check in**, holds the phone near the pod, and sees whether the reading was saved. The supervisor opens the crew view and sees who checked in, who is still waiting, and whose reading needs a retry. The team can switch between Worker, Supervisor, and Demo Admin from the same installation.

The deliverable is a complete **local-first app with real NFC capability**. Crew setup, worker selection, pod assignment, check-ins, history, and role switching must run without an account or internet connection. Build the NFC reader and keep simulated scans available through the same check-in flow. Keep existing Flutter, Riverpod, SQLite, styling, and useful screens. Firebase setup, cloud permissions, remote crew joins, and cross-device syncing are a later implementation. Two installations have independent data until then.

| Path | What must work |
| --- | --- |
| Simulated scan | Deterministic sample or error scenario goes through the worker flow, local storage, and supervisor view. |
| Physical test tag | A real NFC tap reads a fixed sample record, validates it, saves it, and updates the roster. Values carry a visible **Test tag** label. |
| Sensor pod | A platform NFC session reads the board using its confirmed protocol. The app validates freshness, quality, and calibration before presenting sensor measurements. Until that protocol is confirmed, this path can detect a tag and report diagnostic details. |
| Future sync | The same check-in records have stable IDs and crew scope so a later backend can deliver them to a separate supervisor device. |

## 2. Screens and flows

### Crew setup and role switching

1. **Quick Demo** opens a seeded crew with three fictional workers and one active check-in window. The seeded crew and worker identities persist locally. Offer an empty local crew option for bench testing with the team's own labels.
2. **Crew setup** lets an admin create or rename a crew, add or edit workers, archive workers, select a site label, open or close a check-in window, and optionally assign a pod. Archived workers leave the active roster and keep their history.
3. **Select worker** shows active crew members. Remember the selected worker. Ask them to confirm their name when changing workers on a shared phone. The worker profile determines whose record is saved. A pod identifier can verify an assignment when available. An assigned pod presented by a different worker triggers a mismatch and no save. Expose pairing and reassignment in Demo Admin.
4. **Switch view** offers Worker, Supervisor, and Demo Admin. The two regular views share the selected crew and database. Demo controls live in a clearly labeled menu. Actual worker and supervisor access on separate devices will be enforced through later crew membership and backend authorization.

### Worker

- **Home:** Name, crew, active window, **Check in**, and the most recent check-in with time and source. Show a clear demo indicator for simulated or test-tag sessions. One primary action should fit a phone screen without scrolling.
- **Scan:** Tap **Check in** to start an NFC session or the selected fixture. Show **Hold phone near the pod**, then **Reading** or **Keep holding** while the board samples. Allow cancellation. The selected worker and window are fixed for that attempt.
- **Success:** Save locally before showing **Check-in saved**. Use a short haptic where supported. Show time, source, and the available measurements in an expandable panel. Partial readings identify which channels are unavailable. A fresh skin temperature can be useful even if the sweat strip is dry. A repeat check-in is deliberate and creates a new record.
- **Retry:** Explain the actual problem in plain language. Examples include **No tag found**, **Wrong pod for this worker**, **Hold the phone closer**, **Reseat the cartridge**, and **Couldn’t save**. Canceling can return quietly to Ready. A failed read never marks the worker checked in. Keep communication and hardware diagnostics in Demo Admin.
- **History:** Show this worker’s local check-ins. Keep measurement labels, times, and source visible. Missing values display as unavailable. Support a metric trend only when enough comparable readings exist.

### Supervisor

- **Crew overview:** Show active window, how many workers have checked in, and the active roster. Each row shows worker name, current-window status, latest check-in time, and source. Use **Waiting**, **Checked in**, and **Retry requested** or a secondary failed-attempt indicator where it adds context. After a window closes, **Missed** means no valid check-in was saved during that window. A later failed attempt must not erase an earlier valid check-in.
- **Worker detail:** Reuse worker profile and history components. Show latest available readings with units, contact or sensor-quality notes, and time. Keep a simple **Request a recheck** or **Log follow-up** action in the local workspace. A follow-up flag is a supervisor action. The local app shows it when the role is switched. Remote delivery belongs to the sync phase.
- **Windows:** Admin or supervisor opens or closes one window for the selected crew. Start with one active window per crew and one seeded demo window. If the worker has no open window, explain how to start one in the local demo. Use the window ID to calculate completion so yesterday’s reading does not count today.

### Demo Admin

| Control | Behavior |
| --- | --- |
| View and worker picker | Switch roles or workers using the same local crew. Seed three clearly fictional workers. |
| Crew, window, pod assignment | Manage demo crew and active window. Inspect or pair a known physical pod to a worker. Support an explicit unpaired bench test that writes diagnostics but does not change roster status. |
| Scan source | Select **Simulated**, **Physical test tag**, or **Sensor pod**. Keep the active source visible. A failed physical read stays a failure until the operator deliberately switches source. |
| Scenarios | Provide fixed **complete reading**, **temperature only**, **dry strip**, **poor cartridge contact**, and **timeout** fixtures. Keep manual fixture entry admin-only if it is retained. |
| NFC diagnostics | Show availability, tag technology, available identifier, read duration, result, frame version, and channel or contact status. Allow raw bytes in bench mode. Use a small recent-attempt list for testing. |
| Reset demo | Require confirmation and reset only the selected demo crew’s fixtures and demo records. Preserve other local data. |

## 3. Where each data field comes from

| Field | Source | What the app should store or show |
| --- | --- | --- |
| **Forehead skin temperature** | **T4** thermistor in the forehead strip, sampled by the pod’s ADC. | Store °C after the board or app applies the confirmed calibration. The second temperature field **T6/PTAT** in the draft is on-device temperature for diagnostics, separate from forehead and weather readings. |
| **Sweat accumulation** | **F3** electrode ladder. The pod senses changing impedance as sweat wets the channel. | Store a fill level or calibrated volume in **µL**. The original concept used ten steps of 2.5 µL. Use the actual cartridge calibration when available. Show local strip accumulation and saturation status. |
| **Sweat accumulation rate** | Derived in the app or firmware from change in calibrated strip volume over elapsed time. | Store **µL/min** when two valid points refer to the same worker, pod, and cartridge session. Withhold the rate on a first read, after a cartridge change, when volume decreases or is saturated, or when elapsed time is invalid. This is a local strip trend. |
| **Sweat conductance / conductivity** | **E5** electrodes measure electrical response in the wetted channel. | Use the calibrated unit agreed with hardware. Conductance uses a unit such as µS. Conductivity uses a unit such as µS/cm and needs a cell calibration. A dry or disconnected strip has an unavailable channel. An NaCl-equivalent concentration needs its own validated calibration. Keep the UI label **Sweat conductivity** or **Sweat conductance** consistent with the data you actually receive. |
| **Cartridge contact and board status** | Dock continuity loop, sensor status flags, supply voltage, and hardware or calibration revision if supported. | Separate retry conditions from individual unavailable channels and keep board voltage and raw counts in diagnostics. |
| **Outdoor temperature, humidity, and estimated WBGT** | Phone app’s weather service. The current code uses Open-Meteo air temperature and relative humidity, then estimates WBGT. | Store separately with source and fetch time. Label WBGT **Estimated**. Use cached context with its age, or show unavailable. The current hardcoded fallback belongs in simulated scenarios. Weather fetch never blocks a check-in. |
| **Worker, crew, time, window** | Local role selection and phone clock. | Store the phone’s capture time in UTC, and show local time in the UI. A firmware time field or counter can help establish freshness once its meaning is documented. It does not replace the phone timestamp. |

Treat raw ADC integers as counts until calibration gives them units. Avoid mixing the repo’s simulated sweat-rate and salinity values with calibrated pod values in one chart or baseline. Keep legacy scoring as a labeled simulated demonstration if it is useful. The live view should use capture and channel quality, plus any explicit supervisor follow-up. Heat-safety actions remain with the crew’s existing procedures. [OSHA heat prevention guidance](https://www.osha.gov/heat-exposure/prevention)

## 4. NFC implementation

### A. Physical test tag now

Use a known writable **NDEF Text** tag and start the read from the app. In NFC Tools, choose **Write → Add a record → Text**. Keep the existing simple fixture and add one full sensor-shaped fixture.

```text
VELTRA1,TAG01,34.2
VELTRA2,TAG02,35.1,12.5,820
```

Write **one line per tag** or overwrite a single tag between tests. Read it back with NFC Tools first.

- `VELTRA1` is a test pod ID plus forehead temperature in °C.
- `VELTRA2` is a test pod ID, forehead temperature in °C, local strip volume in µL, and sample conductivity in µS/cm. These are fixed examples. One tag does not provide a time series or a fresh sensor measurement.
- Decode the NDEF Text record into text using standard text-record handling. Validate the prefix, field count, identifiers, numeric values, and supported fixture units. Reject invalid content and unrelated tags without saving. Derive a rate only if a deliberate simulated scenario supplies a comparable second measurement.
- Record the source as `nfc_test_tag`. Simulated software fixtures use `simulated`. A real board result uses `sensor_pod` only when it passes the confirmed hardware contract.

### B. Real pod integration

The original plan describes a battery-free rear pod powered by the phone’s NFC field. It uses the front strip to sample T4, F3, E5, and dock continuity. The original software plan and the detailed PDF layout target ISO/IEC 15693 and describe **six four-byte blocks**. Elsewhere the PDF describes eight blocks or a 32-byte frame. Use the following as a **draft field map**, pending Lucus’s board and firmware details.

| Draft block | Byte 0 | Byte 1 | Byte 2 | Byte 3 |
| --- | --- | --- | --- | --- |
| `0x00` | `0x48` | `0x53` | Protocol version, proposed `0x03` | Device state flags |
| `0x01` | Sensor status flags | ADC sample count | VCC high | VCC low |
| `0x02` | F3 impedance high | F3 impedance low | E5 electrical reading high | E5 electrical reading low |
| `0x03` | T4 thermistor high | T4 thermistor low | T6 internal temperature high | T6 internal temperature low |
| `0x04` | Dock continuity high | Dock continuity low | Frame timestamp or counter high | Frame timestamp or counter low |
| `0x05` | CRC-16 high | CRC-16 low | Hardware revision ID | Factory calibration ID |

The draft does not specify an embedded pod serial in this table. Confirm whether hardware will provide a serial, use the NFC tag UID, or use another stable ID. If using the UID, confirm that iOS and Android normalize byte order consistently before saving a pairing. A sticker or UI-selected worker name does not establish board identity.

**Get these items from Lucus before enabling live measurements**

1. Exact board, chip, firmware revision, on-air tag technology, and the commands or memory locations actually supported. Confirm block size and whether the app reads NDEF, blocks, or a command response.
2. How a sample starts, where the ready bit or fresh-result marker lives, and what happens after a phone leaves the field. Confirm whether stale data can persist, whether reads are coherent across blocks, and how long the app should keep listening.
3. Final byte length, header and version, offsets and endianness, error and validity flags, missing values, and integrity checks. For CRC, agree on the variant and covered bytes. For multi-block reads, agree on how the phone detects an incomplete or changing sample.
4. Per-channel encoding, units, calibration responsibility, and how to recognize an empty or saturated strip, a disconnected cartridge, or a missing sensor. If the app receives raw counts, supply calibration coefficients or a lookup by hardware and cartridge revision. Choose firmware-calibrated units if that makes the interface simpler.
5. One known-good **hex frame with expected decoded values** and one known-bad or partial example. Include a live two-tap demonstration where the measurement actually changes. Use the fixtures to lock down the Dart decoder before relying on it in a demo.

The native reader owns hardware I/O. Start a foreground session, confirm the tag technology, connect, perform the documented read sequence, and close the session on completion, cancel, or error. If ISO 15693 is confirmed, use iOS Core NFC’s ISO 15693 block or command APIs and Android’s `NfcV` path as applicable. Keep the sequence and parser behind the scan source so role screens stay independent of the protocol. A bounded wait or retry can handle a board that needs time to sample. Publish capture duration from actual bench measurements. [Apple Core NFC](https://developer.apple.com/documentation/corenfc/nfciso15693tag) · [Android NfcV](https://developer.android.com/reference/android/nfc/tech/NfcV) · [TI passive sensor reference](https://www.ti.com/tool/TIDM-RF430FRLSENSE)

The milestone before firmware is finalized is real tag reading, test-tag check-in, and a useful board diagnostic path. Enable live saving after the board contract and known-good fixture are available. Treat invalid headers, unsupported versions, frame integrity failures, stale results, and wrong assigned pods as unsuccessful reads.

## 5. Local data and repo changes

Keep the model small. Existing entities can be extended where that preserves current callers.

| Record | Minimum useful data |
| --- | --- |
| **Crew and worker** | Stable local IDs, crew name, worker display name, active or archived, optional pod assignment. Use a persistent crew ID for new records. |
| **Window** | Stable ID, crew ID, opened time, optional closed time. One open per crew. |
| **Check-in** | Stable check-in ID, crew ID, worker ID, window ID, capture time, source, optional pod ID and cartridge session ID, nullable sensor fields with units or fixed unit-bearing names, overall read quality, per-channel availability, and optional weather context. |
| **Attempt and follow-up** | An attempt records outcome and error separately from successful check-ins when useful to diagnostics or roster review. A follow-up records worker, window, request time, and optional completion or note. |
| **Demo configuration** | Selected crew, role, worker, scan source, and scenario. Keep role switching separate from any future production identity. |

A check-in is one local transaction. Prevent double saves if the reader callback fires twice or the user double-taps. Use a stable record ID for later retry and sync. Missing measurements remain null. Preserve historical records and identify legacy source and units where verifiable. Old simulated readings can remain accessible separately from live history. The local path must never enqueue uploads for demo crew data.

| Existing area | Implementation direction |
| --- | --- |
| `lib/core/demo_mode.dart`, `lib/core/router/app_router.dart`, Quick Demo entry | Add role, crew, worker, and scan-source selection. Keep normal sign-in behavior for existing routes and make Quick Demo usable when offline. |
| `lib/features/scan/`, `lib/services/mock_scan_service.dart` | Build worker-first check-in. Reuse appropriate screen components. Use one read-and-save path across the simulated and physical sources. Keep mock-only settings out of the worker’s main flow. |
| `lib/models/sensor_reading.dart`, `lib/models/scan_record.dart`, `lib/repositories/scan_repository.dart` | Support partial measurements and explicit sources. The current save couples scans to baseline changes and cloud queue entries. Separate local check-in persistence from those side effects while preserving existing signed-in behavior. |
| `lib/services/database_schema.dart`, `lib/services/database_service.dart` | Upgrade SQLite from schema v4 without clearing data. Preserve IDs, legacy scans, and existing pending queue contents. Use explicit migration and test fresh and upgraded installs. |
| `lib/features/crew/`, `lib/providers/worker_providers.dart` | Reuse roster and history. Read status from the current window and source-aware check-ins. Add local follow-up and role-aware navigation. |
| `lib/services/weather_service.dart` | Reuse optional context and cache. Distinguish estimated, cached, unavailable, and simulated weather. |
| `pubspec.yaml`, `ios/Runner`, Android manifest | Add a compatible NFC library and native configuration. `nfc_manager` and its NDEF companion are the first candidates. Use the confirmed board command support and baseline build to choose versions. |

## 6. Build order and acceptance

| Step | Deliverable | Pass condition |
| --- | --- | --- |
| **1. Baseline** | Build the current app and open Quick Demo. | The original simulated scan works on the selected device. Keep any setup fixes in a dedicated change. |
| **2. Local product flow** | Role switch, crew and worker setup, windows, simulated scan, local supervisor roster and history. | Worker A checks in; Worker B stays waiting. Switch views and see A’s record. Close or open a window and verify new status. Force-close and reopen with history intact. |
| **3. NFC reader and test tags** | Physical NDEF read and diagnostics on a phone, then connect to the check-in flow. | Read both documented fixtures. Reject malformed or unrelated tags. Cancel or time out and retry. A repeated callback saves once. The supervisor sees the correct value and source in airplane mode with NFC available. |
| **4. Board integration** | Read the real board using the documented protocol, calibrate or decode its reported readings, and preserve partial-channel status. | A known-good frame decodes to the firmware team’s expected values. A stale, truncated, or invalid frame is rejected. A changed sensor input produces a new reading on a second tap. Measure success count and read duration in open air and through the intended mount. |
| **5. Firebase later** | Shared crew memberships, configured sync, scoped supervisor reads, offline retry, and two-device delivery. | A second device receives the same check-in. Reconnection does not duplicate it. A worker or supervisor from another crew cannot read it. |

**First Cursor implementation target:** Steps 1–3, with a clear place to plug in the board reader in Step 4. Ship all three local screens and a working test-tag check-in. Bench acceptance for Step 4 depends on Lucus’s firmware contract. The one-phone competition demo can run any of the three sources as soon as each is verified.

**Development setup:** Use the existing native Apple Silicon SDK at `~/fvm/default/bin/flutter`. On the Mac checked previously, Flutter 3.47.9, Dart 3.13.7, Xcode 27.2, and CocoaPods 1.17.0 were installed. A clean device build still needs verification. Run `flutter doctor -v`, `flutter pub get`, `flutter devices`, and a baseline build using that SDK before dependency upgrades. For iPhone NFC use a physical device, Developer Mode, a signing team that supports NFC Tag Reading, and `NFCReaderUsageDescription`. Align the old iOS deployment setting with selected dependency requirements. For Android, install the SDK if needed, confirm the phone has NFC, add the NFC permission, and migrate the old Gradle setup only as required for the build. Use a simulator for UI and fixture tests and a physical phone for NFC acceptance. [Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup) · [Flutter Android setup](https://docs.flutter.dev/platform-integration/android/setup) · [Apple reader setup](https://developer.apple.com/documentation/corenfc/building-an-nfc-tag-reader-app) · [Flutter NFC package](https://pub.dev/packages/nfc_manager) · [NDEF companion](https://pub.dev/packages/nfc_manager_ndef)

**Acceptance before filming:** Run the app with a fresh install and with an upgraded v4 database. Check two workers and two fixture tags, a partial read, a dry strip, wrong pod assignment, canceled or interrupted reads, repeat scans, and a restart. Verify that reset affects only the demo crew. Film one worker tapping and the same saved record appearing on the Supervisor screen. Keep the source visible so the footage documents exactly what generated the value.

## References within the project

- `veltra_full_plan.pdf`, pages 25–31, for T4/F3/E5 sensing, the draft memory map, and the original weather and scoring concepts.
- `software_plan.pdf`, pages 4 and 6–9, for the six-block draft and planned data flow.
- `VELTRA.md`, `plans/MASTER_PLAN.md`, and current Flutter source at `b2840f5` for implementation history.
- The November 16 project update and subsequent team discussion for worker self-scan, supervisor review, the current hardware redesign, and the local-first scope.
