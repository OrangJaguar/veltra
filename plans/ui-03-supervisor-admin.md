# UI plan 3 — Supervisor and Admin

> **Status:** Done.
> **Goal:** Supervisor is a glanceable board. Admin is the bench, in the same glass frame, without the long dump of buttons.

Depends on UI plan 2. Say **"code UI plan 3"** to start.

## Adjusted before coding

UI plan 1 left Workers, Settings, Crew, and Tools as titles, and the whole bench is still one list. UI plan 2 added the check-in trend chart. These seams follow that:

- The dashboard replaces the current crew list on the supervisor’s first tab. The full roster moves to Workers. A row still opens the worker detail.
- That detail keeps the latest measurements and Request a recheck, and it uses the same trend chart as worker history. The repeated history cards come off this page.
- Open and close move to Supervisor Settings. The bench no longer has the window. Crew name and site are readouts there. Admin Crew can still rename the crew, because that is the only place the name is edited.
- Admin Bench keeps source, the five scenarios, the presented pod, and the NFC log. Crew keeps the people, pods, archive, add, and crew switching. Tools keeps the unpaired read and Reset demo crew.

## Supervisor

**Dashboard.** The window state, then four counts: Waiting, Checked in, Retry requested, Missed. Under that, only the people who are not simply checked in, each as a row you can open. No paragraphs.

**Workers.** The full active roster, closest to the old crew list: name, status, time, source. Tap opens that worker: latest measurements, the same trend chart as the worker history, and **Request a recheck** when one is not already open.

**Settings.** Open or close the window. Crew name and site as readouts. Reset stays on Admin, so a supervisor cannot wipe the demo by accident.

## Admin

Admin is not a fourth kind of employee. It is the bench for this one phone.

**Bench.** Scan source, the five scenarios, the presented pod, and the short NFC read list. A physical source explains that Check in on the worker page reads the tag.

**Crew.** The workers on the current crew: rename, pod, archive, add. Switch crew or make an empty one.

**Tools.** Unpaired bench read, and **Reset demo crew** with the confirm. Reset still restores only Avery, Blake, and Casey and leaves any other crew.

## Acceptance

- Dashboard counts match a mixed crew: one checked in, one missed after close, one retry.
- A recheck requested here shows on that worker’s own phone.
- Admin can still run a dry strip, a pod mismatch, and a reset, and the worker scan page picks those up.
- The HTML phone has the same three tabs for each role.
