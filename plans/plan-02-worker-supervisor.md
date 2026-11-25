# Plan 2 — Worker and supervisor

> **Status:** Done.
> **Goal:** On one phone, pretend to be a worker and check in with a simulated reading, then switch to supervisor and see that row change. The same screens exist in `phone-preview/` so they can be clicked in a browser.

Depends on plan 1. Say **"code plan 2"** to start. Do not start plan 3 in the same pass.

## Adjusted before coding

Plan 1 already stores the crew, the open window, and `demo_config`. These seams follow that:

- Quick Demo opens `/checkin`. Signed-in foreman mode still opens `/scan` and the old voice flow.
- The supervisor roster is only Avery, Blake, and Casey. Jake, Maria, Dev, Chris, and Sam stay in the old crew list.
- A successful simulated check-in uses one fixed reading: 36.8°C, 8.0 µL, 640 µS/cm. Sweat rate stays unavailable. There is no risk color.
- Timeout calls a failed-attempt write. It does not call `saveCheckIn`. Cancel writes nothing.
- Weather on this screen is a real fetch or a cache. The hardcoded 30°C fallback is not shown and not saved. The Check in button does not wait for it.
- Role, selected worker, and scan source stay in the `demo_config` row from plan 1. Switching role does not change the selected worker.
- Exit demo sits on the shell so Quick Demo is not a dead end.

## In scope

### Shared

- A persistent role: Worker, Supervisor, Demo Admin. Switching is one obvious control, available from every main screen, and it does not change who is selected or what is saved.
- A persistent selected worker. Changing workers asks them to confirm the name.
- Demo Admin can be selected. Its screen in this plan is a short placeholder that says the bench controls arrive in plan 3. Scan source stays **Simulated**.
- Remove voice match from the check-in path. The selected worker is whose record is saved.
- One simulated happy-path reading and one simulated failure (timeout). The full scenario list is plan 3.
- Success copy is **Check-in saved**. Show local time, source **Simulated**, and the measurements in an expandable panel. No GREEN / AMBER / RED on this path.
- A failed attempt does not create a check-in.
- A second successful check-in in the same window creates a second record.
- Weather may show as estimated, cached, or unavailable. It must not block the button. The hardcoded weather fallback is only allowed inside the simulated reading.

### Worker

- Home fits one phone screen: name, crew, open window, **Check in**, and the latest check-in with time and source.
- No open window: plain text that says a window has to be started, and point at Demo Admin. Opening the window is plan 3, so for plan 2 the seeded window is already open.
- Scan: **Hold phone near the pod**, then **Reading**. Cancel returns to Ready and saves nothing.
- History lists this worker’s check-ins with labels, times, and source. Null channels show as unavailable.

### Supervisor

- Crew overview for the open window: checked-in count and each active worker as **Waiting** or **Checked in**. Show latest time and source.
- Worker detail reuses the profile and history. Show the latest measurements with units.
- **Request a recheck** can wait for plan 3. Leave a visible disabled or absent action rather than a fake one.

### HTML phone

Create `phone-preview/` at the repo root. One self-contained page (HTML, CSS, and a single script, no build step) that:

- Shows a phone frame on a desktop page, and fills the window when the browser is already narrow.
- Uses the colors and type scale in `DESIGN.md` (Plus Jakarta Sans, sunrise cream, safety orange, glass cards, 52px targets).
- Implements the same Worker and Supervisor flows, including role switch, confirm-worker, check-in, cancel, timeout, saved state, and history.
- Stores the demo crew in `localStorage` so a refresh keeps it.
- Has no NFC, no Firebase, and no claim that a tap read a tag.

## Out of scope

- The scenario catalog, archive, pod pairing, mismatch, follow-up, window open/close, and demo reset (plan 3)
- NFC sessions and the payload file (plan 4)
- Rewiring the old risk engine into this flow

## Files

| Area | Change |
|------|--------|
| `lib/features/scan/`, `lib/features/shell/`, `lib/core/router/app_router.dart` | Worker home and check-in replace the voice scan as the demo home |
| `lib/features/crew/` | Window-scoped roster |
| `lib/core/demo_mode.dart` and the demo-config store from plan 1 | Role and selected worker |
| `phone-preview/` | New |

The old Scan screen can remain on a route that normal signed-in foreman mode still reaches. Quick Demo lands on the new worker home.

## Acceptance

- Worker A checks in. Worker B stays Waiting. Switch to Supervisor and see both.
- Force-quit, reopen, history and roster match.
- Cancel, then a timeout: roster unchanged.
- Check in again: a second saved record, still one roster “checked in”.
- The success screen has no risk color.
- `phone-preview/index.html` opens from the file and completes the same A-then-B walkthrough without a server.

## Notes for the next plan

Plan 3 fills Demo Admin and the extra roster words (**Retry requested**, **Missed**). Plan 2’s roster only needs Waiting and Checked in, driven by a saved check-in in the open window. Failed attempts already use `CheckInRepository.recordFailedAttempt` and do not create a check-in. The placeholder screen is `DemoAdminScreen` on `/checkin`.
