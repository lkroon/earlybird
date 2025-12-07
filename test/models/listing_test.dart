import 'package:flutter_test/flutter_test.dart';
import 'package:earlybird/models/listing.dart';

void main() {
  group('Listing Model Tests', () {
    test('creates Listing with all properties', () {
      final listing = Listing(
        title: 'Test House',
        content: 'A beautiful house in Soest',
        url: 'https://www.funda.nl/detail/123',
        imageUrls: ['https://example.com/image.jpg'],
      );

      expect(listing.title, 'Test House');
      expect(listing.content, 'A beautiful house in Soest');
      expect(listing.url, 'https://www.funda.nl/detail/123');
      expect(listing.imageUrls, ['https://example.com/image.jpg']);
      expect(listing.imageUrl, 'https://example.com/image.jpg');
    });

    test('creates Listing from map with image key', () {
      final map = {
        'title': 'Test House',
        'content': 'A beautiful house',
        'url': 'https://www.funda.nl/detail/123',
        'image': 'https://example.com/image.jpg',
      };

      final listing = Listing.fromMap(map);

      expect(listing.title, 'Test House');
      expect(listing.content, 'A beautiful house');
      expect(listing.url, 'https://www.funda.nl/detail/123');
      expect(listing.imageUrl, 'https://example.com/image.jpg');
    });

    test('creates Listing from map with imageUrls key', () {
      final map = {
        'title': 'Test House',
        'content': 'A beautiful house',
        'url': 'https://www.funda.nl/detail/123',
        'imageUrls': [
          'https://example.com/image1.jpg',
          'https://example.com/image2.jpg'
        ],
      };

      final listing = Listing.fromMap(map);

      expect(listing.title, 'Test House');
      expect(listing.imageUrls.length, 2);
      expect(listing.imageUrl, 'https://example.com/image1.jpg');
    });

    test('creates Listing from map with missing values', () {
      final map = <String, dynamic>{};

      final listing = Listing.fromMap(map);

      expect(listing.title, '');
      expect(listing.content, '');
      expect(listing.url, '');
      expect(listing.imageUrls, isEmpty);
    });

    test('converts Listing to map', () {
      final listing = Listing(
        title: 'Test House',
        content: 'A beautiful house',
        url: 'https://www.funda.nl/detail/123',
        imageUrls: ['https://example.com/image.jpg'],
      );

      final map = listing.toMap();

      expect(map['title'], 'Test House');
      expect(map['content'], 'A beautiful house');
      expect(map['url'], 'https://www.funda.nl/detail/123');
      expect(map['imageUrls'], ['https://example.com/image.jpg']);
    });

    test('hasImage returns true when imageUrls is not empty', () {
      final listing = Listing(
        title: 'Test',
        content: 'Test',
        url: 'https://test.com',
        imageUrls: ['https://example.com/image.jpg'],
      );

      expect(listing.hasImage, true);
    });

    test('hasImage returns false when imageUrls is empty', () {
      final listing = Listing(
        title: 'Test',
        content: 'Test',
        url: 'https://test.com',
        imageUrls: [],
      );

      expect(listing.hasImage, false);
    });

    test('id returns url', () {
      final listing = Listing(
        title: 'Test',
        content: 'Test',
        url: 'https://test.com/123',
        imageUrls: [],
      );

      expect(listing.id, 'https://test.com/123');
    });

    test('isNew returns true for listings less than 24 hours old', () {
      final listing = Listing(
        title: 'Test',
        content: 'Test',
        url: 'https://test.com',
        imageUrls: [],
        firstSeenAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(listing.isNew, true);
    });

    test('markAsViewed sets isViewed to true', () {
      final listing = Listing(
        title: 'Test',
        content: 'Test',
        url: 'https://test.com',
        imageUrls: [],
      );

      expect(listing.isViewed, false);
      listing.markAsViewed();
      expect(listing.isViewed, true);
      expect(listing.lastSeenAt, isNotNull);
    });

    test('toggleViewed switches the viewed status', () {
      final listing = Listing(
        title: 'Test',
        content: 'Test',
        url: 'https://test.com',
        imageUrls: [],
      );

      expect(listing.isViewed, false);
      listing.toggleViewed();
      expect(listing.isViewed, true);
      listing.toggleViewed();
      expect(listing.isViewed, false);
    });
  });
}
