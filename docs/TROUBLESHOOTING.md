# Troubleshooting

## Scraping Returns Empty Results

**Symptom:** `fetchListingHeadings()` returns empty list or WebView extraction finds 0 listings.

**Likely cause:** Funda.nl changed their HTML structure.

**Diagnosis:**
1. Check if `/detail/` still appears in listing URLs on funda.nl
2. For HTTP path: inspect `funda_scraper_service.dart` — headings are found via `h1, h2, h3, h4` selectors, then filtered for `/detail/` in href
3. For WebView path: inspect `_extractionJs` in `listing_webview.dart` — uses `a[href*="/detail/"]`

**Fix:** Update the selectors to match current DOM structure. Both paths must be updated independently.

## Bot Protection / CaptchaException

**Symptom:** App shows WebView captcha screen on every load, or HTTP requests consistently fail.

**Likely cause:** Funda.nl's Akamai bot protection is blocking requests.

**How it works:**
1. `FundaScraperService` checks page title for `bijna op de pagina` and body for `captcha` / `__akam_recaptcha`
2. If detected, throws `CaptchaException`
3. `ListingsProvider` sets `needsCaptcha = true`
4. `HomeScreen` renders `ListingWebView` instead of listing cards
5. WebView loads search URL directly, user solves captcha
6. Once page loads without captcha title, WebView polls and extracts data

**If captcha loop persists:** Check `botProtectionPageTitle` in `FundaScraperService` — Funda may have changed the Dutch text.

## CORS Proxy Failures (Web Only)

**Symptom:** HTTP scraping works on mobile but fails on web with network errors.

**Likely cause:** `corsproxy.io` is down or rate-limiting.

**Diagnosis:** Check `AppConstants.corsProxyUrl`. Try the proxy URL directly in a browser.

**Workaround:** Mobile builds bypass the proxy entirely (`UrlBuilder.withCorsProxy` is a no-op when `!kIsWeb`).

## Hive Storage Errors

**Symptom:** App crashes on startup or loses cached data.

**Likely cause:** Hive box corruption, usually from a schema change without migration.

**How it's handled:** `ListingStorageService.init()` catches errors and deletes/recreates the box. This means all cached data is lost.

**If adding a new Listing field:**
1. Add `@HiveField(N)` with the next available index (check `listing.dart` for current max)
2. Regenerate: `dart run build_runner build --delete-conflicting-outputs`
3. New field must be nullable or have a default — existing Hive entries won't have it

## Test Failures After Model Changes

**Symptom:** Tests fail with type errors or missing method stubs after changing model/service interfaces.

**Fix:** Regenerate mocks and adapters:
```bash
dart run build_runner build --delete-conflicting-outputs
```

This regenerates:
- `lib/models/listing.g.dart` (Hive adapter)
- All `test/**/*.mocks.dart` files (Mockito mocks)

## flutter analyze --fatal-infos Fails

**Symptom:** CI fails on `flutter analyze --fatal-infos` even though code compiles.

**Common causes:**
- Unused imports (especially after refactoring)
- Redundant imports (e.g., importing both `foundation.dart` and `material.dart` when only foundation symbols are used)
- Missing `const` constructors

**Fix:** Run `flutter analyze` locally, read the info-level messages, and fix them before pushing.

## WebView Not Extracting Data

**Symptom:** WebView loads the page but times out after 30 seconds with "No /detail/ links found."

**Diagnosis:** Check the diagnostic output (visible in debug mode) — it shows link counts, body size, and sample hrefs.

**Common causes:**
1. Page loaded but content is lazy-rendered (JS hasn't finished) — the 30-poll limit (1s each) should be sufficient for most cases
2. Funda changed their URL pattern — `/detail/` no longer appears in listing hrefs
3. WebView is blocked by bot protection but not showing the captcha page title

**Fix:** Adjust `_maxPollAttempts` or `_pollInterval` in `listing_webview.dart`, or update the `/detail/` selector pattern.
