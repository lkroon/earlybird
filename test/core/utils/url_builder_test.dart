import 'package:flutter_test/flutter_test.dart';
import 'package:earlybird/core/utils/url_builder.dart';
import 'package:earlybird/models/search_filter.dart';
import 'package:earlybird/core/constants/app_constants.dart';

void main() {
  group('UrlBuilder Tests', () {
    test('buildFundaUrl creates correct URL with default filter', () {
      final filter = SearchFilter();
      final url = UrlBuilder.buildFundaUrl(filter);

      expect(url, contains('https://www.funda.nl/zoeken/koop'));
      expect(url,
          contains('selected_area=%5B%22soest%22%5D')); // encoded ["soest"]
      expect(
          url, contains('object_type=%5B%22house%22%5D')); // encoded ["house"]
      expect(url, contains('publication_date=%2230%22')); // encoded "30"
      expect(url, contains('sort=%22date_down%22')); // encoded "date_down"
    });

    test('buildFundaUrl creates correct URL with custom filter', () {
      final filter = SearchFilter(
        area: 'amsterdam',
        objectType: 'apartment',
        publicationDate: '7',
        sortOrder: 'price_up',
      );
      final url = UrlBuilder.buildFundaUrl(filter);

      expect(url, contains('selected_area=%5B%22amsterdam%22%5D'));
      expect(url, contains('object_type=%5B%22apartment%22%5D'));
      expect(url, contains('publication_date=%227%22'));
      expect(url, contains('sort=%22price_up%22'));
    });

    test('buildFundaUrl includes all query parameters', () {
      final filter = SearchFilter();
      final url = UrlBuilder.buildFundaUrl(filter);

      final uri = Uri.parse(url);
      expect(uri.queryParameters, isNotEmpty);
      expect(uri.path, '/zoeken/koop');
    });

    test('withCorsProxy returns URL unchanged on non-web platforms', () {
      const testUrl = 'https://www.funda.nl/test';
      final proxiedUrl = UrlBuilder.withCorsProxy(testUrl);

      // On non-web (test runner), CORS proxy is skipped
      expect(proxiedUrl, equals(testUrl));
    });

    test('withCorsProxy preserves query parameters on non-web', () {
      const testUrl = 'https://www.funda.nl/test?param=value&other=test';
      final proxiedUrl = UrlBuilder.withCorsProxy(testUrl);

      expect(proxiedUrl, equals(testUrl));
    });

    test('buildFundaUrl with special characters in area', () {
      final filter = SearchFilter(area: 's-hertogenbosch');
      final url = UrlBuilder.buildFundaUrl(filter);

      expect(url, contains('s-hertogenbosch'));
    });
  });
}
