/// Application-wide constants
class AppConstants {
  AppConstants._();

  // CORS Proxy
  static const String corsProxyUrl = 'https://corsproxy.io/?';

  // HTTP Headers
  static const Map<String, String> defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'nl-NL,nl;q=0.9,en-US;q=0.8,en;q=0.7',
    'Accept-Encoding': 'gzip, deflate, br',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };

  // Funda specific
  static const String fundaBaseUrl = 'https://www.funda.nl';
  static const String fundaSearchPath = '/zoeken/koop';

  // Pagination
  static const int initialBatchSize = 10;
  static const int subsequentBatchSize = 5;
  static const int loadMoreThreshold =
      5; // Load more when within 5 items of end
}
