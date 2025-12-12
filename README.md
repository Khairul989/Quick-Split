# quicksplit

A new Flutter project.

## Local Setup (Secrets & Firebase)

This repo intentionally does **not** commit local secret/config artifacts.

### Envied (.env)

- Create a local environment file: copy [.env.example](.env.example) to `.env` and fill in values.
- Generate code (Envied + other generators): `dart run build_runner build --delete-conflicting-outputs`

### Firebase (FlutterFire)

These files are ignored by git for safety:

- [firebase.json](firebase.json)
- [lib/firebase_options.dart](lib/firebase_options.dart)
- [android/app/google-services.json](android/app/google-services.json)
- [ios/Runner/GoogleService-Info.plist](ios/Runner/GoogleService-Info.plist)
- [macos/Runner/GoogleService-Info.plist](macos/Runner/GoogleService-Info.plist)

To set Firebase up on a new machine:

- Install FlutterFire CLI (once): `dart pub global activate flutterfire_cli`
- Configure: `flutterfire configure` (regenerates Firebase config for your platforms)

If you prefer, you can also download the platform config files from Firebase Console and place them at the paths above.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
