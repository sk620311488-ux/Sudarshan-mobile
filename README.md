# Sudarshan Mobile

Separate Android-ready mobile scaffold for Sudarshan.

Notes:
- Existing desktop Tkinter app remains untouched.
- This new codebase is designed for Flutter.
- Visual style intentionally follows the current app's warm, soft-card feel.
- Includes auth entry, home shell, tests, notebook, admin, trial-ready promo section, and a demo quiz/result flow.

APK path after installing Flutter:

```bash
flutter create .
flutter pub get
flutter run
flutter build apk --release
```

Next recommended steps:
- Connect Firebase Auth
- Read shared tests from Firestore
- Sync user progress with Firestore
- Replace demo repository with live Firestore data
- Add paid plan / trial gating

Files to check first:
- `lib/screens/auth_gate.dart`
- `lib/screens/home_shell.dart`
- `lib/screens/quiz_screen.dart`
- `lib/screens/result_screen.dart`
- `firebase_mobile_config.example.json`
