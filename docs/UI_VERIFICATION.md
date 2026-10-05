# UI verification

This page records the version 1.0 baseline. The version 1.1 phone redesign and its current screenshots are recorded in [the mobile UX audit](MOBILE_UX_AUDIT.md).

Browser review ran on 5 October 2026 against the Flutter web server at `http://127.0.0.1:8765/` in a separate `mutual-responsive` agent-browser session. The root browser session on port 8088 was not used.

## Overview widths

The overview was rendered at 320, 390, 640, 768, 1024, 1280, and 1920 CSS pixels wide, at 900 pixels high. At every width, `document.documentElement.scrollWidth` matched `window.innerWidth`; there was no page-level horizontal overflow. The 200% text-scale layout is covered by `test/responsive_test.dart`.

Screenshots reviewed:

- [Overview mobile, 390px](../screenshots/overview-mobile.png)
- [Overview narrow desktop, 1024px](../screenshots/overview-1024.png)
- [Overview desktop, 1280px](../screenshots/overview-desktop.png)
- Fund catalogue, 1280px: [funds-desktop.png](../screenshots/funds-desktop.png)
- Fund detail, 1280px: [fund-detail-desktop.png](../screenshots/fund-detail-desktop.png)

The overview cards show the empty portfolio state (₹0.00 with no contributions recorded) and the next-step card. No portfolio or NAV figures were fabricated for the screenshot.

At 1024px the next-step card is offset below the portfolio card's action row, leaving the “View portfolio” button unobscured; the desktop heading retains its 80px scale. The 320/390 mobile, 640/768 tablet, and 1280/1920 desktop screenshots show no visible clipping.

## Catalogue and detail navigation

The top navigation opened `/funds`; the first “Explore fund” action opened `/funds/118955`. The detail view displayed the current published NAV and valuation date, NAV-derived returns, and dated minimum-investment and holdings-factsheet source links. Browser back returned to `/funds`, then to `/`.

The fund catalogue screenshot shows the search field, category filters, NAV valuation date, and the updated “1-year NAV return” label. The detail screenshot shows 1-year absolute dated returns separately from 3-year and 5-year CAGR figures.

## Browser and widget checks

- No browser error overlay; page body had content.
- `agent-browser errors` returned no page errors. Console output contained Flutter startup logs and its viewport-meta replacement warning, with no errors.
- `flutter test test/responsive_test.dart` passed 3 tests after the 1024px stack adjustment. The combined `flutter test test/fund_ui_test.dart test/responsive_test.dart` passed 11 tests before that layout-only adjustment.
