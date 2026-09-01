# NeuroNova — AI-based Cognitive Gaming & Memory Assistance Platform

This repository contains the complete implementation for **NeuroNova**, a localized, offline-first assistive cognitive care and gaming platform designed for elderly and neuro-divergent individuals.
2. Replace the generated `lib/` folder and `pubspec.yaml` with the ones from
   this zip.
3. Add the dependencies (this fetches current versions automatically, so you
   don't have to trust any version numbers I might have gotten stale):
   ```
   flutter pub add flutter_secure_storage sqflite path path_provider crypto speech_to_text
   ```
4. **Android permission** — `speech_to_text` needs mic access. Add this inside
   `<manifest>` in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   ```
5. Run it:
   ```
   flutter pub get
   flutter run
   ```

## What's actually working

- **Register/Login** — fully local. Username + password are hashed (SHA-256)
  and stored in a local SQLite table; there's no server anywhere in this flow.
- **Session persistence** — a session flag is saved in `flutter_secure_storage`
  on login. On next app open, `SplashScreen` checks that flag (a local read,
  zero network calls) and skips straight to the dashboard if it's set.
- **Read & Memorize & Speak** — pick a genre → pick a language → pick a text →
  speak it (on-device speech-to-text, works offline on most Android phones
  once the language pack is installed) → score is computed locally by simple
  word-overlap → attempt is saved to SQLite and shows up in "Recent activity"
  on the dashboard.
- **Manual fallback** — if the speech engine isn't available (e.g. running on
  an emulator without mic access during the demo), it automatically falls
  back to a text field so the flow never gets stuck on stage.

## What's intentionally stubbed for now

- "Games" and "Reminders" buttons on the dashboard are disabled placeholders
  for teammates to wire up.
- Only 4 sample texts are seeded in `lib/data/sample_texts.dart` (2 languages).
  Real multilingual content and the offline-download-a-language-pack idea
  aren't implemented yet — this just proves the selection → speak → score →
  save loop works.
- The caregiver/admin dashboard isn't built — this only covers what the
  patient sees.
- Scoring is a naive word-overlap percentage, not the real comparison
  algorithm — good enough to demo, not tuned.

## Why local-only auth, on purpose

Given the PS's low-connectivity requirement, a patient's device shouldn't
need internet just to open the app. Local accounts (one per device) sidestep
that entirely. If the team wants a caregiver to check progress from a
different device later, that's better handled as an optional sync layer on
top of this — not a reason to make login itself depend on a server.
