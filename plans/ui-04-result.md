# Look plan 1 — Result

> **Status:** Done.
> **Goal:** The screen after a check-in matches screenshot 13 in `Veltra-Main-Screens.png` and screenshots 12–15 in `Veltra-All-Screens.png`.

Read `.cursor/skills/veltra-design/SKILL.md` first. Reuse `WorkerAvatar`, `MetricStatBox`, `VeltraPrimaryButton`, and `flutter_animate`. Do not restyle the dashboard or settings in this pass.

## Adjusted before coding

The saved view only receives the check-in. The name and the trend have to be loaded beside it.

- Look up the worker on the check-in, not whoever the phone is set to now.
- Time and source stay as a caption under the action line. The picture leads with the status and the name, and dropping the caption would hide whether this was a simulated save.
- A WBGT tile appears only when this check-in stored a WBGT. Height, weight, and the profile stay on look plan 2.
- One forehead point still says “Not enough data” on the trend. The chart and the metric menu are on the page anyway.

## Screen

- Circular initial, then GREEN, AMBER, or RED at 32px bold in the status color
- Worker name, then the existing action line
- Two-column tiles with icons: forehead, strip volume, conductivity, sweat rate. WBGT only when weather exists. A missing value stays in its tile as Unavailable
- The same trend chart as History, with the metric menu
- One full-width orange Done button
- The card slides up 24px and fades in over 300ms

The HTML preview gets the same layout. Say **"code look plan 1"** to start.

## Acceptance

- A 36.8 °C simulated save shows a green word, Avery’s initial, four icon tiles, the trend, and an orange Done button
- Volume left blank still has a tile that says Unavailable
- The phone preview matches that layout
