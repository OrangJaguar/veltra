# Phase 4 — Crew History & Trends

> **Goal:** Worker detail with scan history, trend charts, status filters on crew list. Scan results screen enhanced with profile photo, metric grid, and live trend preview.

---

## Prerequisites

- Phase 3 ✅ — scans being saved

---

## Dependencies

```bash
flutter pub add fl_chart
```

---

## Files

| File | Purpose |
|------|---------|
| `lib/providers/scan_providers.dart` | Scans by worker, crew status filter |
| `lib/features/crew/widgets/trend_chart.dart` | Line chart with metric dropdown |
| `lib/features/crew/widgets/scan_history_list.dart` | Glass cards per scan + detail sheet |
| `lib/features/crew/widgets/status_filter_chips.dart` | All / Green / Amber / Red |
| `lib/core/widgets/metric_stat_box.dart` | 2-column reading boxes |
| `lib/features/crew/screens/worker_detail_screen.dart` | Profile, trend, history |
| `lib/features/scan/screens/scan_results_screen.dart` | Sticky header/footer, grid, graph |
| `lib/features/crew/screens/add_worker_screen.dart` | Edit mode via `/crew/:id/edit` |

---

## Scan results screen (enhanced in Phase 4)

- Sticky colored header with **worker profile photo**, status, name, recommendation
- Scrollable middle: **2-column metric boxes** (always visible, trend arrows vs last scan)
- Worker profile chips (ID, NFC, age, height, weight, BMI)
- **Trend chart** with metric dropdown (skin temp, z-score, salinity, sweat rate)
- Sticky footer: Log & Next + Alert (RED only)

---

## Worker detail screen

Sections:
1. **Header** — avatar, name, last status badge, timestamp
2. **Profile** — employee ID, NFC, body stats
3. **Trend chart** — last 10 scans, metric dropdown
4. **History list** — tap row for full scan detail sheet

---

## Crew list enhancements

- Filter chips (All / Green / Amber / Red)
- Richer list subtitles: ID, NFC, status, relative time
- **Edit worker** in 3-dot menu
- Pull-to-refresh sync

---

## Acceptance criteria

- [x] Worker detail shows all logged scans
- [x] Chart renders with 2+ scans (single-point + empty states before that)
- [x] Filter chips work on crew list
- [x] Relative timestamps on crew rows
- [x] Edit worker from 3-dot menu
- [x] Scan results: photo header, metric grid, sticky actions, trend chart
- [x] Worker picker UI cleaned up

---

## Testing (you)

1. Log 3+ scans for one worker (use mock + manual picker)
2. Open worker detail → chart shows lines
3. Filter crew by RED only → only RED workers show
4. Edit a worker from 3-dot menu
5. Scan → results screen shows photo, grid, graph, sticky Log & Next

---

## Next phase

**"code phase 5"** → [phase-05-settings-polish.md](./phase-05-settings-polish.md)
