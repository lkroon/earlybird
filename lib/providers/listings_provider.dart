import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../models/search_filter.dart';
import '../models/site.dart';
import '../services/scraper_service.dart';
import '../services/image_loader_service.dart';
import '../services/listing_storage_service.dart';
import '../core/constants/app_constants.dart';

class ListingsProvider extends ChangeNotifier {
  final ScraperService scraperService;
  final ImageLoaderService imageLoaderService;
  final ListingStorageService storageService;

  ListingsProvider({
    required this.scraperService,
    required this.storageService,
  }) : imageLoaderService = ImageLoaderService(scraperService);

  List<Listing> _listings = [];
  List<Map<String, String>> _allHeadings = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentIndex = 0;
  SearchFilter _currentFilter = SearchFilter();
  String? _errorMessage;
  Site _selectedSite = Site.funda;

  List<Listing> get listings => _listings;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _currentIndex < _allHeadings.length;
  SearchFilter get currentFilter => _currentFilter;
  String? get errorMessage => _errorMessage;
  Site get selectedSite => _selectedSite;

  void selectSite(Site site) {
    if (site == _selectedSite) return;
    _selectedSite = site;
    notifyListeners();
    fetchListings();
  }

  Future<void> fetchListings() async {
    _isLoading = true;
    _listings = [];
    _allHeadings = [];
    _currentIndex = 0;
    _errorMessage = null;
    notifyListeners();

    try {
      _allHeadings = await scraperService.fetchListingHeadings(_currentFilter);
      _isLoading = false;
      notifyListeners();

      await loadMore();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load listings: $e';
      notifyListeners();
      debugPrint('Error fetching listings: $e');
    }
  }

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

      final filterKey = _currentFilter.toQueryString();
      final listingsWithFilter =
          newListings.map((l) => l.copyWith(filterKey: filterKey)).toList();
      final merged =
          storageService.mergeWithCache(listingsWithFilter, filterKey);
      await storageService.saveListings(merged);

      _listings.addAll(merged);
      _currentIndex += batchSize;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _errorMessage = 'Failed to load more listings: $e';
      notifyListeners();
      debugPrint('Error loading more listings: $e');
    }
  }

  Future<void> markAsViewed(Listing listing) async {
    listing.markAsViewed();
    await storageService.updateListingViewedStatus(listing.id, true);
    notifyListeners();
  }

  Future<void> updateFilter(SearchFilter newFilter) async {
    _currentFilter = newFilter;
    await fetchListings();
  }

  bool shouldLoadMore(int currentItemIndex) {
    return currentItemIndex >=
        _listings.length - AppConstants.loadMoreThreshold;
  }

  Future<void> refresh() => fetchListings();
}
