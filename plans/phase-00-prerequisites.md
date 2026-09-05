# Phase 0 — Prerequisites & Setup

> **Who does this:** You (Sanskar), before any coding starts.  
> **Agent does:** Nothing — this is your checklist.

---

## What you need installed

### 1. Flutter SDK

Check if installed:
```bash
flutter --version
flutter doctor
```

`flutter doctor` should show at least:
- ✅ Flutter
- ✅ Xcode (for iOS Simulator on Mac) — or Android toolchain for Android only
- ⚠️ Android license — run `flutter doctor --android-licenses` if needed

If Flutter is missing: https://docs.flutter.dev/get-started/install/macos

### 2. Xcode (for iOS Simulator — recommended on Mac)

- Install from Mac App Store
- Open Xcode once → accept license
- Install iOS Simulator: Xcode → Settings → Platforms → iOS

### 3. Node.js (for Firebase CLI)

```bash
node --version   # need v18+
npm --version
```

Install: https://nodejs.org

### 4. Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

Browser opens — sign in with the Google account you used for Firebase Console.

---

## Firebase Console setup (Spark / free plan)

You said you created a blank project **"veltra"**. Complete these steps:

### Step A — Enable Authentication

1. Go to https://console.firebase.google.com → select **veltra**
2. **Build** → **Authentication** → **Get started**
3. **Sign-in method** tab → enable **Email/Password** → Save

### Step B — Create Firestore database

1. **Build** → **Firestore Database** → **Create database**
2. Choose **Start in test mode** (we'll add proper rules in Phase 1)
3. Pick a location close to you (e.g. `nam5` / us-central) → Enable

> Test mode expires — Phase 1 will deploy secure rules scoped to `users/{uid}`.

### Step C — Register apps (Flutter needs this)

You need **one app per platform** you test on. Do both if you can:

#### iOS app
1. Project Overview (gear) → **Project settings**
2. **Your apps** → **Add app** → **iOS**
3. **Apple bundle ID:** `com.veltra.veltra` (must match Xcode — Phase 1 sets this)
4. Download **`GoogleService-Info.plist`** — save for Phase 1 (don't lose it)

#### Android app
1. **Add app** → **Android**
2. **Package name:** `com.veltra.veltra`
3. Download **`google-services.json`** — save for Phase 1

### Step D — Note your project ID

In Project settings, copy:
- **Project ID** (e.g. `veltra-xxxxx`)
- You'll need this for `flutterfire configure`

---

## Connect Firebase to Flutter (run once, after Phase 1 starts OR now)

From project folder:

```bash
cd /Users/SANSG/Desktop/veltra

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Make sure pub global bin is on PATH (add to ~/.zshrc if needed):
export PATH="$PATH:$HOME/.dartServer/bin:$HOME/.pub-cache/bin"

# Configure — selects your Firebase project, generates firebase_options.dart
flutterfire configure
```

When prompted:
- Select project **veltra**
- Select platforms: **ios**, **android** (space to toggle, enter to confirm)
- It writes `lib/firebase_options.dart` and updates native config files

**If `flutterfire configure` fails:** Phase 1 agent can guide you — you must have Steps A–C done first.

---

## How to run & view the app locally

**You do NOT code iOS and Android separately.** One Flutter codebase → runs on both.

### iOS Simulator (easiest on Mac)

```bash
cd /Users/SANSG/Desktop/veltra
open -a Simulator          # boot iPhone simulator
flutter devices            # should list an iPhone simulator
flutter run                # builds and launches app
```

While running:
- **`r`** = hot reload (UI changes instantly)
- **`R`** = hot restart (full restart)
- **`q`** = quit

### Physical iPhone (later, for speech/NFC)

- Connect USB → trust device
- Apple Developer free account lets you run ~7 days on device
- `flutter run` picks connected device

### Android Emulator

1. Install Android Studio → Device Manager → Create virtual device
2. Start emulator
3. `flutter run`

### Which to use for MVP?

| Feature | Simulator | Physical phone |
|---------|-----------|----------------|
| UI / navigation | ✅ | ✅ |
| Firebase Auth | ✅ | ✅ |
| Speech-to-text | ⚠️ Limited / fake | ✅ Best |
| NFC | ❌ | ✅ iPhone only |
| Haptics | ❌ | ✅ |

**Recommendation:** Build UI on **iOS Simulator**. Test **speech-to-text on your iPhone** in Phase 3.

---

## iOS permissions (Phase 3 — speech)

When we add microphone, you'll need to allow in:
- `ios/Runner/Info.plist` → `NSMicrophoneUsageDescription`
- `ios/Runner/Info.plist` → `NSSpeechRecognitionUsageDescription`

Phase 3 plan includes exact strings.

---

## Environment checklist

Before saying **"code phase 1"**, confirm:

- [ ] `flutter doctor` passes (no critical errors)
- [ ] iOS Simulator opens OR Android emulator works
- [ ] Firebase project **veltra** exists
- [ ] Email/Password auth **enabled**
- [ ] Firestore database **created** (test mode OK for now)
- [ ] iOS and/or Android app registered in Firebase Console
- [ ] `firebase login` completed in terminal
- [ ] (Optional now, required before first run) `flutterfire configure` completed

---

## Free plan limits (Spark) — you're fine for MVP

| Service | Free tier | Our usage |
|---------|-----------|-----------|
| Auth | 50k MAU | Tiny |
| Firestore | 1 GiB, 50k reads/day | Demo scale |
| Hosting | 10 GB | Dashboard later |
| Storage | 5 GB | Not used in MVP |

No billing required for development.

---

## Troubleshooting

**"No devices found"** → Open Simulator first or start Android emulator.

**Firebase auth fails on simulator** → Ensure `flutterfire configure` ran and `firebase_options.dart` exists.

**CocoaPods errors on iOS** → `cd ios && pod install && cd ..`

**Gradle errors on Android** → Open Android Studio once to finish SDK setup.

---

## Next step

When checklist is done → say **"code phase 1"**

Reference: [phase-01-skeleton-auth.md](./phase-01-skeleton-auth.md)
