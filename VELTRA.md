# Veltra (HeatShield V3) — Project Context

> Living reference for AI assistants and team members. Update as hardware, validation, and software ship.

## Team

| Name | Role | Focus |
|------|------|-------|
| **Sanskar** | Software | Flutter app, ML pipeline, Firebase, dashboard |
| **Lucas** | Hardware | NFC pod, sensors, cartridge, RF energy harvesting, 3D prints |
| **Ryan** | Validation / Business | Contractor outreach, EMR pitch, pilots, competition submissions |

**Mission:** Win top-tier innovation competitions (Conrad Challenge, Blue Ocean, Diamond Challenge) with a credible product + business story, not a science-fair demo.

**Prior competition result:** Top-30 global alternate finalist at Conrad (referenced in full plan).

---

## Product (One Sentence)

Zero-battery, NFC-powered hard-hat sweat cartridge + foreman smartphone app that reads skin temp, sweat rate, and salinity trends in <1s during rest breaks and outputs GREEN / AMBER / RED screening actions—protecting workers from heat strain and contractors from EMR / insurance spikes.

**Naming note:** Full business plan uses **HeatShield V3**; repo/code uses **Veltra**. Pick one brand for judges and stick to it everywhere.

---

## Problem & Business Hook

- ~40 US outdoor worker heat deaths/year is the headline stat; real pain is **productivity loss**, **OSHA citations**, and especially **EMR (Experience Modification Rate)**.
- One severe heat incident can push EMR from 1.0 → 1.25+ for years → **+$25k/yr insurance** and **loss of bid eligibility** on major projects.
- Existing wearables fail on construction sites: charging, loss, pairing, cost ($200–400/unit).

**Unit economics (target vs prototype):**
- Disposable cartridge: **$0.25** scale / **~$1.10** prototype
- Reusable pod + cable + dock: **~$3.50** scale amortized over 100 shifts
- **~$0.28/shift** at scale vs **~$1.34/shift** prototype batch

---

## Hardware Architecture (3 Layers)

1. **Reusable Core Pod** (rear harness ratchet) — TI RF430-class NFC MCU, ADC, EEPROM, RF energy harvesting, etched antenna through 2–3mm plastic.
2. **Flex ribbon + front dock** — Routes signals to forehead; elastomer compression pads contact cartridge traces.
3. **Disposable sweat cartridge** — Microfiber pad, paper microfluidic channel, printed graphite traces. No wires. Peel-and-stick per shift.

**Four sensing mechanisms:**
1. Sweat rate — impedance fill ladder (F3)
2. Salinity shift — conductivity cell, microamp AC (E5)
3. Skin temperature — NTC thermistor (T4), ±0.1°C target
4. Software Z-score baseline — personal deviation vs multi-shift history (replaces expensive ion-selective membranes)

**NFC payload:** 24 bytes (6 memory blocks), magic header `0x48 0x53` ('H''S'), checksum + continuity loop validation.

**Power:** No battery. Phone NFC field harvests energy → 1.8–3.0V → ADC read → broadcast to phone in <1s.

**Known hardware risks (from plan):** sweat creep/shorting at dock, ANSI Z89.1 clearance (rear mount mitigates), snapshot-only (no continuous alarm between breaks), evaporative cooling lowering skin temp vs core strain.

---

## Software Stack (Final Decisions)

| Layer | Technology |
|-------|------------|
| Mobile | Flutter (iOS + Android) |
| NFC | `flutter_nfc_kit` (ISO/IEC 15693) |
| Local DB | SQLite (`sqflite`), offline-first |
| On-device ML | XGBoost → **TFLite** via `tflite_flutter` (planned) |
| Voice | Vosk (`vosk_flutter`), offline, constrained grammar |
| State | Riverpod |
| Backend | Firebase (Auth, Firestore, Storage, Hosting, Functions, FCM) |
| Dashboard | React + Firebase Hosting |
| Weather / WBGT | Dio + external API, cached |

**User model:** Foreman/supervisor app only. **No worker accounts.** Workers wear hat + cartridge; zero app interaction.

**App tabs:** Scan (primary) | Crew | Settings

**Scan flow:** Tap Scan → NFC read → validate → identify worker (NFC ID / roster / voice) → 8D feature vector → ML inference → GREEN/AMBER/RED + action → Log & Next → SQLite → sync Firestore.

**Cold start (shifts 1–4):** Hybrid rule engine (WBGT + population thresholds). **Shift 5+:** Personalized baselines (μ, σ) + XGBoost.

---

## ML Pipeline

### 8-D Feature Vector

| # | Feature | Source |
|---|---------|--------|
| 1 | Forehead skin temp | T4 thermistor / ADC |
| 2 | Skin temp rate of change | (T_now − T_prev) / Δt |
| 3 | Sweat conductance / salinity shift | E5 conductivity cell |
| 4 | Sweat accumulation rate | F3 impedance ladder |
| 5 | Ambient WBGT | Weather API |
| 6 | Elapsed shift time | Clock since shift start |
| 7 | Personal salinity Z-score | (current − baseline_μ) / baseline_σ |
| 8 | Acclimatization factor | 1.0–2.0 from days worked |

### Output

| Status | Risk | Action |
|--------|------|--------|
| GREEN | < 0.35 | Continue work |
| AMBER | 0.35–0.70 | Drink 500mL electrolyte; re-scan in 30 min |
| RED | > 0.70 | Mandatory 15-min shade rest |

### Training data strategy (plan vs reality)

**Plan:** JOS-3 physics thermoregulation + public datasets (EPA wearables, firefighter heat stress) + future field data.

**Current implementation (`veltra_ml/generate_model.py`):**
- Real anchor: Mendeley firefighter dataset (~21 subjects) → skin temp, core temp, weight loss, age, body fat stats only.
- Synthetic: 10k samples via multivariate normal + hand-tuned thresholds for labels.
- Model: XGBoost classifier, exported as `heat_risk_model.json` (not yet TFLite).
- Artifacts: `training_data.csv`, `real_data_statistics.csv`, `flutter_demo_samples.csv`.

**Label distribution (10k synthetic):** GREEN 56% | AMBER 36% | RED 7%

---

## Firebase Schema (Firestore)

**workers:** id, name, employee_id, role, site_id, nfc_id, photo_url, created_at

**scans:** worker_id, timestamp, skin_temp, sweat_conductance, sweat_volume, sweat_rate, wbgt, status, recommendation, z_score, synced_at

**baselines:** worker_id, mu/sigma salinity & temp, shift_count, updated_at

---

## Validation Timeline (from full plan)

| Phase | When | What |
|-------|------|------|
| 1 | Months 1–2 | Ryan: 10 contractor calls; Lucas: TI RF430 benchtop + syringe pump synthetic sweat |
| 2 | Months 3–4 | 3-subject athletic trial (basketball/tennis); Flutter app + SQLite + Vosk |
| 3 | Months 5–6 | Provisional patent; contractor pilots; testimonials |
| 4 | Months 7–8 | Conrad, Diamond, Blue Ocean submissions |

**Athletic trial gold standard:** Pre/post nude body mass balance, reaction time vs HeatShield biometrics.

**OSU partnership:** Microfluidic testing, potential endorsement letter.

---

## Build decisions (locked Aug 2026)

| Decision | Choice |
|----------|--------|
| App brand | **Veltra** |
| Risk engine MVP | Dart rule engine (`label_risk` port) |
| Scan flow | Mock scan → speech-to-text worker match → results |
| Shift timer | Auto-start first scan of day |
| Weather | Open-Meteo |
| Design | Warm construction glass — see `DESIGN.md` |
| Build plans | `plans/MASTER_PLAN.md` (phases 0–5) |

## Current Repo State (as of Aug 2026)

| Area | Status |
|------|--------|
| Flutter app | Phase 2 complete — workers CRUD, SQLite offline, Firestore sync, demo crew |
| Design & plans | `DESIGN.md`, `plans/*`, `LOCAL_DEV.md` |
| Firebase project | Created blank in Console — needs auth, Firestore, flutterfire |
| ML pipeline | Python script + synthetic 10k dataset + XGBoost JSON model |
| Hardware | Not in this repo (Lucas) |
| React dashboard | Deferred |
| Patent | Planned provisional before competition entries |

---

## Competition Pitch Angles

- **Technical depth:** Offline ML + NFC-through-shell + zero-battery sensors
- **Real problem:** EMR / OSHA / productivity, not just "40 deaths"
- **Trade-offs:** XGBoost not LLM; Firebase not AWS; snapshot not continuous BLE
- **User design:** Zero worker friction; glove-friendly UI; haptic + voice in noise
- **Live demo requirement:** Judges expect working NFC tap on stage—deck alone is not enough

**Self-assessed score in plan:** 929/1000 (Global Finalist tier)—contingent on working prototype + live demo.

---

## Critical Gaps to Close Before Judging

1. **Live NFC demo** — phone reads through hard hat shell, unedited video
2. **Brand consistency** — Veltra vs HeatShield
3. **ML honesty** — frame as rule-augmented screening; validate on real trial data, not synthetic accuracy
4. **TFLite export** — plan says TFLite; current export is raw XGBoost JSON
5. **Flutter MVP** — scan → parse → infer → display path, even with mock NFC payload first
6. **Contractor testimonial** — EMR / bidding impact quote on video
7. **Athletic field trial data** — Z-score plots in deck

---

## Key Files

```
veltra/
├── VELTRA.md              ← this file
├── veltra_full_plan.pdf   ← business + hardware + validation + rubric
├── software_plan.pdf      ← software architecture + stack + schema
├── veltra_ml/
│   ├── generate_model.py
│   ├── training_data.csv
│   ├── heat_risk_model.json
│   ├── real_data_statistics.csv
│   └── flutter_demo_samples.csv
└── lib/main.dart          ← placeholder Flutter app
```

---

## External References

- Firefighter dataset: https://data.mendeley.com/datasets/7ghxcsd9sz/1
- NFC: ISO/IEC 15693, 13.56 MHz
- Target MCU family: TI RF430 series (energy harvesting NFC)

---

## Assistant Notes

When implementing software:
- Prefer offline-first; construction sites often have no signal.
- Never claim clinical core body temperature diagnosis—screening tool only.
- Shifts 1–4 must use conservative rule engine before personalized ML.
- Mock NFC payloads are fine for UI/ML integration until Lucas's hardware is ready.
- Do not cite synthetic ML accuracy to judges as proof of real-world performance.

flutter pub get
open -a Simulator
flutter run
