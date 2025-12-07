import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Application-wide constants
class AppConstants {
  AppConstants._();

  // CORS Proxy
  static const String corsProxyUrl = 'https://corsproxy.io/?';

  // HTTP Headers
  static Map<String, String> get defaultHeaders {
    if (kIsWeb) {
      // Web headers - User-Agent cannot be set in browsers due to security restrictions
      return {
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
      };
    } else if (Platform.isIOS) {
      // iOS headers
      return {
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'nl-NL,nl;q=0.9,en-US;q=0.8,en;q=0.7',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      };
    } else {
      // Android and other platforms
      return {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'nl-NL,nl;q=0.9,en-US;q=0.8,en;q=0.7',
      };
    }
  }

  // Funda specific
  static const String fundaBaseUrl = 'https://www.funda.nl';
  static const String fundaSearchPath = '/zoeken/koop';

  // Pagination
  static const int initialBatchSize = 5;
  static const int subsequentBatchSize = 5;
  static const int loadMoreThreshold =
      2; // Load more when within 2 items of end
}
