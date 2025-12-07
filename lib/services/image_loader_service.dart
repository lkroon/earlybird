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
    int batchSize, {
    String filterKey = '',
  }) async {
    final endIndex = (startIndex + batchSize).clamp(0, headings.length);
    final batch = headings.sublist(startIndex, endIndex);

    // Fetch all images in parallel for better performance
    final imageFutures = batch.map((heading) async {
      final detailUrl = heading['url'] ?? '';
      final thumbnailUrl = heading['image'] ?? '';

      // Fetch full image gallery from detail page
      final detailImages = await scraperService.fetchListingImages(detailUrl);

      // If we have a thumbnail and detail images, combine them
      // Otherwise use whatever we have
      List<String> imageUrls;
      if (thumbnailUrl.isNotEmpty && detailImages.isNotEmpty) {
        // Start with thumbnail, add detail images if they're different
        imageUrls = [thumbnailUrl];
        for (var img in detailImages) {
          if (img != thumbnailUrl && !imageUrls.contains(img)) {
            imageUrls.add(img);
          }
        }
      } else if (detailImages.isNotEmpty) {
        imageUrls = detailImages;
      } else if (thumbnailUrl.isNotEmpty) {
        imageUrls = [thumbnailUrl];
      } else {
        imageUrls = [];
      }

      return Listing(
        title: heading['title'] ?? '',
        content: heading['content'] ?? '',
        url: detailUrl,
        imageUrls: imageUrls,
        filterKey: filterKey,
      );
    });

    // Wait for all image fetches to complete in parallel
    final newListings = await Future.wait(imageFutures);

    return newListings;
  }

  /// Returns the appropriate batch size based on whether it's the first load
  int getBatchSize(bool isFirstBatch) {
    return isFirstBatch
        ? AppConstants.initialBatchSize
        : AppConstants.subsequentBatchSize;
  }
}
