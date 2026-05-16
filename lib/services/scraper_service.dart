import '../models/search_filter.dart';

/// Abstract interface for real estate listing scrapers
abstract class ScraperService {
  /// Fetches all listing headings/metadata without images
  /// Returns a list of partial listings that can be loaded incrementally
  Future<List<Map<String, String>>> fetchListingHeadings(SearchFilter filter);

  /// Fetches the image URL for a specific listing by visiting its detail page
  Future<String> fetchListingImage(String detailUrl);

  /// Returns the name of the scraper service (e.g., "Funda", "Jaap")
  String get serviceName;
}
