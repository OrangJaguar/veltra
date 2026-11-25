# Veltra test tag lines

Write these with **NFC Tools**: Write → Add a record → Text. Paste **one line**, then write. One line per tag, or overwrite the same tag between tests. Read the tag back in NFC Tools before opening Veltra.

Use a writable NDEF tag (NTAG213, NTAG215, NTAG216, or another NFC Forum Type 2 tag). Do not write these lines onto Lucas’s board.

Temperature is accepted only from **30.0 to 42.0 °C**. Strip volume and conductivity must be **0 or greater**. Anything else is rejected and the roster does not change.

## Saves

```text
VELTRA1,TAG01,34.2
```

Check-in saved. Source **Test tag**. Forehead 34.2 °C. Strip volume, conductivity, and sweat rate stay unavailable.

```text
VELTRA2,TAG02,35.1,12.5,820
```

Check-in saved. Source **Test tag**. Forehead 35.1 °C, strip volume 12.5 µL, conductivity 820 µS/cm. Sweat rate stays unavailable. A test tag is one snapshot, so it does not compute a rate.

If the worker is assigned a different pod, both lines show **Wrong pod for this worker.** and do not save. No assignment is not a mismatch.

## Rejects

```text
HELLO
```

Unrelated tag.

```text
VELTRA1,TAG01
```

Too few fields.

```text
VELTRA2,TAG02,35.1,12.5
```

Too few fields.

```text
VELTRA9,TAG01,34.2
```

Unknown prefix.

```text
VELTRA1,TAG01,hot
```

Not a number.

```text
VELTRA1,,34.2
```

Missing pod id.

```text
VELTRA2,TAG02,35.1,-1,820
```

Volume out of range.

```text
VELTRA1,TAG01,29.9
```

Temperature out of range.

A second text record on the same tag, if the writer can add one, shows **Not a single text record.** Holding the phone away until the session ends shows **Hold the phone closer**. A tag with no text record shows **No tag found**. None of these check the worker in.
