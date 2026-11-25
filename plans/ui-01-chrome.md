# UI plan 1 — Chrome

> **Status:** Done.
> **Goal:** The phone has a skinny glass role switch at the top and a larger glass tab bar at the bottom. Exit demo is gone. The app opens on the worker scan page.

Say **"code UI plan 1"** to start. Do not start UI plan 2 in the same pass.

## Adjusted before coding

The check-in pages already work. Blanking them would hide Check in, the roster, and the bench until later plans. These seams follow that:

- The app starts in demo mode and opens `/checkin`. The shell seeds the demo crew on first open, the same seed Quick Demo used. Login, sign-up, and onboarding stay in the repo. While demo mode is on, those routes still redirect to `/checkin`.
- Worker Scan keeps the current worker home. Supervisor Dashboard keeps the current roster. Admin Bench keeps the current bench. History, Settings, Workers, Crew, and Tools are plain titled slots.
- A check-in session, a saved card, a pushed history page, and a worker detail stay full screen, without the two bars. Back returns to the shell.
- The HTML phone stores the role and each role’s tab. A refresh keeps both. An old “demo paused” state opens on Worker → Scan.

## What changes

- Remove **Exit demo** from the Flutter shell and the HTML phone. There is no signed-out pause screen. Launch goes to the worker scan page. Login, sign-up, and onboarding stay in the repo and are not on this path.
- Remove the **Veltra** label in the top-right status corner.
- Top bar: one liquid-glass pill, as short as it can be and still hit with a thumb. Worker, Supervisor, Admin. The selected segment slides. It does not look like the bottom bar.
- Bottom bar: a separate liquid-glass bar, normal height, clearly heavier than the top pill. It changes with the role.
  - Worker: **Scan**, **History**, **Settings**
  - Supervisor: **Dashboard**, **Workers**, **Settings**
  - Admin: **Bench**, **Crew**, **Tools**
- The page bodies can stay plain in this plan. The bars and the empty slots have to be real, in Flutter and in the HTML phone, so the navigation can be clicked before the pages are dressed.

## Out of scope

- The scan circle, manual entry, result card, and trend chart (UI plan 2)
- Supervisor counts and the admin bench layout (UI plan 3)
- Changing what a check-in saves

## Acceptance

- Nothing on screen says Exit demo.
- Opening the app or the HTML file lands on Worker → Scan.
- The top pill is short. The bottom bar is taller and reads as a different control.
- Switching role keeps the bottom bar in sync. Switching tab does not change role.
- Refreshing the HTML keeps the role and the tab.
