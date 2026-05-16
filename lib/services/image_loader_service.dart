import 'scraper_service.dart';
import '../models/listing.dart';
import '../core/constants/app_constants.dart';

/// Service for loading images incrementally
class ImageLoaderService {
  final ScraperService scraperService;

  ImageLoaderService(this.scraperService);

  /// Loads a batch of listings with their images
  /// Takes partial listing data and fetches images for them
  Future<List<Listing>> loadBatch(
    List<Map<String, String>> headings,
    int startIndex,
    int batchSize,
  ) async {
    final endIndex = (startIndex + batchSize).clamp(0, headings.length);
    final newListings = <Listing>[];

    for (var i = startIndex; i < endIndex; i++) {
      final heading = headings[i];
      final detailUrl = heading['url'] ?? '';

      // Fetch the image
      final imageUrl = await scraperService.fetchListingImage(detailUrl);

      newListings.add(Listing(
        title: heading['title'] ?? '',
        content: heading['content'] ?? '',
        url: detailUrl,
        imageUrl: imageUrl,
      ));
    }

    return newListings;
  }

  /// Returns the appropriate batch size based on whether it's the first load
  int getBatchSize(bool isFirstBatch) {
    return isFirstBatch
        ? AppConstants.initialBatchSize
        : AppConstants.subsequentBatchSize;
  }
}
