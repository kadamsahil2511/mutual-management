# Android verification

- Device: `emulator-5554`, Android API 35, package `com.kadamsahil.mutual_management`.
- Integration command: `flutter test integration_test/app_test.dart -d emulator-5554` — passed (1 test).
- The guest flow opened the overview, searched the fund catalogue for “Corporate” and verified both matching funds, opened the “How a mutual fund works” article, then submitted the empty goal form and verified the name and positive-amount validation messages. Search text entry exercised the on-screen text input; this test does not assert scrolling while the keyboard is open.
- Portrait and landscape rendering were checked on-device and captured with `adb screencap`. The screenshots show the overview at 1080×2400 portrait and 2400×1080 landscape:
  - [Portrait screenshot](../screenshots/android-portrait.png)
  - [Landscape screenshot](../screenshots/android-landscape.png)
- The debug integration build reported a Kotlin Gradle Plugin compatibility warning for `firebase_auth` and `firebase_core`; the build and test completed successfully. Release signing/build verification was handled separately.
