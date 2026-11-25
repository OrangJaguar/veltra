# Look plan 2 — People

> **Status:** Done.
> **Goal:** The supervisor board and a worker’s page look like screenshots 17 and 22 in `Veltra-Main-Screens.png`.

Depends on look plan 1. Read `.cursor/skills/veltra-design/SKILL.md`. Height, weight, age, and BMI are already on `Worker` and on the old edit form. This pass shows them again. It does not change roster status rules.

## Adjusted before coding

The old edit screen is the signed-in form. Opening it from the demo would also write a sync row, and demo mode is not that form.

- Edit stays on the worker page. The fields are name, employee id, age, height in cm, and weight in kg. BMI is calculated. Pod stays a readout, edited on Admin Crew.
- The save writes those columns on the worker and does not touch the sync queue.
- Avery, Blake, and Casey get a starter profile when they are created, when a launch finds those three fields empty, and when demo crew is reset. An edit is kept.
- The measurement list comes off this page. The result card already shows the tiles. This page is the person, the profile, and the trend.
- Motion stays on look plan 3.

## Dashboard and roster

- Count tiles keep their four statuses, with 12px between them and 20px of screen padding
- Each person is a glass row: initial avatar, name, status word, time
- Simply checked-in people stay off the dashboard list. They stay on Workers

## Worker page

- Avatar, name, status, time
- Profile card: employee id, age, height, weight, BMI, pod
- Edit opens the same fields as `add_worker_screen.dart` and saves them on that worker
- Trend chart stays
- Request a recheck is an outlined button, not orange text

The HTML preview gets the same layout. Age, height, and weight can be edited there too. Say **"code look plan 2"** to start.

## Acceptance

- Avery’s page shows height and weight, and an edit changes what the profile shows
- Dashboard rows have initials and a status word, and the four counts still match a mixed crew
