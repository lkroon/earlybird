import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:earlybird/screens/home/widgets/filter_dialog.dart';
import 'package:earlybird/providers/listings_provider.dart';
import 'package:earlybird/models/search_filter.dart';

@GenerateMocks([ListingsProvider])
// ignore: unused_import
import 'filter_dialog_test.mocks.dart';

void main() {
  group('FilterDialog Widget Tests', () {
    late MockListingsProvider mockProvider;

    setUp(() {
      mockProvider = MockListingsProvider();

      // Default mock behavior
      when(mockProvider.currentFilter).thenReturn(SearchFilter());
      when(mockProvider.updateFilter(any)).thenAnswer((_) async => {});
    });

    Widget createFilterDialog() {
      return ChangeNotifierProvider<ListingsProvider>.value(
        value: mockProvider,
        child: const MaterialApp(
          home: Scaffold(
            body: FilterDialog(),
          ),
        ),
      );
    }

    testWidgets('displays all filter fields', (WidgetTester tester) async {
      await tester.pumpWidget(createFilterDialog());

      expect(find.text('Search Filters'), findsOneWidget);
      expect(find.text('Area'), findsOneWidget);
      expect(find.text('Object Type'), findsOneWidget);
      expect(find.text('Publication Date (days)'), findsOneWidget);
      expect(find.text('Sort Order'), findsOneWidget);
    });

    testWidgets('area field is enabled', (WidgetTester tester) async {
      await tester.pumpWidget(createFilterDialog());

      final areaField = tester.widget<TextField>(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.enabled != false &&
              widget.decoration?.hintText != null,
        ),
      );

      expect(areaField.enabled, isNot(false));
    });

    testWidgets('other fields are disabled', (WidgetTester tester) async {
      await tester.pumpWidget(createFilterDialog());

      final disabledFields = tester.widgetList<TextField>(
        find.byWidgetPredicate(
          (widget) => widget is TextField && widget.enabled == false,
        ),
      );

      expect(
          disabledFields.length, 3); // objectType, publicationDate, sortOrder
    });

    testWidgets('has save and discard buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createFilterDialog());

      expect(find.text('Save & Refresh'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('discard button closes dialog without saving',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ListingsProvider>.value(
          value: mockProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const FilterDialog(),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Search Filters'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Search Filters'), findsNothing);
      verifyNever(mockProvider.updateFilter(any));
    });

    testWidgets('save button updates filter and closes dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ListingsProvider>.value(
          value: mockProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const FilterDialog(),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Change area text
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.enabled != false &&
              widget.decoration?.hintText != null,
        ),
        'amsterdam',
      );

      await tester.tap(find.text('Save & Refresh'));
      await tester.pumpAndSettle();

      expect(find.text('Search Filters'), findsNothing);
      verify(mockProvider.updateFilter(any)).called(1);
    });

    testWidgets('displays current area value', (WidgetTester tester) async {
      when(mockProvider.currentFilter).thenReturn(
        SearchFilter(area: 'utrecht'),
      );

      await tester.pumpWidget(createFilterDialog());

      expect(find.text('utrecht'), findsOneWidget);
    });

    testWidgets('area field has hint text', (WidgetTester tester) async {
      await tester.pumpWidget(createFilterDialog());

      final areaField = tester.widget<TextField>(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.hintText != null,
        ),
      );

      expect(areaField.decoration?.hintText, contains('soest'));
    });

    testWidgets('disabled fields have grey background',
        (WidgetTester tester) async {
      await tester.pumpWidget(createFilterDialog());

      final disabledFields = tester.widgetList<TextField>(
        find.byWidgetPredicate(
          (widget) => widget is TextField && widget.enabled == false,
        ),
      );

      for (final field in disabledFields) {
        expect(field.decoration?.fillColor, const Color(0xFFF5F5F5));
      }
    });

    testWidgets('empty area defaults to soest', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ListingsProvider>.value(
          value: mockProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const FilterDialog(),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Clear the area field
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.enabled != false &&
              widget.decoration?.hintText != null,
        ),
        '',
      );

      await tester.tap(find.text('Save & Refresh'));
      await tester.pumpAndSettle();

      // Verify it saves with default 'soest' area
      final captured = verify(mockProvider.updateFilter(captureAny)).captured;
      expect((captured[0] as SearchFilter).area, 'soest');
    });
  });
}
