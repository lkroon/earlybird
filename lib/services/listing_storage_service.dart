import 'package:hive_flutter/hive_flutter.dart';
import '../models/listing.dart';

/// Service for managing persistent storage of listings using Hive
class ListingStorageService {
  static const String _boxName = 'listings';
  static const int _retentionDays = 30;

  Box<Listing>? _box;

  /// Initializes the storage service and opens the Hive box
  Future<void> init() async {
    try {
      _box = await Hive.openBox<Listing>(_boxName);
      await _cleanupOldListings();
    } catch (_) {
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox<Listing>(_boxName);
    }
  }

  /// Gets all cached listings
  List<Listing> getAllListings() {
    if (_box == null) return [];
    return _box!.values.toList();
  }

  /// Gets cached listings for a specific filter
  List<Listing> getListingsForFilter(String filterKey) {
    if (_box == null) return [];
    return _box!.values
        .where((listing) => listing.filterKey == filterKey)
        .toList();
  }

  /// Gets a listing by its URL (ID)
  Listing? getListingById(String url) {
    if (_box == null) return null;
    return _box!.get(url);
  }

  /// Saves or updates a listing
  Future<void> saveListing(Listing listing) async {
    if (_box == null) return;
    await _box!.put(listing.id, listing);
  }

  /// Saves multiple listings
  Future<void> saveListings(List<Listing> listings) async {
    if (_box == null) return;
    final Map<String, Listing> listingMap = {
      for (var listing in listings) listing.id: listing
    };
    await _box!.putAll(listingMap);
  }

  /// Updates the viewed status of a listing
  Future<void> updateListingViewedStatus(String url, bool isViewed) async {
    if (_box == null) return;

    final listing = _box!.get(url);
    if (listing != null) {
      if (isViewed) {
        listing.markAsViewed();
      } else {
        listing.isViewed = false;
        listing.lastSeenAt = null;
      }
      await listing.save();
    }
  }

  /// Toggles the viewed status of a listing
  /// If [forceViewed] is true, always sets to viewed (doesn't toggle)
  Future<void> toggleListingViewed(String url,
      {bool forceViewed = false}) async {
    if (_box == null) return;

    final listing = _box!.get(url);
    if (listing != null) {
      if (forceViewed) {
        listing.markAsViewed();
      } else {
        listing.toggleViewed();
      }
      await listing.save();
    }
  }

  /// Merges new listings with cached ones for the same filter
  /// Returns a combined list with viewed status preserved
  List<Listing> mergeWithCache(List<Listing> newListings, String filterKey) {
    if (_box == null) return newListings;

    final Map<String, Listing> mergedMap = {};

    // First, add all cached listings for this filter
    for (var cachedListing in _box!.values) {
      if (cachedListing.filterKey == filterKey) {
        mergedMap[cachedListing.id] = cachedListing;
      }
    }

    // Then merge with new listings
    for (var newListing in newListings) {
      final existingListing = mergedMap[newListing.id];

      if (existingListing != null) {
        // Preserve viewed status and timestamps, but update other data
        mergedMap[newListing.id] = newListing.copyWith(
          firstSeenAt: existingListing.firstSeenAt,
          lastSeenAt: existingListing.lastSeenAt,
          isViewed: existingListing.isViewed,
        );
      } else {
        // New listing - add with current timestamp
        mergedMap[newListing.id] = newListing;
      }
    }

    return mergedMap.values.toList();
  }

  /// Removes listings older than retention period
  Future<void> _cleanupOldListings() async {
    if (_box == null) return;

    final cutoffDate = DateTime.now().subtract(
      const Duration(days: _retentionDays),
    );

    final keysToDelete = <String>[];

    for (var listing in _box!.values) {
      if (listing.firstSeenAt.isBefore(cutoffDate)) {
        keysToDelete.add(listing.id);
      }
    }

    await _box!.deleteAll(keysToDelete);
  }

  /// Clears all stored listings (for testing or reset)
  Future<void> clearAll() async {
    if (_box == null) return;
    await _box!.clear();
  }

  /// Closes the storage box
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
