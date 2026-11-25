# UI plan 2 — Worker

> **Status:** Done.
> **Goal:** The worker phone looks like the scan screen in `Veltra-Main-Screens.png`, and it still saves a check-in.

Depends on UI plan 1. Say **"code UI plan 2"** to start. Do not start UI plan 3 in the same pass.

## Adjusted before coding

UI plan 1 left Scan as the old worker home, and History and Settings as titles. These seams follow that:

- Scan replaces that home. The History button and Switch worker leave this page. History is the bottom tab. Switch worker moves to Settings.
- Manual entry calls the same check-in save as a simulated read, with the typed numbers. It does not run the bench scenario and it does not write the old scan table. A presented-pod mismatch still fails with “Wrong pod for this worker.” and writes no check-in.
- Forehead temperature is required, from 30.0 to 42.0 °C. Volume and conductivity can be left blank.
- The color is computed when the card or the history row is shown. It is not stored. The old crew trend chart stays on the signed-in screens. Worker history gets the same kind of chart for the four check-in metrics.
- Done returns to the shell on Scan.

## Scan

- Weather chip at the top left. The selected worker’s name sits with it, because this phone is already that person.
- The large orange circle is the check-in. Label it **Check in**. Tap starts the same session as today: simulated scenario, test tag, or sensor-pod diagnostic.
- **Manual entry** sits under the circle, as a text button, and opens a sheet. The fields are forehead temperature °C, strip volume µL, and conductivity µS/cm. A saved sheet uses the same check-in transaction as a simulated read. It does not write the old scan table. The result card scores it the same way as a circle tap.
- Voice name matching stays off this page. The worker was already chosen.

## After a check-in

- A card in the same family as the old result screen: the big verdict, the action line, time, source, and the measurements that came back. Missing channels say Unavailable.
- The headline is **GREEN**, **AMBER**, or **RED**, with the old action line: Continue work / Drink 500mL water · re-scan in 30 min / Rest 15 min in shade.
- The color comes from the existing risk engine. Forehead temperature is the skin-temp input. A sweat rate, when one exists, converts from µL/min to L/hr. WBGT counts only when weather actually returned it. Conductivity, z-score, temp rate, and acclimatization do not invent points. Under 4 is GREEN, 4–7 is AMBER, 8 or more is RED. The demo read of 36.8°C with no rate is GREEN.
- A failed read still saves nothing and shows no color. Roster status stays Waiting, Checked in, Retry requested, or Missed. The color is the result card, and a history row can show it.
- Done returns to Scan.

## History

- The trend chart from the old worker detail, pointed at this worker’s check-ins.
- A metric control switches forehead temperature, strip volume, conductivity, and sweat rate.
- A short list of past check-ins sits under the chart. Each row shows time and source.

## Settings

- Switch worker, with the existing confirm.
- Scan source: Simulated, Physical test tag, Sensor pod.
- The open or closed window, as a status. Opening and closing it stays with the supervisor.

## Acceptance

- Scan matches the screenshot’s structure: weather, circle, manual entry, bottom tabs.
- A circle tap and a manual save both show up as one roster row for that worker.
- A dry-strip scenario still does not save.
- History can switch metrics, and an empty metric says there is not enough data.
- The HTML phone does the same clicks, including a pasted test-tag line from UI plan 4’s preview.
