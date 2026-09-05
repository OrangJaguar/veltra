# Phase 3 — Mock Scan Pipeline (Core Product Loop)

> **Goal:** Tap scan → mock sensor data → voice worker match → risk engine → results → log scan → update baseline & shift.

---

## Prerequisites

- Phase 2 ✅ — workers exist in SQLite
- **Physical iPhone recommended** for speech-to-text testing (simulator is limited)

---

## Dependencies

```bash
flutter pub add speech_to_text
flutter pub add geolocator geocoding
flutter pub add http
flutter pub add flutter/services.dart  # HapticFeedback — built-in
```

---

## Services

| File | Purpose |
|------|---------|
| `lib/services/mock_scan_service.dart` | Generate realistic random sensor readings |
| `lib/services/risk_engine.dart` | Port `label_risk()` from Python |
| `lib/services/weather_service.dart` | Open-Meteo fetch + WBGT estimate + cache |
| `lib/services/shift_service.dart` | Auto-start shift on first scan of calendar day |
| `lib/services/baseline_service.dart` | Compute Z-score, update μ/σ after scan |
| `lib/services/speech_worker_matcher.dart` | STT → fuzzy match worker name |
| `lib/repositories/scan_repository.dart` | Save scan local + sync |

### MockScanService output
```dart
class SensorReading {
  double skinTemp;       // 36.0–39.0°C
  double sweatRate;      // 0.1–2.0 L/hr
  double salinity;       // 20–80 mmol/L (conductance proxy)
  double sweatVolume;    // 0.5–5.0 mL cumulative
  String mockNfcId;      // random hex — for future auto-match
}
```

Dev toggles (Settings, debug section):
- Force GREEN / AMBER / RED preset readings

### RiskEngine
Port exact thresholds from `veltra_ml/generate_model.py`:
- Input: `RiskInput` with 8 features
- Output: `RiskResult { status: GREEN|AMBER|RED, recommendation, riskScore }`
- Recommendations:
  - GREEN: "Continue work"
  - AMBER: "Drink 500mL water · re-scan in 30 min"
  - RED: "Rest 15 min in shade"

Compute derived fields before engine:
- `zScore = (salinity - muSalinity) / sigmaSalinity`
- `tempRate = (skinTemp - prevSkinTemp) / hoursSinceLastScan` (or 0 if first scan)
- `elapsedHours` from ShiftService
- `wbgt` from WeatherService cache
- `acclimatization` from baseline

**Cold start (shiftCount < 4):** optionally apply stricter margins (flag in engine).

### ShiftService
- Store `currentShiftStartedAt` in SQLite + Firestore `users/{uid}/meta/shift`
- On first scan where `lastScanDate != today` → set `currentShiftStartedAt = now`
- `elapsedHours = now - currentShiftStartedAt`

### WeatherService (Open-Meteo)
- Endpoint: `https://api.open-meteo.com/v1/forecast`
- Params: latitude, longitude, current=temperature_2m,relative_humidity_2m
- WBGT estimate (simplified): use heat index formula or documented approximation
- Cache 30 min in SQLite
- Fallback WBGT: 26.0 if offline/no GPS

GPS:
- Request location permission on first scan
- If denied → use last cached coords or default (Columbus OH ~39.96, -83.00 for dev)

### SpeechWorkerMatcher
Flow:
1. After mock scan completes → show voice overlay
2. `speech_to_text.listen()` for ~5 seconds
3. Fuzzy match transcript to worker names (case insensitive, contains, Levenshtein optional)
4. On match → proceed to results
5. On fail → show manual worker picker (glass list)

---

## Scan flow screens

| File | Purpose |
|------|---------|
| `lib/features/scan/screens/scan_screen.dart` | Main scan UI — big button, shift chip, WBGT chip |
| `lib/features/scan/screens/scan_results_screen.dart` | Status banner, worker, metrics collapsible, Log & Next |
| `lib/features/scan/widgets/voice_match_overlay.dart` | "Say worker name" glass overlay |
| `lib/features/scan/widgets/worker_picker_sheet.dart` | Manual fallback bottom sheet |
| `lib/features/scan/providers/scan_flow_provider.dart` | State machine for scan steps |

### Scan state machine
```
idle → scanning (800ms mock delay + haptic)
     → voiceMatch
     → computing (risk engine)
     → results
     → saving → idle
```

### Scan screen UI
- Gradient background (DESIGN.md)
- Top row: Shift timer chip | WBGT chip
- Center: pulsing orange "Scan Hard Hat" button (mock)
- Subtext: "Tap to read sensors" (4 words)

### Results screen UI
- Full status color banner + icon
- Worker name (Headline)
- Action text (Body)
- Expandable Details: skin temp, sweat rate, salinity, z-score, temp rate
- Primary: "Log & Next"
- RED only: "Alert" → share sheet stub ("Worker X — RED — rest required")

---

## Save scan (on Log & Next)

1. Insert `scans` SQLite row
2. Enqueue Firestore sync
3. Update worker `lastStatus`, `lastScanAt`
4. BaselineService: increment shiftCount, rolling update μ/σ for salinity & temp
5. Navigate back to scan idle

---

## iOS permissions (agent adds)

`ios/Runner/Info.plist`:
```xml
<key NSMicrophoneUsageDescription>Veltra needs the microphone to identify workers by name after a scan.</key>
<key NSSpeechRecognitionUsageDescription>Veltra uses speech recognition to match the worker you name to your crew roster.</key>
<key NSLocationWhenInUseUsageDescription>Veltra uses your location to fetch local heat (WBGT) conditions.</key>
```

Android `AndroidManifest.xml`:
- `RECORD_AUDIO`, `ACCESS_FINE_LOCATION`

---

## Acceptance criteria

- [x] Tap scan → loading → voice overlay appears
- [x] Say worker name → matches correct worker (on device)
- [x] Manual picker works if voice fails
- [x] Results show GREEN/AMBER/RED with correct action text
- [x] Log & Next saves scan, updates crew list status dot
- [x] Shift timer auto-starts on first scan of day
- [x] WBGT chip shows value (from API or fallback)
- [x] Force RED dev toggle produces RED result
- [x] Haptic on scan complete

---

## Testing (you)

| Test | How |
|------|-----|
| Mock scan UI | Simulator — tap scan, use **manual picker** if voice unavailable |
| Voice match | **Physical iPhone** — add worker "Jake", scan, say "Jake" |
| Risk engine | Force RED toggle → verify banner + Alert button |
| Shift timer | First scan → note time; second scan → elapsed increases |
| WBGT | Allow location → chip shows number; deny → fallback still works |
| Persistence | Log scan → Crew tab shows colored dot on worker |

---

## Firebase Console actions (you)

- Verify `users/{uid}/scans` collection populates after Log & Next
- Verify `users/{uid}/meta/shift` updates

---

## Not in Phase 3

- Real NFC parsing
- TFLite model
- Trend charts
- PDF export

---

## Next phase

**"code phase 4"** → [phase-04-crew-history.md](./phase-04-crew-history.md)
