# Plan 3 — Demo Admin

> **Status:** Done.
> **Goal:** The bench controls live in a clearly labeled Demo Admin view. Simulated edge cases save or fail honestly, and the supervisor roster tells the truth after a window closes or a recheck is requested.

Depends on plan 2. Say **"code plan 3"** to start. Do not start plan 4 in the same pass.

## Adjusted before coding

Plan 2 already has the worker home, the supervisor roster, and a Demo Admin placeholder on `/checkin`. These seams follow that:

- Fill that Demo Admin screen. Leave the old foreman Crew tab alone. Missed, Checked in, Waiting, and Retry requested appear on the check-in roster.
- The roster uses the latest window, including a closed one, so Missed can show. An open recheck shows **Retry requested** and does not erase a saved check-in. A closed window with no save is **Missed**.
- The next check-in’s presented pod is stored on `demo_config` (schema v6). The worker’s assignment stays on `pod_id`. A blank presented pod uses the assignment. A different presented pod is a mismatch.
- The five scenarios are the bench inputs. The old manual number sheet stays on the signed-in scan screen.
- Sweat rate is derived from the previous saved volume for the same worker, pod, and window. The first read has none. A drop, a gap longer than 4 hours, or a volume at or above 25 µL stores no rate.
- Physical test tag and Sensor pod can be selected. A check-in then explains that they connect in the next update and does not save.
- Reset always restores the seeded Demo Crew. Any other local crew is left in place.

## In scope

### Demo Admin

- Crew: create, rename, site label. Empty local crew for bench labels, separate from the seeded three.
- Workers: add, edit, archive. Archived workers leave the active roster and keep history.
- Window: open or close the one window for the selected crew. Opening while one is already open is refused. Closing sets the closed time.
- Pod: assign or clear a pod id on a worker. An explicit unpaired bench action records an attempt and does not change roster status.
- Scan source control shows Simulated, Physical test tag, and Sensor pod. Only Simulated runs a save in this plan. Choosing either physical source shows that it connects in plan 4, and does not silently fall back to a fake success.
- Scenarios, simulated only:
  - complete reading
  - temperature only
  - dry strip
  - poor cartridge contact
  - timeout
- Manual number entry, if it stays, is on this screen only.
- Reset asks for confirmation and deletes fixtures and demo records for the selected demo crew only. Other local crews and the old foreman scans stay.

### Rules the worker and supervisor screens pick up

- Measurements may be missing. The success panel names the missing channels. Temperature only is still a saved check-in.
- Dry strip and poor contact are failed attempts with those plain sentences: **Reseat the cartridge** for poor contact, and a dry-strip sentence that does not say the check-in saved. A failed attempt never flips the row to Checked in and never erases an earlier valid check-in in the same window.
- Sweat rate is stored only when two valid volumes exist for the same worker, pod, and cartridge session, the volume did not drop, the strip is not saturated, and the elapsed time is valid. The first read has no rate.
- Presented pod id must match the assignment when the worker has one. A mismatch saves nothing and says **Wrong pod for this worker**. No assignment means the pod id is stored and is not a mismatch.
- Supervisor can **Request a recheck**. Switching to Worker shows that flag. It is local only.
- After the window is closed, a worker with no valid check-in in that window is **Missed**.
- Yesterday’s check-in does not count toward today’s window. Status uses the window id.
- Source stays visible on the row and the detail.

### HTML phone

Extend `phone-preview/` with Demo Admin, the five scenarios, window open and close, archive, pod mismatch, recheck, Missed, and reset. Same `localStorage` crew.

## Out of scope

- Starting an NFC session, parsing tag text, or writing the payload file (plan 4)
- Treating Sensor pod as a measurement source
- Cloud delivery of the follow-up flag
- Putting GREEN / AMBER / RED back on the worker result

## Files

| Area | Change |
|------|--------|
| New Demo Admin screen under `lib/features/` | The controls above |
| Check-in save path from plan 1 | Scenario mapping, mismatch, rate rule, attempt vs check-in |
| `lib/features/crew/` | Missed, Retry requested, follow-up |
| `phone-preview/` | The same controls |

## Acceptance

- Complete reading checks the worker in. Temperature only checks them in and shows the other channels as unavailable. Dry strip, poor contact, and timeout do not.
- A valid check-in, then a later failed attempt, still shows Checked in.
- Close the window: workers who never saved are Missed. Open a new window: the previous save does not count, and they are Waiting.
- Assign pod `TAG01`, simulate a read from `TAG02`: no save, mismatch message. Clear the assignment and the same read saves.
- Reset removes the demo crew’s check-ins and restores the seeded window and workers. A second local crew created in the empty-crew path is still there.
- Request a recheck, switch to Worker, and see it.
- The HTML phone completes the same checks.

## Notes for the next plan

Plan 4 replaces the “connects in the next update” state on Physical test tag with a real session. It should pass the decoded line through `CheckInRepository.applyScenario`, including the mismatch and partial-channel rules. The presented pod is `demo_config.presented_pod_id`. Sensor pod stays diagnostic.
