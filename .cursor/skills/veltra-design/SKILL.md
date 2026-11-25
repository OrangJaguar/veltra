---
name: veltra-design
description: >-
  Match Veltra screens to Veltra-Main-Screens.png, Veltra-All-Screens.png, and
  DESIGN.md. Use when building or editing Flutter UI, check-in screens, the
  phone preview, result cards, dashboards, roster rows, settings, worker
  profiles, buttons, or motion.
---

# Veltra design

The look is the foreman app in `Veltra-Main-Screens.png` and `Veltra-All-Screens.png`. Tokens are in `DESIGN.md`. Plus Jakarta Sans. Cream `#FFF8F0`, orange `#FF6B2C`, ink `#2C2416`.

The check-in pages went wrong by drawing new text lists instead of the widgets that already match those pictures. Reuse the widgets. Do not invent a flatter style.

## Before a screen

Open the closest frame in the PNG. Copy its structure: avatar, status word, name, icon tiles, one orange button. Screen padding is 20px. Cards are 16–20px inside, 20px radius, white at 72% with a warm shadow. Gap between cards is 12px. Touch targets are at least 52px.

## Reuse these

- `GlassCard`
- `WorkerAvatar` — circle with the initial, status color behind it
- `MetricStatBox` — icon, label, value, optional arrow
- `VeltraPrimaryButton` — orange fill, 16px radius, 56px tall, white label
- Outlined actions — white fill, 1.5px orange border, orange label, same height and radius
- `flutter_animate` for the timings in `DESIGN.md`

Orange text sitting in a card is not a button. Rename, Archive, Switch worker, Save crew, Add worker, Open window, and Close window are real buttons.

## Result

This is screenshot 13 in the main sheet and 12–15 in the all-screens sheet.

- Circular initial, then the status word at 32px bold in green, amber, or red
- Worker name under it, then one action line
- A 2-column grid of `MetricStatBox`, each with a rounded icon
- Channels we have: forehead, strip volume, conductivity, sweat rate. WBGT only when weather exists. Missing value says Unavailable inside the tile. Do not drop the tile.
- The trend chart on the same screen, with the metric menu
- One full-width orange button at the bottom
- Reveal: slide up 24px and fade, 300ms, easeOutCubic

## People

Crew and dashboard rows are glass cards, about 64px, with an avatar, the name, and the status word. Counts can sit above the list. They do not replace avatars. Leave air between the count tiles. Do not use a dense table.

Worker detail is screenshot 22. Avatar, name, last result, time. Then a Profile card: employee id, age, height, weight, BMI, pod. Those fields already live on `Worker`. Edit them with the same form as `add_worker_screen.dart`. Then the trend chart.

## Controls and motion

Scan source is its own card. Chips have 16px of card padding and 8px between them. They do not touch the card edge or the next card.

| Interaction | Duration | Curve |
|---|---|---|
| Tab | 250ms | easeInOutCubic |
| Screen push | 350ms | easeOutCubic |
| Result reveal | 300ms | slide up + fade |
| List rows | 50ms stagger | fade in |

Haptic when a check-in saves. The HTML preview copies layout and type. It does not fake native transitions.

## Do not

- A plain label/value table as the result
- Text links as the only way to act
- Four cramped count tiles and nameless rows as the dashboard
- New hues. Status colors and safety orange only
- Paragraphs on the scan flow
