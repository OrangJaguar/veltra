# Look plan 3 — Controls and motion

> **Status:** Done.
> **Goal:** Actions look like buttons, and the app moves like the timings in `DESIGN.md`.

Depends on look plan 2. Read `.cursor/skills/veltra-design/SKILL.md`.

## Adjusted before coding

The result card already slides up and fades over 300ms. A saved check-in already triggers a haptic. This pass does not rebuild that card.

- Switch worker, Open window, Close window, Save crew, Add worker, Unpaired bench read, and Reset are full-width buttons. Rename, Archive, and Pod sit side by side so three people still fit.
- Choosing another crew stays a row. It is navigation, not a form action.
- Back on the preview becomes an outlined button. The app already uses a back arrow.
- The tab dock moves to 250ms. Pushed check-in screens slide and fade over 350ms. Roster rows fade in once, 50ms apart.
- The HTML preview copies the button shapes and the chip spacing. It does not play the native transitions.

## Controls

Switch worker, Rename, Archive, Save crew, Add worker, Open window, and Close window become filled or outlined buttons. Minimum 52px, 16px radius. Orange text alone is not a button.

Scan source stays in its own card, with 16px padding and 8px between chips. The chips do not sit against the card edge or the next card.

## Motion

- Result reveal: 300ms slide up and fade
- Pushed screens: 350ms easeOutCubic
- Tab change: 250ms
- Roster rows fade in with a 50ms stagger
- Haptic when a check-in saves

The HTML preview matches the button shapes. It does not imitate the native transitions. Say **"code look plan 3"** to start.

## Acceptance

- Worker Settings shows Switch worker as a button, and the scan-source chips have space around them
- Opening a saved check-in animates in
- Admin Crew rename and archive are buttons
