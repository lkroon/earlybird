# EarlyBird

Flutter app that scrapes Funda.nl real estate listings using a hybrid HTTP + WebView approach. Handles bot protection by loading pages in a WebView, extracting listing data via JavaScript DOM parsing, and caching results locally with Hive.

## Architecture

```
main.dart ── providers/listings_provider.dart ── services/*
                    │                                │
                    │                          ScraperService (abstract)
                    │                          FundaScraperService (HTTP scraping)
                    │                          ImageLoaderService (batch image fetch)
                    │                          ListingStorageService (Hive cache)
                    │                          CaptchaSessionService (cookie mgmt)
                    │
             screens/home/home_screen.dart
                    │
              widgets/listing_webview.dart (WebView DOM scraping)
              widgets/listing_card.dart
              widgets/filter_dialog.dart
              widgets/site_selector.dart
```

**Data flow:** SearchFilter -> UrlBuilder -> FundaScraperService (HTTP) or ListingWebView (WebView) -> ListingsProvider -> UI

**Two scraping paths:**
1. **HTTP path:** FundaScraperService fetches via CORS proxy, parses HTML with `html` package. Used when no bot protection is detected.
2. **WebView path:** ListingWebView loads the search URL directly, polls DOM for `/detail/` links, extracts data via injected JavaScript. Triggered when CaptchaException is thrown.

**State management:** Provider (ChangeNotifier). Single provider `ListingsProvider` orchestrates all services.

**Storage:** Hive with `ListingAdapter` (auto-generated). Listings keyed by URL, retained for 30 days, merged on re-fetch to preserve viewed status.

## Setup and Testing

```bash
flutter pub get
flutter test                    # run all tests
flutter analyze --fatal-infos   # static analysis (CI enforces this)
dart format --set-exit-if-changed .  # format check
```

## Code Generation

Generated files (do NOT hand-edit):
- `lib/models/listing.g.dart` — Hive TypeAdapter for Listing
- `test/**/*.mocks.dart` — Mockito mocks from `@GenerateMocks` annotations

Regenerate after changing Listing fields or mock annotations:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Key Gotchas

- **HTML scraping is fragile.** Funda.nl can change its DOM structure at any time. The HTTP scraper looks for headings with `/detail/` hrefs. The WebView scraper uses `a[href*="/detail/"]` and `img[src*="funda"]` selectors. Both break if Funda changes URL patterns.
- **CORS proxy dependency.** Web builds route requests through `corsproxy.io`. If the proxy is down, HTTP scraping fails on web. Mobile builds bypass the proxy.
- **Bot protection triggers CaptchaException.** When detected, the provider sets `needsCaptcha = true`, which swaps the UI to `ListingWebView`. The WebView handles captcha solving and data extraction in one flow.
- **WebView lifecycle.** `ListingWebView` uses async polling with `Timer.periodic`. All `await` calls are followed by `if (!mounted) return;` guards to prevent use-after-dispose. Debug output is gated behind `kDebugMode`.
- **Hive box corruption.** `ListingStorageService.init()` catches errors and recreates the box from scratch if it can't open. This means cached data can be lost silently.

## Common Agent Tasks

**Add a new scraper for another site:**
1. Create a new class implementing `ScraperService` in `lib/services/`
2. Add the site to `lib/models/site.dart` enum
3. Wire it up in `main.dart` (conditional on selected site)
4. Add tests mirroring `test/services/funda_scraper_service_test.dart`

**Update selectors when Funda changes its HTML:**
1. Check `lib/services/funda_scraper_service.dart` for HTTP-path selectors (headings, href regex, image attributes)
2. Check `lib/screens/home/widgets/listing_webview.dart` for WebView-path JavaScript selectors (`_extractionJs` and `_diagnosticJs` constants)
3. Update both paths to match new DOM structure
4. Run `flutter test` to verify existing tests still pass

**Add a new filter option:**
1. Add field to `lib/models/search_filter.dart`
2. Update `toQueryParams()` and `toQueryString()`
3. Add UI control in `lib/screens/home/widgets/filter_dialog.dart`
4. Add test cases in `test/models/search_filter_test.dart`

**Fix a failing test:**
1. Check if it's a mock issue — regenerate with `dart run build_runner build --delete-conflicting-outputs`
2. Check if Listing fields changed — may need to update `listing.g.dart` (regenerate, don't hand-edit)
3. Run the specific test: `flutter test test/path/to/test.dart`
