# Veltra — Look and navigation

> The check-in program in [MASTER_PLAN.md](./MASTER_PLAN.md) is done. This program puts that behavior back into the original warm glass screens.
> Plans 1–3 put the check-in behavior on screen. Plans 4–6 put the original look back. The check-in pages used plain text lists instead of the avatar, icon tiles, profile, and buttons in the PNGs. Read `.cursor/skills/veltra-design/SKILL.md` before any of these.

The reference pictures are `Veltra-Main-Screens.png` and `Veltra-All-Screens.png`. Cream background, orange circle, frosted cards, Plus Jakarta Sans. The current HTML phone is a stack of text buttons and is not the target.

## Plans

| Plan | File | Leaves you with | Status |
|------|------|-----------------|--------|
| **1** | [ui-01-chrome.md](./ui-01-chrome.md) | Skinny glass role bar, a distinct bottom bar per role, no Exit demo, app opens on the worker scan page. Insides can still be plain. | ✅ |
| **2** | [ui-02-worker.md](./ui-02-worker.md) | Worker Scan, History, and Settings. Big scan circle, manual entry, saved card, trend line with a metric switch. | ✅ |
| **3** | [ui-03-supervisor-admin.md](./ui-03-supervisor-admin.md) | Supervisor dashboard, workers, and settings. Admin bench, crew, and tools. Same chrome. | ✅ |
| **4** | [ui-04-result.md](./ui-04-result.md) | Saved check-in looks like the original result: avatar, status word, icon tiles, trend, orange button. | ✅ |
| **5** | [ui-05-people.md](./ui-05-people.md) | Dashboard and roster rows with avatars. Worker profile brings back height, weight, age, and BMI. | ✅ |
| **6** | [ui-06-controls.md](./ui-06-controls.md) | Real buttons, spaced scan-source chips, and the motion from the design notes. | ✅ |

HTML in `phone-preview/` updates in the same pass as the Flutter screens. NFC behavior from plan 4 stays. These plans change the frame and the pages, not the save rules.

The result card shows GREEN, AMBER, or RED again, from the existing risk engine. That color does not replace the supervisor roster statuses.
