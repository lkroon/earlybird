/// Application-wide constants
class AppConstants {
  AppConstants._();

  // CORS Proxy
  static const String corsProxyUrl = 'https://corsproxy.io/?';

  // HTTP Headers
  static const Map<String, String> defaultHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
  };

  // Funda specific
  static const String fundaBaseUrl = 'https://www.funda.nl';
  static const String fundaSearchPath = '/zoeken/koop';

  // Pagination
  static const int initialBatchSize = 10;
  static const int subsequentBatchSize = 5;
  static const int loadMoreThreshold = 5; // Load more when within 5 items of end
}
