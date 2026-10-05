# Verification evidence

## Version 1.1 mobile revision

The [mobile UX audit](MOBILE_UX_AUDIT.md) records the redesigned navigation, added screens and current screenshot evidence. Formatting and analysis pass, all 45 Flutter unit/widget tests pass, and the updated Android API 35 navigation/form integration test passes. Backend schemas, security rules, repositories and financial calculations retain the verified version 1.0 behavior described below.

Version 1.1.0 release builds passed. The signed APK was installed and launched on API 35 with portrait, landscape and keyboard checks. The production Vercel app passed mobile navigation/deep-link smoke verification. [Implementation CI](https://github.com/kadamsahil2511/mutual-management/actions/runs/37290176265) passed both Flutter and Firestore jobs. Android API 24 is supported by the build minimum; device verification used API 35.

## Firebase backend

- Project: `device-streaming-f3ea5c85`; default Firestore database in `asia-south1`.
- Firebase Authentication Email/Password provider was initialized on the free tier. REST configuration readback confirmed the provider is enabled and password sign-in is required. Authorized domains include `localhost`, `127.0.0.1`, and `mutual-management.vercel.app`.
- Production Firestore rules passed the emulator security suite (6 tests), including owner isolation, schema/amount checks, contribution immutability, monthly and quarterly SIP dates, deterministic contribution IDs, and concurrent duplicate protection.
- Production Firebase Web SDK smoke verification passed with two unique temporary `@example.test` accounts: account creation/sign-in; valid goal, SIP, and contribution writes; second-client synchronization; atomic duplicate rejection; fresh-account isolation; and cross-account read denial.
- The temporary verification records and accounts were removed after the run. Generated passwords, tokens, and test account identifiers were kept outside the repository and are not recorded here.
- No billing plan was changed. No production user records were used in the verification.

## Version 1.0 application and release baseline

- `flutter analyze`: no issues. `flutter test`: 39 passing unit/widget tests. Numerical coverage includes the 65-unit / ₹1,560 value / ₹60 gain fixture, zero returns, leap years, original month-end dates, missing history and partial overlap. HTTP tests cover malformed responses, timeouts, retry and six-hour/offline caching.
- Responsive checks: all requested widths (320, 390, 640, 768, 1024, 1280, 1920), plus 200% text scaling. The 1024px hero overlap was corrected and the 11 UI/responsive tests passed after that change. See [UI evidence](UI_VERIFICATION.md).
- Android API 35 integration: 1 passing guest navigation/search/learning/form-validation test. Portrait and landscape checked. See [Android evidence](ANDROID_VERIFICATION.md).
- Signed release APK 1.0.0 was installed and cold-launched successfully on the API 35 emulator. Signature verified with `apksigner` (RSA 2048, v2); manifest verified minimum API 24 and target API 36, with ARM32, ARM64 and x86_64 libraries. API 24 is the build minimum; device testing was on API 35.
- Release APK keyboard check: the goal form was scrolled with the Android keyboard visible; the Save goal button remained accessible above it. Android reported `mInputShown=true` and `mIsInputViewShown=true`. [Screenshot](../screenshots/android-keyboard.png).
- Web release built successfully and deployed using Vercel's prebuilt output. The protected preview's `/funds/118955` route returned HTTP 200 through `vercel curl`. Public production deep links also returned HTTP 200.
- Browser walkthrough against real Firebase: registered an empty account, compared two funds, created a goal, saved a monthly SIP, confirmed its due installment using the October 1 published NAV, and recorded a second fund contribution. On `https://mutual-management.vercel.app`, signing in from another browser session and reloading `/portfolio` retained both records: ₹2,000 contributed/value, two funds, dated partial holdings coverage and sector weights. Cancelling the SIP removed future recording actions while retaining the existing contributions. No browser page errors were reported. [Portfolio screenshot](../screenshots/portfolio-desktop.png).
- GitHub Actions passed both Flutter and Firestore jobs on the published main branch. The latest run is linked from the repository's Actions tab.

The screenshots contain only explicit test simulations. The release uses dated published disclosures; it does not claim full portfolio holdings, a comparable cross-AMC expense average, future returns, or a completed classroom assessment.
