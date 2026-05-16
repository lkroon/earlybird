import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/app_constants.dart';
import '../../models/search_filter.dart';

class UrlBuilder {
  UrlBuilder._();

  static String buildFundaUrl(SearchFilter filter) {
    final queryParams = filter.toQueryParams();
    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '${AppConstants.fundaBaseUrl}${AppConstants.fundaSearchPath}?$queryString';
  }

  static String withCorsProxy(String url) {
    if (!kIsWeb) return url;
    return '${AppConstants.corsProxyUrl}${Uri.encodeComponent(url)}';
  }
}
