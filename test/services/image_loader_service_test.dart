import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:earlybird/services/image_loader_service.dart';
import 'package:earlybird/services/scraper_service.dart';
import 'package:earlybird/core/constants/app_constants.dart';

@GenerateMocks([ScraperService])
import 'image_loader_service_test.mocks.dart';

void main() {
  group('ImageLoaderService Tests', () {
    late ImageLoaderService service;
    late MockScraperService mockScraper;

    setUp(() {
      mockScraper = MockScraperService();
      service = ImageLoaderService(mockScraper);
    });

    test('getBatchSize returns initial batch size for first batch', () {
      final size = service.getBatchSize(true);
      expect(size, AppConstants.initialBatchSize);
      expect(size, 5);
    });

    test('getBatchSize returns subsequent batch size for non-first batch', () {
      final size = service.getBatchSize(false);
      expect(size, AppConstants.subsequentBatchSize);
      expect(size, 5);
    });

    test('loadBatch fetches images for listings', () async {
      final headings = [
        {
          'title': 'House 1',
          'content': 'Description 1',
          'url': 'https://example.com/1',
          'image': '',
        },
        {
          'title': 'House 2',
          'content': 'Description 2',
          'url': 'https://example.com/2',
          'image': '',
        },
      ];

      when(mockScraper.fetchListingImages('https://example.com/1'))
          .thenAnswer((_) async => ['https://example.com/image1.jpg']);
      when(mockScraper.fetchListingImages('https://example.com/2'))
          .thenAnswer((_) async => ['https://example.com/image2.jpg']);

      final listings = await service.loadBatch(headings, 0, 2);

      expect(listings.length, 2);
      expect(listings[0].title, 'House 1');
      expect(listings[0].imageUrl, 'https://example.com/image1.jpg');
      expect(listings[1].title, 'House 2');
      expect(listings[1].imageUrl, 'https://example.com/image2.jpg');

      verify(mockScraper.fetchListingImages('https://example.com/1')).called(1);
      verify(mockScraper.fetchListingImages('https://example.com/2')).called(1);
    });

    test('loadBatch respects batch size limit', () async {
      final headings = List.generate(
        10,
        (i) => {
          'title': 'House $i',
          'content': 'Description',
          'url': 'https://example.com/$i',
          'image': '',
        },
      );

      when(mockScraper.fetchListingImages(any))
          .thenAnswer((_) async => ['https://example.com/image.jpg']);

      final listings = await service.loadBatch(headings, 0, 5);

      expect(listings.length, 5);
      verify(mockScraper.fetchListingImages(any)).called(5);
    });

    test('loadBatch handles startIndex correctly', () async {
      final headings = [
        {'title': 'House 1', 'content': '', 'url': 'url1', 'image': ''},
        {'title': 'House 2', 'content': '', 'url': 'url2', 'image': ''},
        {'title': 'House 3', 'content': '', 'url': 'url3', 'image': ''},
      ];

      when(mockScraper.fetchListingImages(any))
          .thenAnswer((_) async => ['image.jpg']);

      final listings = await service.loadBatch(headings, 1, 2);

      expect(listings.length, 2);
      expect(listings[0].title, 'House 2');
      expect(listings[1].title, 'House 3');
    });

    test('loadBatch clamps endIndex to headings length', () async {
      final headings = [
        {'title': 'House 1', 'content': '', 'url': 'url1', 'image': ''},
        {'title': 'House 2', 'content': '', 'url': 'url2', 'image': ''},
      ];

      when(mockScraper.fetchListingImages(any))
          .thenAnswer((_) async => ['image.jpg']);

      // Request batch size of 10 but only 2 items available
      final listings = await service.loadBatch(headings, 0, 10);

      expect(listings.length, 2);
    });

    test('loadBatch creates Listing objects with correct properties', () async {
      final headings = [
        {
          'title': 'Beautiful House',
          'content': 'Great location',
          'url': 'https://example.com/house',
          'image': '',
        },
      ];

      when(mockScraper.fetchListingImages('https://example.com/house'))
          .thenAnswer((_) async => ['https://example.com/house.jpg']);

      final listings = await service.loadBatch(headings, 0, 1);

      expect(listings.length, 1);
      expect(listings[0].title, 'Beautiful House');
      expect(listings[0].content, 'Great location');
      expect(listings[0].url, 'https://example.com/house');
      expect(listings[0].imageUrl, 'https://example.com/house.jpg');
    });

    test('loadBatch handles empty headings list', () async {
      final headings = <Map<String, String>>[];
      final listings = await service.loadBatch(headings, 0, 10);

      expect(listings, isEmpty);
      verifyNever(mockScraper.fetchListingImages(any));
    });
  });
}
