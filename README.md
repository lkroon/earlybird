# EarlyBird

A Flutter app that scrapes real estate listings from Funda.nl. Browse listings, filter by area, and open details directly on Funda.

## Current State

This is an experimental/prototype project. The app scrapes Funda search results via a public CORS proxy (`corsproxy.io`), parses HTML for listing headings, then lazily fetches images from detail pages. It works but is fragile — the scraping depends on Funda's current HTML structure and the CORS proxy staying available.

**What works:**
- Scraping Funda listings (headings + images)
- Filtering by area (other filter fields exist but are disabled in the UI)
- Infinite scroll with batched image loading
- Opening listing URLs in external browser
- 70+ unit and widget tests

**Known issues:**
- CORS proxy (`corsproxy.io`) is a public third-party service and can be unreliable
- HTML scraping is brittle (depends on Funda's markup structure)
- Images are fetched sequentially (slow)
- Listings without images are silently hidden
- Theme colors don't match Funda branding despite using their logo
- `dart:io` import in constants breaks web builds

## Architecture

```
lib/
├── main.dart                    # App entry point with Provider setup
├── core/
│   ├── constants/               # URLs, headers, pagination config
│   ├── theme/                   # Theme configuration
│   └── utils/                   # URL builder utility
├── models/                      # Listing, SearchFilter
├── services/                    # ScraperService (abstract), FundaScraperService, ImageLoaderService
├── providers/                   # ListingsProvider (ChangeNotifier)
└── screens/home/                # HomeScreen, ListingCard, FilterDialog
```

State management uses Provider. The `ScraperService` interface allows adding new sources (e.g., Jaap.nl) by implementing the abstract class.

## Getting Started

### Prerequisites

- Flutter SDK >=3.10.0 (Dart >=3.0.0)
- For WSL2: install Flutter natively in Linux (`snap install flutter --classic` or manual install) — the Windows-side SDK won't work from WSL2
- Chrome (for web target, easiest on WSL2)

### Run

```bash
flutter pub get
flutter run -d chrome
```

### VS Code

The project includes `.vscode/launch.json` with configurations for Chrome, Android, and Linux Desktop. Select a launch configuration from the Run and Debug panel.

### Tests

```bash
flutter test
flutter test --coverage

# Regenerate mocks after changing service interfaces
dart run build_runner build --delete-conflicting-outputs
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `http` | HTTP client for scraping |
| `html` | HTML parsing |
| `url_launcher` | Open listings in browser |
| `flutter_svg` | Funda logo rendering |
| `mockito` + `build_runner` | Test mocking (dev) |

## License

MIT — see [LICENSE](LICENSE).
