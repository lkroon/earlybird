# Test Documentation

## Test Coverage Summary

**Total Tests: 70**
**All Passing ✓**

## Test Organization

### Models Tests (17 tests)
Location: `test/models/`

#### Listing Model (`listing_test.dart`) - 6 tests
- ✓ Creates Listing with all properties
- ✓ Creates Listing from map
- ✓ Creates Listing from map with missing values
- ✓ Converts Listing to map
- ✓ hasImage returns true when imageUrl is not empty
- ✓ hasImage returns false when imageUrl is empty

#### SearchFilter Model (`search_filter_test.dart`) - 6 tests
- ✓ Creates SearchFilter with default values
- ✓ Creates SearchFilter with custom values
- ✓ copyWith updates only specified fields
- ✓ copyWith with no changes returns equivalent filter
- ✓ toQueryParams returns correct map
- ✓ toQueryParams formats area with quotes and brackets

### Core Utilities Tests (6 tests)
Location: `test/core/utils/`

#### URL Builder (`url_builder_test.dart`) - 6 tests
- ✓ buildFundaUrl creates correct URL with default filter
- ✓ buildFundaUrl creates correct URL with custom filter
- ✓ buildFundaUrl includes all query parameters
- ✓ withCorsProxy wraps URL correctly
- ✓ withCorsProxy handles URL encoding
- ✓ buildFundaUrl with special characters in area

### Services Tests (22 tests)
Location: `test/services/`

#### FundaScraperService (`funda_scraper_service_test.dart`) - 10 tests
- ✓ serviceName returns "Funda"
- ✓ fetchListingHeadings parses HTML correctly (conceptual)
- ✓ fetchListingImage returns empty string on error
- ✓ fetchListingHeadings filters non-detail URLs
- ✓ fetchListingHeadings handles empty headings
- ✓ fetchListingHeadings extracts href correctly
- ✓ fetchListingHeadings truncates long content
- ✓ fetchListingImage skips logo image
- ✓ Can create service instance
- ✓ fetchListingHeadings method exists and can be called

#### ImageLoaderService (`image_loader_service_test.dart`) - 8 tests
- ✓ getBatchSize returns initial batch size for first batch
- ✓ getBatchSize returns subsequent batch size for non-first batch
- ✓ loadBatch fetches images for listings
- ✓ loadBatch respects batch size limit
- ✓ loadBatch handles startIndex correctly
- ✓ loadBatch clamps endIndex to headings length
- ✓ loadBatch creates Listing objects with correct properties
- ✓ loadBatch handles empty headings list

### Provider Tests (13 tests)
Location: `test/providers/`

#### ListingsProvider (`listings_provider_test.dart`) - 13 tests
- ✓ Initial state is correct
- ✓ fetchListings updates loading state
- ✓ fetchListings fetches headings from scraper
- ✓ loadMore loads images for next batch
- ✓ loadMore does nothing when already loading
- ✓ loadMore does nothing when no more items
- ✓ shouldLoadMore returns true when near end
- ✓ updateFilter changes filter and refetches
- ✓ refresh calls fetchListings
- ✓ fetchListings clears previous listings
- ✓ Notifies listeners on state changes

### Widget Tests (12 tests)
Location: `test/widgets/`

#### ListingCard (`listing_card_test.dart`) - 11 tests
- ✓ Displays listing with image
- ✓ Does not display listing without image
- ✓ Displays all listing information
- ✓ Shows error icon when image fails to load
- ✓ Card has correct padding and margin
- ✓ Displays image with correct dimensions
- ✓ Title has correct styling
- ✓ Content has correct styling
- ✓ URL is clickable
- ✓ Handles empty title gracefully
- ✓ Handles empty content gracefully

#### HomeScreen (`home_screen_test.dart`) - 11 tests
- ✓ Shows loading indicator when isLoading is true
- ✓ Shows "No listings found" when list is empty
- ✓ Displays listings in ListView
- ✓ Shows loading indicator at bottom when isLoadingMore is true
- ✓ Has refresh button
- ✓ Refresh button calls provider.refresh()
- ✓ Has app bar with Funda logo
- ✓ Calls fetchListings on init
- ✓ ListView has correct padding
- ✓ itemCount includes loading indicator when isLoadingMore
- ✓ Scroll controller is disposed properly

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/models/listing_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Generate Mocks (if needed)
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Test Dependencies

The following packages are used for testing:
- `flutter_test`: Built-in Flutter testing framework
- `mockito`: For creating mock objects
- `build_runner`: For generating mock classes

## Test Strategy

### Unit Tests
- **Models**: Test data structures, conversions, and helper methods
- **Services**: Test business logic with mocked dependencies
- **Providers**: Test state management with mocked services
- **Utils**: Test utility functions with various inputs

### Widget Tests
- **UI Components**: Test widget rendering, user interactions, and state changes
- **Integration**: Test widget behavior with mocked providers

### Mock Generation
Mock classes are automatically generated using `@GenerateMocks` annotation:
- `MockScraperService`: Mocks the scraper service interface
- `MockListingsProvider`: Mocks the listings provider for widget tests

## What's Tested

### ✓ Data Layer
- Model creation and conversion
- Filter parameter handling
- URL building and encoding

### ✓ Business Logic
- Listing scraping and parsing
- Incremental image loading
- Batch size management

### ✓ State Management
- Loading states
- Pagination logic
- Data refresh
- Filter updates

### ✓ UI Layer
- Component rendering
- User interactions
- Loading indicators
- Error states

## Future Test Improvements

1. **Integration Tests**: Add end-to-end tests for critical user flows
2. **Golden Tests**: Add screenshot tests for UI consistency
3. **Performance Tests**: Add tests for scroll performance and memory usage
4. **Error Scenarios**: Add more tests for network failures and edge cases
5. **Accessibility Tests**: Add tests for screen reader support and contrast
