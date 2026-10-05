# Mobile UX audit and revision

Requested after testing release 1.0.0. Review used the actual Flutter routes, Android screenshots, and form flows. The user confirmed use of this audit on 5 October 2026.

| Finding | Impact | Revision |
|---|---|---|
| Six destinations hidden behind a website-style header and drawer | Primary tasks need extra navigation; weak sense of place | Persistent Home, Funds, Portfolio, Plans and More bottom navigation on phones |
| Large editorial hero and long explanatory copy fill the home viewport | Useful account actions and data are below the fold | Compact mobile dashboard, balance, quick actions, goals and upcoming installments |
| Goals, SIPs and contribution forms appended beneath lists | Creating a record means scrolling through unrelated content | Dedicated create/edit goal, create SIP and contribution screens with Back navigation |
| Full transaction ledger mixed into portfolio analysis | Hard to find or inspect an individual contribution | Activity screen and individual contribution receipt |
| Account only exposed as a sign-out dialog; reset mixed into sign-in | Missing account destination and unclear recovery flow | Account and dedicated password-reset screens |
| Learning/calculators/deposits scattered across long pages | Useful tools difficult to find | More hub and separate calculator screen; compact learning list |
| Large fund cards stack every metric | Few useful choices fit on a phone | Compact mobile rows/cards and focused fund detail sections |
| Desktop spacing reused on phones | Excessive scrolling and weak action hierarchy | 16px page margins, compact page titles/card padding and persistent contextual navigation |

The blue, locally bundled fonts, rounded cards, real Firebase/API data and explicit simulation labels remain. Desktop retains its wider editorial layout. No new backend or financial calculations are needed.

The five-question risk questionnaire remains accessible from More. Mobile fund categories scroll horizontally. Each holding keeps its published NAV date, cache status, retry action and fund-details link. Missing prices display “Unavailable”, rather than a zero portfolio value.

## Verification — 5 October 2026

- Formatting and `flutter analyze` pass; all **45 unit/widget tests** pass. Added route tests cover bottom navigation, separate goal forms, Back, calculators, risk access, reset validation and missing-NAV portfolio values.
- Responsive tests cover 320, 390, 640, 768, 1024, 1050, 1100, 1280 and 1920px, including 200% text. A populated 320px/200% test exposed overflowing financial rows; holdings, activity and receipts now stack their information and pass with large figures.
- Browser checks at 390px exercised bottom tabs, Plans → Create goal → Back, scheme-prefilled SIP/contribution actions, the Corporate Bond filter and More → Risk comfort. Page widths matched 320px and 1280px viewports. Desktop retains its editorial hero.
- The updated Android API 35 integration test passed: fund search, bottom tabs, separate goal editor, validation, Back, calculators and learning.

Current screenshots: [Home](../screenshots/mobile-v1.1-home.png), [Funds](../screenshots/mobile-v1.1-funds.png), [Fund details](../screenshots/mobile-v1.1-fund-detail.png), [Plans](../screenshots/mobile-v1.1-plans.png), [New goal](../screenshots/mobile-v1.1-newgoal.png), [More](../screenshots/mobile-v1.1-more.png), and [desktop](../screenshots/mobile-v1.1-home-desktop-1280.png). These show guest/empty states and real published NAV, without fabricated holdings.
