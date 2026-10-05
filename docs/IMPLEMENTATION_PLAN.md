# Mutual Management delivery plan

Historical delivery plan for the initial build. The current release, user guide and mobile revision are documented in [README](../README.md) and [the mobile UX audit](MOBILE_UX_AUDIT.md).

Source: user-provided approved Flutter Web and Android plan, 5 October 2026. DESIGN.md is the visual authority. Detailed code contracts: INTERFACES.md.

1. Foundation: Flutter 3.47.1 Android API24+/web, Riverpod, repository layer, local fonts/theme/router, CI.
2. Three concurrent workers: A Firebase/auth/user records/rules; B real fund reference/API data/calculations; C responsive overview/fund/detail/compare/risk screens. Root implements remaining screens, integrates and releases.
3. Integration: goals, monthly/quarterly simulated SIP installments with historical NAV, immutable contributions, derived portfolio, overlap/sector, learning calculators/deposits, pending-form auth return.
4. Verification: analyze/unit/widget/emulator/browser, money example 65 units/1560 value/60 gain; month-end/leap dates; cache errors; two clients and owner isolation; widths 320/390/640/768/1024/1280/1920/200% text; Android portrait/landscape.
5. Release: public kadamsahil2511/mutual-management with green CI; Firebase device-streaming-f3ea5c85 display Mutual Management, preserve resources/billing; Vercel mutual-management ksahil-team via static prebuilt output; release signed APK; screenshots and demo/syllabus guide. User has authorized these destinations and publication.
