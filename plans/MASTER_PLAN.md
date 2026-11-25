# Veltra — Check-in program

> Current build. One plan at a time. Say **"code plan N"** to implement that plan.
> The finished foreman app (phases 0–5) is archived in [mvp-MASTER_PLAN.md](./mvp-MASTER_PLAN.md). Leave those phase files as history.

## Why four plans

The work splits on seams where the app is usable and the next chunk does not have to reopen the last one.

| Plan | File | Leaves you with | Status |
|------|------|-----------------|--------|
| **1** | [plan-01-foundation.md](./plan-01-foundation.md) | Local crew, window, and check-in records. Quick Demo still opens. Old screens still run. | ✅ |
| **2** | [plan-02-worker-supervisor.md](./plan-02-worker-supervisor.md) | Worker check-in and supervisor roster on one phone, simulated only, plus the HTML phone. | ✅ |
| **3** | [plan-03-demo-admin.md](./plan-03-demo-admin.md) | Crew setup, scenarios, pod mismatch, follow-up, and a demo reset. HTML matches. | ✅ |
| **4** | [plan-04-nfc-test-tags.md](./plan-04-nfc-test-tags.md) | Real NDEF test tags on the iPhone, a copy-paste payload file, diagnostics. HTML can paste a line. | ✅ |

Lucas’s sensor pod and Firebase stay out of all four. Plan 4 leaves a named place for the pod reader. Plan 1 leaves a named place for sync later.

At the start of each plan, re-read that file and edit it if the previous plan moved a seam. At the end, mark it done here and fix anything the next plan got wrong.

## Decisions already locked

| Topic | Decision |
|-------|----------|
| Worker result | **Check-in saved**, with time, source, and whatever channels came back. GREEN / AMBER / RED is not that screen. |
| Who is using the phone | A selected local worker, switched from a Supervisor or Demo Admin view. Same database. |
| Accounts and a second phone | Later. Firebase stays in the repo and is not required for Quick Demo. |
| NFC now | Writable NDEF text tags, read by the app. Payloads live in one copy-paste file. |
| NFC later | Lucas’s board. Until his frame is confirmed, a pod tap may show diagnostics and must not be saved as a measurement. |
| Preview | `phone-preview/` is the same UI in a phone frame. Plans 2, 3, and 4 update it in the same pass as the Flutter screens. |
| Design | Keep the existing warm glass system in `DESIGN.md`. |
| Data | Upgrade SQLite past schema v4. Do not wipe existing rows. |

## What we are not building in this program

- ISO 15693 block reads, calibration, or live pod measurements
- Firebase crew membership, cloud sync, or per-worker accounts
- Voice as the way to decide who was scanned
- A risk color as the outcome of a check-in

## How a check-in works when all four are done

1. Quick Demo opens a local crew of three fictional workers and one open window. No network.
2. Switch to Worker, confirm the name, tap **Check in**.
3. The active source is Simulated, a Physical test tag, or Sensor pod diagnostics.
4. A good read saves once, then shows **Check-in saved**. A bad read explains the problem and leaves the roster unchanged.
5. Switch to Supervisor. That worker is **Checked in**. The other two are **Waiting**.
6. Demo Admin holds scenarios, pod pairing, the window, diagnostics, and reset.

## NFC Tools

Yes. Use the **NFC Tools** app on the iPhone. Write → Add a record → Text → paste one line from the payload file in plan 4 → write it to a normal writable tag (NTAG213 / 215 / 216 or similar). Then read that tag from Veltra, not from NFC Tools.

Those text tags are the bench tags. They are a different kind of chip from Lucas’s board. Do not write these lines onto the sensor pod.

iOS only reads a tag while Veltra has started a session, so the test always begins with **Check in**. The simulator on this Mac cannot read NFC. Acceptance for plan 4 is the iPhone 17 Pro.
