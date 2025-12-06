import '../constants/app_constants.dart';
import '../../models/search_filter.dart';

/// Utility class for building URLs with filters
class UrlBuilder {
  UrlBuilder._();

  /// Builds a Funda search URL with the given filters
  static String buildFundaUrl(SearchFilter filter) {
    final queryParams = filter.toQueryParams();
    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '${AppConstants.fundaBaseUrl}${AppConstants.fundaSearchPath}?$queryString';
  }

  /// Wraps a URL with the CORS proxy
  static String withCorsProxy(String url) {
    // Add timestamp to bust cache on CORS proxy
    final separator = url.contains('?') ? '&' : '?';
    final urlWithCacheBust =
        '$url${separator}_t=${DateTime.now().millisecondsSinceEpoch}';
    return '${AppConstants.corsProxyUrl}${Uri.encodeComponent(urlWithCacheBust)}';
  }
}
