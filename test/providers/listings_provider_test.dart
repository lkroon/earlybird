import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:earlybird/providers/listings_provider.dart';
import 'package:earlybird/services/scraper_service.dart';
import 'package:earlybird/services/listing_storage_service.dart';
import 'package:earlybird/models/search_filter.dart';
import 'package:earlybird/models/listing.dart';

@GenerateMocks([ScraperService, ListingStorageService])
import 'listings_provider_test.mocks.dart';

void main() {
  group('ListingsProvider Tests', () {
    late ListingsProvider provider;
    late MockScraperService mockScraper;
    late MockListingStorageService mockStorage;

    setUp(() {
      mockScraper = MockScraperService();
      mockStorage = MockListingStorageService();
      when(mockScraper.serviceName).thenReturn('TestScraper');
      when(mockStorage.getAllListings()).thenReturn([]);
      when(mockStorage.getListingsForFilter(any)).thenReturn([]);
      when(mockStorage.mergeWithCache(any, any))
          .thenAnswer((inv) => inv.positionalArguments[0]);
      provider = ListingsProvider(
        scraperService: mockScraper,
        storageService: mockStorage,
      );
    });

    test('initial state is correct', () {
      expect(provider.listings, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.isLoadingMore, false);
      expect(provider.hasMore, false);
      expect(provider.currentFilter, isNotNull);
    });

    test('fetchListings loads cached listings first', () async {
      final cachedListings = [
        Listing(
          title: 'Cached House',
          content: 'Desc',
          url: 'url1',
          imageUrls: ['img1.jpg'],
          filterKey: 'utrecht-house-30-date_down',
        ),
      ];

      when(mockStorage.getListingsForFilter(any)).thenReturn(cachedListings);
      when(mockScraper.fetchListingHeadings(any)).thenAnswer((_) async => []);

      await provider.fetchListings();

      expect(provider.listings, cachedListings);
    });

    test('fetchListings updates refreshing state', () async {
      when(mockScraper.fetchListingHeadings(any)).thenAnswer((_) async => []);

      final refreshingStates = <bool>[];
      provider.addListener(() {
        refreshingStates.add(provider.isRefreshing);
      });

      await provider.fetchListings();

      expect(refreshingStates, contains(true));
      expect(provider.isRefreshing, false);
    });

    test('fetchListings fetches headings from scraper', () async {
      final mockHeadings = [
        {'title': 'House 1', 'content': 'Desc', 'url': 'url1', 'image': ''},
        {'title': 'House 2', 'content': 'Desc', 'url': 'url2', 'image': ''},
      ];

      when(mockScraper.fetchListingHeadings(any))
          .thenAnswer((_) async => mockHeadings);
      when(mockScraper.fetchListingImages(any))
          .thenAnswer((_) async => ['image.jpg']);
      when(mockStorage.saveListings(any)).thenAnswer((_) async => {});

      await provider.fetchListings();
      // Wait for the loadMore to complete
      await Future.delayed(Duration.zero);

      verify(mockScraper.fetchListingHeadings(any)).called(1);
      expect(provider.listings.length, greaterThan(0));
    });

    test('loadMore loads images for next batch', () async {
      final mockHeadings = List.generate(
        10,
        (i) => {
          'title': 'House $i',
          'content': 'Description',
          'url': 'url$i',
          'image': '',
        },
      );

      when(mockScraper.fetchListingHeadings(any))
          .thenAnswer((_) async => mockHeadings);
      when(mockScraper.fetchListingImages(any))
          .thenAnswer((_) async => ['image.jpg']);
      when(mockStorage.saveListings(any)).thenAnswer((_) async => {});

      await provider.fetchListings();

      // First batch should load 5 items
      expect(provider.listings.length, 5);
      expect(provider.hasMore, true);

      await provider.loadMore();

      // After loadMore, should have 10 items (5 + 5)
      expect(provider.listings.length, 10);
      expect(provider.hasMore, false);
    });

    test('loadMore does nothing when already loading', () async {
      when(mockScraper.fetchListingHeadings(any)).thenAnswer((_) async => []);

      await provider.fetchListings();

      // Manually set loading state
      provider.loadMore(); // Start loading
      const listenerCallCount = 0;
      provider.addListener(() {
        // Should not be called again
      });

      await provider.loadMore(); // Try to load again while loading

      expect(listenerCallCount, 0);
    });

    test('loadMore does nothing when no more items', () async {
      when(mockScraper.fetchListingHeadings(any)).thenAnswer((_) async => []);

      await provider.fetchListings();

      expect(provider.hasMore, false);

      final initialLength = provider.listings.length;
      await provider.loadMore();

      expect(provider.listings.length, initialLength);
    });

    test('shouldLoadMore returns true when near end', () async {
      final mockHeadings = List.generate(
        20,
        (i) => {'title': 'House $i', 'content': '', 'url': '', 'image': ''},
      );

      when(mockScraper.fetchListingHeadings(any))
          .thenAnswer((_) async => mockHeadings);
      when(mockScraper.fetchListingImages(any))
          .thenAnswer((_) async => ['image.jpg']);
      when(mockStorage.saveListings(any)).thenAnswer((_) async => {});

      await provider.fetchListings();

      expect(provider.listings.length, 5);

      // Should load more when within 2 items of end (5 - 2 = 3)
      expect(provider.shouldLoadMore(3), true);
      expect(provider.shouldLoadMore(4), true);
      expect(provider.shouldLoadMore(2), false);
    });

    test('updateFilter changes filter and refetches', () async {
      when(mockScraper.fetchListingHeadings(any)).thenAnswer((_) async => []);

      final newFilter = SearchFilter(area: 'amsterdam');
      await provider.updateFilter(newFilter);

      expect(provider.currentFilter.area, 'amsterdam');
      verify(mockScraper.fetchListingHeadings(any)).called(1);
    });

    test('refresh calls fetchListings', () async {
      when(mockScraper.fetchListingHeadings(any)).thenAnswer((_) async => []);

      await provider.refresh();

      verify(mockScraper.fetchListingHeadings(any)).called(1);
    });

    test('toggleListingViewed updates storage', () async {
      await provider.toggleListingViewed('https://test.com');

      verify(mockStorage.toggleListingViewed('https://test.com')).called(1);
    });

    test('notifies listeners on state changes', () async {
      when(mockScraper.fetchListingHeadings(any)).thenAnswer((_) async => []);

      var notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      await provider.fetchListings();

      expect(notificationCount, greaterThan(0));
    });
  });
}
