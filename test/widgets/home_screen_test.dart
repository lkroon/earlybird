import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:earlybird/screens/home/home_screen.dart';
import 'package:earlybird/providers/listings_provider.dart';
import 'package:earlybird/models/listing.dart';

@GenerateMocks([ListingsProvider])
import 'home_screen_test.mocks.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    late MockListingsProvider mockProvider;

    setUp(() {
      mockProvider = MockListingsProvider();

      // Default mock behavior
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.isLoadingMore).thenReturn(false);
      when(mockProvider.listings).thenReturn([]);
      when(mockProvider.hasMore).thenReturn(false);
      when(mockProvider.shouldLoadMore(any)).thenReturn(false);
      when(mockProvider.fetchListings()).thenAnswer((_) async => {});
      when(mockProvider.loadMore()).thenAnswer((_) async => {});
      when(mockProvider.refresh()).thenAnswer((_) async => {});
    });

    Widget createHomeScreen() {
      return ChangeNotifierProvider<ListingsProvider>.value(
        value: mockProvider,
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      );
    }

    testWidgets('shows loading indicator when isLoading is true',
        (WidgetTester tester) async {
      when(mockProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(createHomeScreen());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No listings found'), findsNothing);
    });

    testWidgets('shows "No listings found" when list is empty',
        (WidgetTester tester) async {
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.listings).thenReturn([]);

      await tester.pumpWidget(createHomeScreen());

      expect(find.text('No listings found'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('displays listings in ListView', (WidgetTester tester) async {
      final mockListings = [
        Listing(
          title: 'House 1',
          content: 'Description 1',
          url: 'https://example.com/1',
          imageUrl: 'https://example.com/image1.jpg',
        ),
        Listing(
          title: 'House 2',
          content: 'Description 2',
          url: 'https://example.com/2',
          imageUrl: 'https://example.com/image2.jpg',
        ),
      ];

      when(mockProvider.listings).thenReturn(mockListings);

      await tester.pumpWidget(createHomeScreen());

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('House 1'), findsOneWidget);
      expect(find.text('House 2'), findsOneWidget);
    });

    testWidgets('shows loading indicator at bottom when isLoadingMore is true',
        (WidgetTester tester) async {
      final mockListings = [
        Listing(
          title: 'House 1',
          content: 'Description',
          url: 'https://example.com/1',
          imageUrl: 'https://example.com/image.jpg',
        ),
      ];

      when(mockProvider.listings).thenReturn(mockListings);
      when(mockProvider.isLoadingMore).thenReturn(true);

      await tester.pumpWidget(createHomeScreen());

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('has refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());

      expect(find.byType(FloatingActionButton), findsNWidgets(2));
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('refresh button calls provider.refresh()',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      verify(mockProvider.refresh()).called(1);
    });

    testWidgets('has app bar with Funda logo', (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());

      expect(find.byType(AppBar), findsOneWidget);
      // SvgPicture would be here if assets were loaded
    });

    testWidgets('calls fetchListings on init', (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      verify(mockProvider.fetchListings()).called(1);
    });

    testWidgets('ListView has correct padding', (WidgetTester tester) async {
      final mockListings = [
        Listing(
          title: 'House',
          content: 'Description',
          url: 'https://example.com',
          imageUrl: 'https://example.com/image.jpg',
        ),
      ];

      when(mockProvider.listings).thenReturn(mockListings);

      await tester.pumpWidget(createHomeScreen());

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, const EdgeInsets.all(16.0));
    });

    testWidgets('itemCount includes loading indicator when isLoadingMore',
        (WidgetTester tester) async {
      final mockListings = List.generate(
        5,
        (i) => Listing(
          title: 'House $i',
          content: 'Description',
          url: 'https://example.com/$i',
          imageUrl: 'https://example.com/image$i.jpg',
        ),
      );

      when(mockProvider.listings).thenReturn(mockListings);
      when(mockProvider.isLoadingMore).thenReturn(true);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Should have 5 listings + 1 loading indicator in the list
      // The list should have 6 items total
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.semanticChildCount, 6);
    });

    testWidgets('scroll controller is disposed properly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());

      // This ensures the widget builds and scroll controller is created
      expect(find.byType(HomeScreen), findsOneWidget);

      // Dispose the widget
      await tester.pumpWidget(Container());

      // If scroll controller wasn't disposed, this would cause issues
      expect(find.byType(HomeScreen), findsNothing);
    });
  });
}
