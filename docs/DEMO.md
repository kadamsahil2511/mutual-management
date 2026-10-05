# Setup and demonstration

Open [Mutual Management](https://mutual-management.vercel.app), or install the APK from the [latest release](https://github.com/kadamsahil2511/mutual-management/releases/latest) on Android 7.0/API 24 or newer. Android may ask you to allow installation from the browser/file manager used to open the APK.

On phones, use **Home, Funds, Portfolio, Plans, More** along the bottom. **More** contains your account, calculators, risk questionnaire, learning, fixed deposits and activity. Forms and details have their own screens and a Back button; the keyboard can stay open while you scroll a form. Wider screens keep the desktop navigation.

## Five-minute walkthrough

1. Browse **Funds** as a guest. Search or swipe the category filters, and select two or three funds to compare. Use **More → Risk comfort** on mobile (or **Explore your risk comfort** in the desktop catalogue) for the questionnaire. Open details to see current NAV dates separately from dated AMC information; mobile details have Overview, Performance and Holdings sections.
2. Open the account icon, then **Sign in or create account**, with your own email and a password of at least eight characters. The account starts empty. **Forgot password?** opens a dedicated reset screen.
3. In **Plans → Goals → Create goal**, create a goal such as “Education”, target ₹1,20,000, and a future date. Leave the assumed return at 0% for a contribution-only estimate. Goals can be edited later.
4. In **Plans → SIPs → Create SIP plan**, create a ₹1,000 monthly HDFC Flexi Cap simulated SIP linked to the goal, with the first installment on a recent published NAV date. Select a due installment and review its amount, historical NAV, date and units. Choose **Confirm simulation** to save. Future installments require their own confirmation; cancelling stops future recording.
5. In **Portfolio**, inspect units, cost and valuation. Use **Add simulation** to record a second fund contribution and make pairwise overlap useful. The demonstration button fills a sample amount; it still requires review and explicit confirmation. Open **Activity** and tap a record to inspect its receipt. No money moves.
6. Reload or sign into the same account on another device. Goals, SIPs and contributions synchronize. Sign out before leaving a shared device.
7. From **More**, explore **Learn**, **Calculators** and **Fixed deposits**. Try a zero-return calculator scenario and follow official source links. FD maturity is an estimate, not a booking or guaranteed quoted payout.

If a due date precedes available scheme history, its NAV is unavailable. Choose a later due installment. A holiday uses the latest published NAV on or before that date, with a seven-day data-gap limit. If the API is offline, saved public data remains labelled as cached; refresh when connected.

## What to explain during assessment

- Responsive navigation plus dedicated forms, activity/receipts, account/recovery, comparison, questionnaire and article routes; Back/Forward and direct web URLs.
- Three repositories, Riverpod shared state and small stateful forms.
- Paise amounts, dates, email/password and assumptions are validated. Firestore independently checks ownership and record shapes; contributions cannot be edited or deleted by clients.
- January 31 → February 28/29 → March 31; historical SIP NAV; 1Y absolute returns; 3Y/5Y CAGR; zero-return end-of-month calculators.
- ₹1,000 at NAV ₹25 plus ₹500 at ₹20 produces 65 units. At NAV ₹24, value is ₹1,560 and gain ₹60. This is a unit-test fixture, not seeded user data.
- Partial holdings and incompatible expense bases remain visible instead of becoming fabricated results.

See [verification evidence](VERIFICATION.md), [data provenance](DATA_SOURCES.md), and [syllabus mapping](SYLLABUS.md). The app provides educational simulations, not personalized investment advice.
