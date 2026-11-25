# Plan 4 — NFC test tags

> **Status:** Done.
> **Goal:** The iPhone 17 Pro reads a real NDEF text tag, validates the line, and sends a good line through the plan 3 save path. A file in the repo holds the lines to paste into NFC Tools. The HTML phone can paste the same line.

Depends on plan 3. Say **"code plan 4"** to start.

## Adjusted before coding

Plan 3 already saves through `applyScenario` for simulated readings, and it stores a bench “presented pod” on `demo_config`. These seams follow that:

- A test-tag line is saved with `saveTestTag` on the same repository. It reuses the pod-mismatch rule and the one-attempt-id transaction. It does not run a simulated scenario, and it does not derive a sweat rate. Rate stays on the simulated path.
- The pod id in the line is the presented pod. The worker’s `pod_id` is the assignment. The Demo Admin presented-pod field stays for simulated check-ins.
- Physical test tag and Sensor pod start a real session from **Check in**. They no longer stop on “connects in the next update.”
- The iOS deployment target is 15.0. Current Xcode rejects anything lower, and that is still well below the iPhone 17 Pro.
- Sensor pod uses the same reader and only returns diagnostics. It never writes a check-in and never stores source `sensor_pod`.
- The HTML preview pastes a line into the same validator. It does not pretend the computer read a tag.

## In scope

### Payload file

Add `nfc/test-payloads.md`. Each block is one line, meant to be copied alone, plus the result Veltra should show. Writing is done in **NFC Tools**: Write → Add a record → Text → paste the line → write. One line per tag, or overwrite one tag between tests. Read the tag back in NFC Tools before opening Veltra.

Use a writable NDEF tag (NTAG213, NTAG215, NTAG216, or another NFC Forum Type 2 tag). Do not write these lines to Lucas’s board.

Valid lines from the spec:

```text
VELTRA1,TAG01,34.2
VELTRA2,TAG02,35.1,12.5,820
```

- `VELTRA1` — pod id, forehead temperature °C. Volume and conductivity stay unavailable. Source `nfc_test_tag`. The UI says **Test tag**.
- `VELTRA2` — pod id, forehead °C, strip volume µL, conductivity µS/cm. Still one snapshot, so no sweat rate unless a simulated scenario is what produced the second point.

Also include lines that must not save, each with the expected sentence:

| Line | Expected |
|------|----------|
| `HELLO` | Unrelated tag, no save |
| `VELTRA1,TAG01` | Too few fields, no save |
| `VELTRA2,TAG02,35.1,12.5` | Too few fields, no save |
| `VELTRA9,TAG01,34.2` | Unknown prefix, no save |
| `VELTRA1,TAG01,hot` | Not a number, no save |
| `VELTRA1,,34.2` | Missing pod id, no save |
| `VELTRA2,TAG02,35.1,-1,820` | Volume out of range, no save |
| A second text record after a valid line, if the writer can do it | Reject, no save |

Temperature is accepted only inside a stated range (document the range in the file, starting from 30.0–42.0 °C). Conductivity and volume must be ≥ 0. Reject anything that is not a single text record with a `VELTRA1` or `VELTRA2` prefix.

### Reader

- Add `nfc_manager` and the NDEF companion. Confirm versions against the Flutter SDK at `~/fvm/default/bin/flutter` before upgrading unrelated packages.
- iOS: `NFCReaderUsageDescription`, Near Field Communication Tag Reading capability, and a deployment target high enough for that plugin. Session starts when the worker taps **Check in** and the source is Physical test tag. Cancel closes the session and returns to Ready with no save.
- Android manifest NFC permission only if the Android project already builds. Do not spend the plan on a Gradle migration.
- Decode the NDEF text record. Unknown tag types and empty reads are **No tag found** or **Hold the phone closer**, matching what the session actually returned.
- A reader callback that fires twice saves one check-in.
- Diagnostics on Demo Admin: NFC available or not, tag technology, identifier when the platform provides one, duration, result, and a short recent-attempt list. Raw payload text is shown in that admin list.
- Sensor pod source starts a session, reports what tag technology was seen, and does not write a check-in and does not label anything `sensor_pod`. Leave a single reader interface with a pod implementation that returns diagnostics only, so Lucas’s command sequence can replace that implementation later.
- Switching source is explicit. A failed tag read stays failed until the source is changed.
- The HTML phone gets a text box: paste a payload line, run the same validator, and show save or reject. It never claims the computer read a tag.

## Out of scope

- ISO 15693 block reads, CRC, calibration, and saving `sensor_pod` measurements
- Firebase
- Background or lock-screen NFC on iOS

## Files

| Area | Change |
|------|--------|
| `nfc/test-payloads.md` | Copy-paste lines and expected results |
| `pubspec.yaml`, `ios/Runner/Info.plist`, entitlements, Podfile / deployment target | NFC enabled on device |
| `lib/services/` reader + parser, scan source switch | Same save path as plan 3 |
| Demo Admin diagnostics | The fields above |
| `phone-preview/` | Paste-a-line box |

## Acceptance

On the iPhone 17 Pro, with NFC on, airplane mode allowed as long as NFC still works:

- Both valid lines save once and show **Test tag** on the worker success screen and the supervisor row.
- Every reject line in the payload file leaves the roster unchanged.
- Cancel, then a successful retry, saves one record.
- Holding the phone away until the session ends does not check the worker in.
- Two callbacks for one tap do not create two rows.
- Sensor pod source shows a diagnostic result and the roster does not change.
- Reset from plan 3 still removes only the demo crew, including tag-sourced check-ins.
- The HTML paste box accepts `VELTRA2,TAG02,35.1,12.5,820` and rejects `HELLO`.

## After this plan

The local app and the test-tag demo are complete. The next program, not this one, is Lucas’s known-good frame behind the pod reader, then Firebase so a second phone can receive the same check-in.
