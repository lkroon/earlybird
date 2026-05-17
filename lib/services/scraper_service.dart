import '../models/search_filter.dart';

abstract class ScraperService {
  Future<List<Map<String, String>>> fetchListingHeadings(SearchFilter filter);

  Future<String> fetchListingImage(String detailUrl);

  String get serviceName;

  String get baseUrl;

  List<String> get botProtectionBodyIndicators;

  String get botProtectionPageTitle;
}
