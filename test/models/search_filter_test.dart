import 'package:flutter_test/flutter_test.dart';
import 'package:earlybird/models/search_filter.dart';

void main() {
  group('SearchFilter Model Tests', () {
    test('creates SearchFilter with default values', () {
      final filter = SearchFilter();

      expect(filter.area, 'soest');
      expect(filter.objectType, 'house');
      expect(filter.publicationDate, '30');
      expect(filter.sortOrder, 'date_down');
    });

    test('creates SearchFilter with custom values', () {
      final filter = SearchFilter(
        area: 'amsterdam',
        objectType: 'apartment',
        publicationDate: '7',
        sortOrder: 'price_up',
      );

      expect(filter.area, 'amsterdam');
      expect(filter.objectType, 'apartment');
      expect(filter.publicationDate, '7');
      expect(filter.sortOrder, 'price_up');
    });

    test('copyWith updates only specified fields', () {
      final original = SearchFilter(area: 'soest');
      final updated = original.copyWith(objectType: 'apartment');

      expect(updated.area, 'soest');
      expect(updated.objectType, 'apartment');
      expect(updated.publicationDate, '30');
      expect(updated.sortOrder, 'date_down');
    });

    test('copyWith with no changes returns equivalent filter', () {
      final original = SearchFilter(area: 'utrecht');
      final copy = original.copyWith();

      expect(copy.area, original.area);
      expect(copy.objectType, original.objectType);
      expect(copy.publicationDate, original.publicationDate);
      expect(copy.sortOrder, original.sortOrder);
    });

    test('toQueryParams returns correct map', () {
      final filter = SearchFilter(
        area: 'amsterdam',
        objectType: 'apartment',
        publicationDate: '7',
        sortOrder: 'price_down',
      );

      final params = filter.toQueryParams();

      expect(params['selected_area'], '["amsterdam"]');
      expect(params['object_type'], '["apartment"]');
      expect(params['publication_date'], '"7"');
      expect(params['sort'], '"price_down"');
    });

    test('toQueryParams formats area with quotes and brackets', () {
      final filter = SearchFilter(area: 'den-haag');
      final params = filter.toQueryParams();

      expect(params['selected_area'], '["den-haag"]');
    });
  });
}
