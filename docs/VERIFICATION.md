# Verification evidence

## Firebase backend

- Project: `device-streaming-f3ea5c85`; default Firestore database in `asia-south1`.
- Firebase Authentication Email/Password provider was initialized on the free tier. REST configuration readback confirmed the provider is enabled and password sign-in is required. Authorized domains include `localhost`, `127.0.0.1`, and `mutual-management.vercel.app`.
- Production Firestore rules passed the emulator security suite (6 tests), including owner isolation, schema/amount checks, contribution immutability, monthly and quarterly SIP dates, deterministic contribution IDs, and concurrent duplicate protection.
- Production Firebase Web SDK smoke verification passed with two unique temporary `@example.test` accounts: account creation/sign-in; valid goal, SIP, and contribution writes; second-client synchronization; atomic duplicate rejection; fresh-account isolation; and cross-account read denial.
- The temporary verification records and accounts were removed after the run. Generated passwords, tokens, and test account identifiers were kept outside the repository and are not recorded here.
- No billing plan was changed. No production user records were used in the verification.
