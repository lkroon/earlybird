import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../models/search_filter.dart';
import '../services/scraper_service.dart';
import '../services/image_loader_service.dart';
import '../core/constants/app_constants.dart';

/// Provider for managing listings state
class ListingsProvider extends ChangeNotifier {
  final ScraperService scraperService;
  final ImageLoaderService imageLoaderService;

  ListingsProvider({
    required this.scraperService,
  }) : imageLoaderService = ImageLoaderService(scraperService);

  // State
  List<Listing> _listings = [];
  List<Map<String, String>> _allHeadings = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentIndex = 0;
  SearchFilter _currentFilter = SearchFilter();

  // Getters
  List<Listing> get listings => _listings;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _currentIndex < _allHeadings.length;
  SearchFilter get currentFilter => _currentFilter;

  /// Fetches listings with the current filter
  Future<void> fetchListings() async {
    _isLoading = true;
    _listings = [];
    _allHeadings = [];
    _currentIndex = 0;
    notifyListeners();

    try {
      // Fetch all listing headings
      _allHeadings = await scraperService.fetchListingHeadings(_currentFilter);
      _isLoading = false;
      notifyListeners();

      // Load first batch with images
      await loadMore();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching listings: $e');
      rethrow;
    }
  }

  /// Loads more listings (fetching images for the next batch)
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final isFirstBatch = _currentIndex == 0;
      final batchSize = imageLoaderService.getBatchSize(isFirstBatch);

      final newListings = await imageLoaderService.loadBatch(
        _allHeadings,
        _currentIndex,
        batchSize,
      );

      _listings.addAll(newListings);
      _currentIndex += batchSize;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      notifyListeners();
      debugPrint('Error loading more listings: $e');
    }
  }

  /// Updates the search filter and refetches listings
  Future<void> updateFilter(SearchFilter newFilter) async {
    _currentFilter = newFilter;
    await fetchListings();
  }

  /// Checks if we should load more based on scroll position
  bool shouldLoadMore(int currentItemIndex) {
    return currentItemIndex >=
        _listings.length - AppConstants.loadMoreThreshold;
  }

  /// Refreshes the listings
  Future<void> refresh() => fetchListings();
}
