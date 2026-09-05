# Veltra — Design System

> Warm, practical, construction-site friendly. **Not** corporate dark AI slop.

## Design Intent

Veltra is used by foremen outdoors, often in bright sun, sometimes with gloves. The UI should feel:

- **Welcoming** — like a helpful tool, not enterprise software
- **Scannable** — big status colors, few words, obvious next action
- **Calm under stress** — when RED appears, layout stays clear (no panic clutter)
- **Construction-native** — safety orange, sun yellow, hard-hat white, sky blue accents

Think: **safety vest + morning job site + frosted glass**, not black dashboard.

---

## Color Palette

### Brand & surfaces

| Token | Hex | Use |
|-------|-----|-----|
| `sunriseCream` | `#FFF8F0` | Main app background |
| `warmSand` | `#FFF1E0` | Secondary background, cards base |
| `glassWhite` | `#FFFFFF` @ 72% opacity | Glass panels |
| `glassBorder` | `#FFFFFF` @ 90% opacity | Glass edge highlight |
| `shadowWarm` | `#E8A84A` @ 18% opacity | Soft warm shadows |

### Construction accents

| Token | Hex | Use |
|-------|-----|-----|
| `safetyOrange` | `#FF6B2C` | Primary buttons, active nav, brand |
| `hardHatYellow` | `#FFC93C` | Secondary accents, badges |
| `skyWorkBlue` | `#4DA3FF` | Info, links, WBGT chip |
| `coneAmber` | `#FFAB00` | Warnings (non-status) |

### Status (keep distinct from brand orange)

| Token | Hex | Use |
|-------|-----|-----|
| `statusGreen` | `#2ECC71` | GREEN — safe |
| `statusGreenBg` | `#E8F8EF` | GREEN card background |
| `statusAmber` | `#F39C12` | AMBER — caution |
| `statusAmberBg` | `#FEF5E7` | AMBER card background |
| `statusRed` | `#E74C3C` | RED — stop / rest |
| `statusRedBg` | `#FDEDEC` | RED card background |

### Text

| Token | Hex | Use |
|-------|-----|-----|
| `textPrimary` | `#2C2416` | Headlines, worker names |
| `textSecondary` | `#6B5E4E` | Labels, subtitles |
| `textMuted` | `#9A8B78` | Hints, timestamps |
| `textOnOrange` | `#FFFFFF` | Text on orange buttons |
| `textOnStatus` | `#FFFFFF` | Text on solid status banners |

---

## Typography

**Font:** [Plus Jakarta Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans) via `google_fonts`

| Style | Size | Weight | Use |
|-------|------|--------|-----|
| Display | 32px | 700 | Scan result status ("GREEN") |
| Title | 22px | 700 | Screen titles |
| Headline | 18px | 600 | Worker names, section headers |
| Body | 16px | 500 | Actions, short instructions |
| Label | 13px | 600 | Chips, nav labels |
| Caption | 12px | 500 | Timestamps, sync status |

**Copy rules:**
- Max ~6 words per instruction line
- Buttons = verbs: "Scan", "Log & Next", "Add Worker"
- No paragraphs on scan flow screens
- Status actions are one sentence max

---

## Glass Morphism

### Glass card
```
Background: white @ 72%
Backdrop blur: 20px (where supported)
Border: 1px white @ 90%
Border radius: 20px
Shadow: 0 8px 32px sunriseCream shadow / warm tint
```

### Floating pill nav bar
```
Position: fixed, 16px from bottom + safe area inset, 24px horizontal inset
Height: 56px (inner content — keep icon + label compact to avoid overflow)
Border radius: 999px (full pill)
Background: white @ 78%
Blur: 24px
Border: 1.5px white
Shadow: 0 12px 40px #FF6B2C @ 12%

Active tab: safetyOrange filled circle behind icon
Inactive: textMuted icons
```

### Glass header (optional on scroll screens)
- Same glass treatment, 56px height, no harsh divider lines

---

## Layout & Spacing

- Base unit: **8px**
- Screen padding: **20px** horizontal
- Card padding: **16–20px**
- Minimum touch target: **52px** (glove-friendly)
- Primary scan button: **72px** height, full width minus padding
- Bottom nav clearance: **96px** above pill (content must not hide behind nav)

---

## Components

### Primary button (Scan, Log & Next)
- Fill: `safetyOrange`
- Radius: 16px
- Height: 56–72px
- Label: white, Body weight 600
- Press: scale 0.97 + slight shadow reduction (150ms)

### Secondary button
- Fill: `glassWhite` with orange border 1.5px
- Text: `safetyOrange`

### Status result banner (full width card)
- Background: status color @ 15% tint OR solid for RED
- Large icon + status word (Display)
- Action line below (Body, textSecondary)
- Entire card animates in: slide up 24px + fade (300ms, easeOutCubic)

### Worker row (Crew tab)
- Glass card, 64px min height
- Left: colored dot (last scan status)
- Center: name (Headline)
- Right: chevron, optional time ago (Caption)

### WBGT chip (Scan screen)
- Pill shape, `skyWorkBlue` @ 12% bg
- Icon: sun/thermometer
- Text: "WBGT 28°" — one line

### Sync indicator (Settings + subtle header)
- Green dot = synced
- Amber pulse = pending
- Gray = offline

### Voice listening overlay
- Frosted full-screen dim @ 30%
- Center glass card with mic icon pulsing orange
- Text: "Say worker name" (3 words)
- Auto-dismiss on match or 5s timeout → manual picker fallback

---

## Motion & Animation

| Interaction | Duration | Curve |
|-------------|----------|-------|
| Tab switch | 250ms | easeInOutCubic |
| Screen push | 350ms | easeOutCubic |
| Scan button pulse (idle) | 2s loop | subtle scale 1.0→1.02 |
| Mock scan loading | 800ms | shimmer + haptic at end |
| Result reveal | 300ms | slideUp + fade |
| List items | stagger 50ms | fadeIn |
| Nav pill icon active | 200ms | scale + color |

Use `flutter_animate` or built-in `AnimationController` — keep 60fps, no jank.

Haptics:
- Light impact on mock scan complete
- Medium impact on RED result
- Selection click on nav tab

---

## Screen-Specific Notes

### Scan (home)
- Warm gradient background: `sunriseCream` → `warmSand` (top to bottom, subtle)
- Giant orange scan button center
- Shift timer chip top-left ("Shift · 2h 14m")
- WBGT chip top-right
- After scan → voice overlay → results

### Results
- Status color dominates top 40% of screen
- Worker name in Headline below status
- Collapsible "Details" chevron — metrics hidden by default
- Two buttons: "Log & Next" (primary), "Alert" (RED only, secondary red outline)

### Crew
- Search optional later; MVP = simple list
- Filter chips: All | Green | Amber | Red (horizontal scroll)
- FAB or top "+" for add worker — orange circle

### Settings
- Grouped glass sections: Account | Crew | Shift | About
- Large readable rows, icons left

### Auth
- Veltra wordmark + small hard-hat icon
- Friendly one-liner: "Heat safety for your crew"
- Minimal fields, orange CTA

---

## Icons

Use Material Symbols Rounded — friendly, not sharp corporate.

| Context | Icon |
|---------|------|
| Scan | `nfc` or `sensors` |
| Crew | `groups` |
| Settings | `settings` |
| Safe | `check_circle` |
| Caution | `warning_amber` |
| Danger | `error` |
| Voice | `mic` |
| WBGT | `wb_sunny` |

---

## Do / Don't

**Do**
- Big color blocks for status
- Short labels
- Warm backgrounds
- Glass layers for depth
- Smooth transitions

**Don't**
- Pure black `#000` backgrounds
- Purple gradients
- Dense data tables on mobile
- Long explanatory modals
- Tiny gray text on dark cards

---

## Asset checklist (later)

- [ ] Veltra logo (wordmark, orange)
- [ ] App icon (hard hat + orange accent)
- [ ] Empty state illustration (optional, friendly line art)

---

## Implementation files

Design tokens live in:
```
lib/core/theme/veltra_colors.dart
lib/core/theme/veltra_theme.dart
lib/core/theme/veltra_text_styles.dart
lib/core/widgets/glass_card.dart
lib/core/widgets/veltra_nav_bar.dart
```

Reference this doc when building any screen.
