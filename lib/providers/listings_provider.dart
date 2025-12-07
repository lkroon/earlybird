import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../models/search_filter.dart';
import '../services/scraper_service.dart';
import '../services/image_loader_service.dart';
import '../services/listing_storage_service.dart';
import '../core/constants/app_constants.dart';

/// Provider for managing listings state
class ListingsProvider extends ChangeNotifier {
  final ScraperService scraperService;
  final ImageLoaderService imageLoaderService;
  final ListingStorageService storageService;

  ListingsProvider({
    required this.scraperService,
    required this.storageService,
  }) : imageLoaderService = ImageLoaderService(scraperService);

  // State
  List<Listing> _listings = [];
  List<Map<String, String>> _allHeadings = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  int _currentIndex = 0;
  SearchFilter _currentFilter = SearchFilter();
  String? _errorMessage;

  // Getters
  List<Listing> get listings => _listings;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  bool get hasMore => _currentIndex < _allHeadings.length;
  SearchFilter get currentFilter => _currentFilter;
  String? get errorMessage => _errorMessage;

  /// Fetches listings with the current filter
  Future<void> fetchListings() async {
    // Load cached listings immediately
    _loadCachedListings();

    _isRefreshing = true;
    _allHeadings = [];
    _currentIndex = 0;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch all listing headings in the background
      _allHeadings = await scraperService.fetchListingHeadings(_currentFilter);
      _isRefreshing = false;
      notifyListeners();

      // Load first batch with images
      await loadMore(mergeWithCache: true);
    } catch (e) {
      _isRefreshing = false;
      _errorMessage = 'Failed to load listings: $e';
      notifyListeners();
      debugPrint('Error fetching listings: $e');
    }
  }

  /// Loads cached listings from storage
  void _loadCachedListings() {
    final filterKey = _currentFilter.toKey();
    final cachedListings = storageService.getListingsForFilter(filterKey);
    if (cachedListings.isNotEmpty) {
      _listings = cachedListings;
      _isLoading = false;
      notifyListeners();
    } else {
      _isLoading = true;
      _listings = [];
      notifyListeners();
    }
  }

  /// Loads more listings (fetching images for the next batch)
  Future<void> loadMore({bool mergeWithCache = false}) async {
    if (_isLoadingMore || !hasMore) return;

    final isFirstBatch = _currentIndex == 0;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final batchSize = imageLoaderService.getBatchSize(isFirstBatch);
      final filterKey = _currentFilter.toKey();

      final newListings = await imageLoaderService.loadBatch(
        _allHeadings,
        _currentIndex,
        batchSize,
        filterKey: filterKey,
      );

      if (mergeWithCache) {
        // Get merged listings (includes cache + new)
        final mergedListings =
            storageService.mergeWithCache(newListings, filterKey);
        
        // Find truly new listings (not in current _listings)
        final existingIds = _listings.map((l) => l.id).toSet();
        final trulyNewListings = mergedListings
            .where((listing) => !existingIds.contains(listing.id))
            .toList();
        
        // Prepend new listings to the top, keep existing ones
        if (trulyNewListings.isNotEmpty) {
          _listings = [...trulyNewListings, ..._listings];
        }

        // Save merged listings to cache
        await storageService.saveListings(mergedListings);
      } else {
        _listings.addAll(newListings);

        // Save new listings to cache
        await storageService.saveListings(newListings);
      }

      _currentIndex += batchSize;
      _isLoadingMore = false;
      
      // Clear initial loading state after first batch
      if (isFirstBatch) {
        _isLoading = false;
      }
      
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      
      // Clear loading states on error
      if (isFirstBatch) {
        _isLoading = false;
      }
      
      _errorMessage = 'Failed to load more listings: $e';
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

  /// Toggles the viewed status of a listing
  Future<void> toggleListingViewed(String url) async {
    await storageService.toggleListingViewed(url);

    // Update the listing in the current list
    final index = _listings.indexWhere((listing) => listing.id == url);
    if (index != -1) {
      notifyListeners();
    }
  }

  /// Clears all cached listings from storage
  Future<void> clearAllCachedListings() async {
    await storageService.clearAll();
    _listings.clear();
    notifyListeners();
  }

  /// Refreshes the listings
  Future<void> refresh() => fetchListings();
}
