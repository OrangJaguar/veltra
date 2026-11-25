# Veltra

Worker self check-in for construction crews. The current build is local-first, with simulated scans first and NDEF test tags after that.

## Docs

| File | Purpose |
|------|---------|
| [DESIGN.md](DESIGN.md) | UI/UX design system |
| [VELTRA.md](VELTRA.md) | Product & team context |
| [LOCAL_DEV.md](LOCAL_DEV.md) | How to run the app locally |
| [plans/MASTER_PLAN.md](plans/MASTER_PLAN.md) | Current program — say "code plan N" |
| [plans/mvp-MASTER_PLAN.md](plans/mvp-MASTER_PLAN.md) | Archived foreman app (phases 0–5) |

## Quick start (after Phase 1)

```bash
flutter pub get
open -a Simulator
flutter run
```

Setup first: [plans/phase-00-prerequisites.md](plans/phase-00-prerequisites.md)
