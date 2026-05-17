# Module Guide

Quick reference for each module's interface and dependencies.

## Models

### Listing (`lib/models/listing.dart`)
Hive-persisted real estate listing. Keyed by URL (`id` = `url`). Tracks viewed status and timestamps. `fromMap()` creates from scraper output, `toMap()` serializes back.
- **Depends on:** Hive
- **Used by:** ListingsProvider, ListingStorageService, ImageLoaderService, UI widgets

### SearchFilter (`lib/models/search_filter.dart`)
Immutable filter parameters (area, object type, publication date, sort order). Defaults to Soest/house/30 days/newest first.
- `toQueryParams()` — URL query parameters for Funda API
- `toQueryString()` — cache key for ListingStorageService
- **Used by:** ListingsProvider, UrlBuilder, FundaScraperService, FilterDialog

### Site (`lib/models/site.dart`)
Enum for supported sites. Currently only `funda`. Extensible for future scrapers.
- **Used by:** ListingsProvider, SiteSelector, HomeScreen

## Services

### ScraperService (`lib/services/scraper_service.dart`)
Abstract interface. Two methods: `fetchListingHeadings(filter)` returns `List<Map<String, String>>`, `fetchListingImage(detailUrl)` returns image URL string. Properties: `serviceName`, `baseUrl`, `botProtectionBodyIndicators`, `botProtectionPageTitle`.
- **Implemented by:** FundaScraperService

### FundaScraperService (`lib/services/funda_scraper_service.dart`)
HTTP-based Funda.nl scraper. Fetches via CORS proxy (web) or direct (mobile). Parses HTML headings for `/detail/` links. Throws `CaptchaException` when bot protection detected.
- **Depends on:** http, html_parser, CaptchaSessionService, UrlBuilder, AppConstants
- **Used by:** ListingsProvider (via ScraperService interface)

### ImageLoaderService (`lib/services/image_loader_service.dart`)
Batches image loading. Takes headings list + index range, fetches detail pages to extract image URLs, returns `List<Listing>`.
- **Depends on:** ScraperService, AppConstants
- **Used by:** ListingsProvider

### ListingStorageService (`lib/services/listing_storage_service.dart`)
Hive-based persistence. Stores listings keyed by URL. 30-day retention with auto-cleanup. `mergeWithCache()` preserves viewed status across re-fetches.
- **Depends on:** Hive, Listing model
- **Used by:** ListingsProvider

### CaptchaSessionService (`lib/services/captcha_session_service.dart`)
In-memory cookie store. Sessions expire after 20 minutes. Provides cookie headers for authenticated HTTP requests after captcha is solved.
- **Used by:** FundaScraperService, main.dart (injection)

## Provider

### ListingsProvider (`lib/providers/listings_provider.dart`)
Central state manager. Orchestrates fetching (HTTP or WebView), pagination, caching, and error states. Exposes `needsCaptcha` flag that triggers WebView fallback in HomeScreen.
- **Key methods:** `fetchListings()`, `loadMore()`, `onWebViewDataExtracted()`, `onWebViewError()`, `onCaptchaSolved()`
- **Depends on:** ScraperService, ImageLoaderService, ListingStorageService, UrlBuilder
- **Used by:** HomeScreen (via Provider)

## Screens & Widgets

### HomeScreen (`lib/screens/home/home_screen.dart`)
Root UI. Conditionally renders `ListingWebView` (when captcha needed) or listing cards. Handles pull-to-refresh, infinite scroll, filter dialog, site selection.

### ListingWebView (`lib/screens/home/widgets/listing_webview.dart`)
WebView-based scraper. Loads search URL directly, detects captcha pages, polls DOM for listings, extracts data via JavaScript injection. Reports results via `onDataExtracted` / `onError` callbacks.
- **State machine:** loading -> captcha (if detected) -> polling -> done
- **Key JS constants:** `_extractionJs` (listing extraction), `_diagnosticJs` (page diagnostics)

### FilterDialog (`lib/screens/home/widgets/filter_dialog.dart`)
Modal for updating SearchFilter parameters.

### ListingCard (`lib/screens/home/widgets/listing_card.dart`)
Card widget displaying a single listing with image, title, content, and viewed indicator.

### SiteSelector (`lib/screens/home/widgets/site_selector.dart`)
Dropdown for switching between scraper sites.

## Utilities

### UrlBuilder (`lib/core/utils/url_builder.dart`)
Static helper. `buildFundaUrl(filter)` constructs search URL. `withCorsProxy(url)` wraps URL for web builds.

### AppConstants (`lib/core/constants/app_constants.dart`)
CORS proxy URL, platform-specific HTTP headers, Funda base URL, batch sizes, thresholds.

### AppTheme (`lib/core/theme/app_theme.dart`)
Material theme configuration.

### CaptchaException (`lib/core/exceptions/captcha_exception.dart`)
Thrown when bot protection is detected. Triggers WebView fallback in ListingsProvider.
