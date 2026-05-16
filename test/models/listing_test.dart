import 'package:flutter_test/flutter_test.dart';
import 'package:earlybird/models/listing.dart';

void main() {
  group('Listing Model Tests', () {
    test('creates Listing with all properties', () {
      final listing = Listing(
        title: 'Test House',
        content: 'A beautiful house in Soest',
        url: 'https://www.funda.nl/detail/123',
        imageUrl: 'https://example.com/image.jpg',
      );

      expect(listing.title, 'Test House');
      expect(listing.content, 'A beautiful house in Soest');
      expect(listing.url, 'https://www.funda.nl/detail/123');
      expect(listing.imageUrl, 'https://example.com/image.jpg');
    });

    test('creates Listing from map', () {
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

    test('creates Listing from map with missing values', () {
      final map = <String, String>{};

      final listing = Listing.fromMap(map);

      expect(listing.title, '');
      expect(listing.content, '');
      expect(listing.url, '');
      expect(listing.imageUrl, '');
    });

    test('converts Listing to map', () {
      final listing = Listing(
        title: 'Test House',
        content: 'A beautiful house',
        url: 'https://www.funda.nl/detail/123',
        imageUrl: 'https://example.com/image.jpg',
      );

      final map = listing.toMap();

      expect(map['title'], 'Test House');
      expect(map['content'], 'A beautiful house');
      expect(map['url'], 'https://www.funda.nl/detail/123');
      expect(map['image'], 'https://example.com/image.jpg');
    });

    test('hasImage returns true when imageUrl is not empty', () {
      final listing = Listing(
        title: 'Test',
        content: 'Test',
        url: 'https://test.com',
        imageUrl: 'https://example.com/image.jpg',
      );

      expect(listing.hasImage, true);
    });

    test('hasImage returns false when imageUrl is empty', () {
      final listing = Listing(
        title: 'Test',
        content: 'Test',
        url: 'https://test.com',
        imageUrl: '',
      );

      expect(listing.hasImage, false);
    });
  });
}
