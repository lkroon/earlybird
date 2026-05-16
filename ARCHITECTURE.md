# EarlyBird - Project Structure

## Overview
The app has been refactored into a modular, scalable architecture following Flutter best practices.

## Directory Structure

```
lib/
├── main.dart                                    # App entry point with Provider setup
├── core/                                        # Shared utilities and configuration
│   ├── constants/
│   │   └── app_constants.dart                   # URLs, headers, pagination settings
│   ├── theme/
│   │   └── app_theme.dart                       # Theme and color definitions
│   └── utils/
│       └── url_builder.dart                     # URL building with filters
├── models/                                      # Data models
│   ├── listing.dart                             # Listing data class
│   └── search_filter.dart                       # Filter parameters
├── services/                                    # Business logic layer
│   ├── scraper_service.dart                     # Abstract scraper interface
│   ├── funda_scraper_service.dart              # Funda implementation
│   └── image_loader_service.dart               # Lazy image loading
├── providers/                                   # State management
│   └── listings_provider.dart                   # Listings state (using Provider pattern)
└── screens/                                     # UI screens
    └── home/
        ├── home_screen.dart                     # Main home screen
        └── widgets/
            └── listing_card.dart                # Reusable listing card widget
```

## Key Components

### Models
- **Listing**: Represents a real estate listing with title, content, URL, and image
- **SearchFilter**: Encapsulates search parameters (area, object type, date, sort order)

### Services (Business Logic)
- **ScraperService**: Abstract interface for any real estate site scraper
- **FundaScraperService**: Funda-specific implementation
- **ImageLoaderService**: Handles incremental image loading for performance

### Provider (State Management)
- **ListingsProvider**: Manages listings state, loading states, pagination
  - `fetchListings()`: Fetches new listings based on filter
  - `loadMore()`: Loads next batch of listings
  - `updateFilter()`: Updates search filter and refetches
  - `refresh()`: Refreshes the current listings

### UI Components
- **HomeScreen**: Main screen with scroll handling and provider integration
- **ListingCard**: Reusable card widget for displaying a single listing

### Core Utilities
- **AppConstants**: Centralized constants (URLs, batch sizes, thresholds)
- **AppTheme**: Theme configuration
- **UrlBuilder**: Builds URLs from SearchFilter models

## How to Extend

### Adding Filters
1. Update `SearchFilter` model with new properties
2. Update `UrlBuilder.buildFundaUrl()` to include new parameters
3. Create filter UI widgets in `screens/home/widgets/filter_bar.dart`
4. Call `provider.updateFilter(newFilter)` when filters change

### Adding New Real Estate Sites (e.g., Jaap.nl)
1. Create `lib/services/jaap_scraper_service.dart`
2. Implement the `ScraperService` interface
3. Update UI to allow site selection
4. Pass appropriate scraper to `ListingsProvider` in `main.dart`

Example:
```dart
// In main.dart
ChangeNotifierProvider(
  create: (_) => ListingsProvider(
    scraperService: selectedSite == 'funda' 
      ? FundaScraperService() 
      : JaapScraperService(),
  ),
  // ...
)
```

## Benefits of This Architecture

1. **Separation of Concerns**: UI, business logic, and data are clearly separated
2. **Testability**: Each component can be tested independently
3. **Scalability**: Easy to add new features without touching existing code
4. **Maintainability**: Changes are isolated to specific modules
5. **Reusability**: Components like ListingCard can be reused across screens
6. **Type Safety**: Models provide compile-time safety with proper data structures

## State Management
The app uses the Provider pattern for state management:
- Simple to understand and implement
- Built-in to Flutter ecosystem
- Suitable for apps of this complexity
- Can be upgraded to Riverpod or Bloc later if needed

## Next Steps

1. **Add Filter UI**: Create `filter_bar.dart` widget for dynamic filtering
2. **Multi-site Support**: Implement scrapers for other real estate sites
3. **Persistence**: Add local storage for filters and favorites
4. **Testing**: Add unit tests for services and widget tests for UI
5. **Error Handling**: Improve error states and user feedback
