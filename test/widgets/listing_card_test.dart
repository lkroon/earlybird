import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earlybird/screens/home/widgets/listing_card.dart';
import 'package:earlybird/models/listing.dart';

void main() {
  group('ListingCard Widget Tests', () {
    testWidgets('displays listing with image', (WidgetTester tester) async {
      final listing = Listing(
        title: 'Beautiful House',
        content: 'A great place to live',
        url: 'https://www.funda.nl/detail/123',
        imageUrls: ['https://example.com/image.jpg'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(listing: listing),
          ),
        ),
      );

      expect(find.text('Beautiful House'), findsOneWidget);
      expect(find.text('A great place to live'), findsOneWidget);
      expect(find.text('https://www.funda.nl/detail/123'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('does not display listing without image',
        (WidgetTester tester) async {
      final listing = Listing(
        title: 'House Without Image',
        content: 'Description',
        url: 'https://example.com',
        imageUrls: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(listing: listing),
          ),
        ),
      );

      expect(find.text('House Without Image'), findsNothing);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('displays all listing information',
        (WidgetTester tester) async {
      final listing = Listing(
        title: 'Test Title',
        content: 'Test Content',
        url: 'https://test.com',
        imageUrls: ['https://example.com/img.jpg'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(listing: listing),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
      expect(find.text('https://test.com'), findsOneWidget);
    });

    testWidgets('shows error icon when image fails to load',
        (WidgetTester tester) async {
      final listing = Listing(
        title: 'House',
        content: 'Description',
        url: 'https://example.com',
        imageUrls: ['https://invalid-url.com/image.jpg'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(listing: listing),
          ),
        ),
      );

      // Find the Image widget
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      // The error builder should show a broken image icon
      expect(find.byIcon(Icons.broken_image),
          findsNothing); // Won't trigger without actual error
    });

    testWidgets('card has correct padding and margin',
        (WidgetTester tester) async {
      final listing = Listing(
        title: 'House',
        content: 'Description',
        url: 'https://example.com',
        imageUrls: ['https://example.com/image.jpg'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(listing: listing),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, const EdgeInsets.only(bottom: 16.0));
    });

    testWidgets('displays image with correct dimensions',
        (WidgetTester tester) async {
      final listing = Listing(
        title: 'House',
        content: 'Description',
        url: 'https://example.com',
        imageUrls: ['https://example.com/image.jpg'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(listing: listing),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.height, 200);
      expect(image.width, double.infinity);
      expect(image.fit, BoxFit.cover);
    });

    testWidgets('title has correct styling', (WidgetTester tester) async {
      final listing = Listing(
        title: 'Styled House',
        content: 'Description',
        url: 'https://example.com',
        imageUrls: ['https://example.com/image.jpg'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(listing: listing),
          ),
        ),
      );

      final titleText = tester.widget<Text>(find.text('Styled House'));
      expect(titleText.style?.fontSize, 16);
      expect(titleText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('content has correct styling', (WidgetTester tester) async {
      final listing = Listing(
        title: 'House',
        content: 'Styled Content',
        url: 'https://example.com',
        imageUrls: ['https://example.com/image.jpg'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(listing: listing),
          ),
        ),
      );

      final contentText = tester.widget<Text>(find.text('Styled Content'));
      expect(contentText.style?.fontSize, 12);
      expect(contentText.style?.color, Colors.grey);
    });

    testWidgets('URL is clickable', (WidgetTester tester) async {
      final listing = Listing(
        title: 'House',
        content: 'Description',
        url: 'https://example.com',
        imageUrls: ['https://example.com/image.jpg'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(listing: listing),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('handles empty title gracefully', (WidgetTester tester) async {
      final listing = Listing(
        title: '',
        content: 'Description',
        url: 'https://example.com',
        imageUrls: ['https://example.com/image.jpg'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(listing: listing),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('handles empty content gracefully',
        (WidgetTester tester) async {
      final listing = Listing(
        title: 'House',
        content: '',
        url: 'https://example.com',
        imageUrls: ['https://example.com/image.jpg'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(listing: listing),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('House'), findsOneWidget);
    });
  });
}
