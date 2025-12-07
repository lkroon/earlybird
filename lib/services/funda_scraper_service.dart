import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'scraper_service.dart';
import '../models/search_filter.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/url_builder.dart';

/// Funda-specific implementation of the scraper service
class FundaScraperService implements ScraperService {
  @override
  String get serviceName => 'Funda';

  /// Checks if an image is likely a property image based on dimensions
  /// Property images are typically larger than logos/icons
  bool _isValidPropertyImage(dynamic img) {
    final width = int.tryParse(img.attributes['width'] ?? '0') ?? 0;
    final height = int.tryParse(img.attributes['height'] ?? '0') ?? 0;

    // If dimensions are specified and too small, it's likely a logo/icon
    if (width > 0 && height > 0) {
      // Property images are typically at least 400x400
      if (width < 400 || height < 400) {
        return false;
      }
    }

    final src = img.attributes['src'] ??
        img.attributes['data-src'] ??
        img.attributes['data-lazy-src'] ??
        '';

    // Additional URL-based filters
    if (src.isEmpty ||
        src.contains('logo') ||
        src.contains('icon') ||
        src.contains('badge') ||
        src.contains('button') ||
        src.contains('avatar')) {
      return false;
    }

    return true;
  }

  @override
  Future<List<Map<String, String>>> fetchListingHeadings(
      SearchFilter filter) async {
    final fundaUrl = UrlBuilder.buildFundaUrl(filter);
    final url = UrlBuilder.withCorsProxy(fundaUrl);

    final response = await http.get(
      Uri.parse(url),
      headers: AppConstants.defaultHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch listings: ${response.statusCode}');
    }

    // Parse HTML
    final document = html_parser.parse(response.body);
    final allHeadings = document.querySelectorAll('h1, h2, h3, h4');
    final listings = <Map<String, String>>[];

    for (var heading in allHeadings) {
      final headingText = heading.text.trim();
      if (headingText.isEmpty) continue;

      // Extract href from innerHtml
      final innerHtml = heading.innerHtml;
      final hrefMatch = RegExp(r'href="([^"]+)"').firstMatch(innerHtml);
      var detailUrl = '';

      if (hrefMatch != null) {
        final href = hrefMatch.group(1) ?? '';
        detailUrl = href.startsWith('http')
            ? href
            : '${AppConstants.fundaBaseUrl}$href';
      } else {
        continue;
      }

      // Try to get the next sibling text or parent's next content
      var nextContent = '';
      var nextElement = heading.nextElementSibling;
      if (nextElement != null) {
        nextContent = nextElement.text.trim();
        if (nextContent.length > 200) {
          nextContent = nextContent.substring(0, 200);
        }
      }

      // Only include detail page links
      if (detailUrl.contains('/detail/')) {
        // Extract thumbnail image from the listing card
        var thumbnailUrl = '';
        // Look for img tag in the immediate parent/ancestor (max 3 levels up)
        var currentElement = heading.parent;
        var depth = 0;
        const maxDepth = 3; // Limit search to prevent going too far up the tree

        while (currentElement != null &&
            thumbnailUrl.isEmpty &&
            depth < maxDepth) {
          final images = currentElement.querySelectorAll('img');
          // Find the first valid property image (skip logos/icons based on size)
          for (var img in images) {
            if (_isValidPropertyImage(img)) {
              final src = img.attributes['src'] ??
                  img.attributes['data-src'] ??
                  img.attributes['data-lazy-src'] ??
                  '';
              if (src.isNotEmpty) {
                thumbnailUrl = src;
                break;
              }
            }
          }
          currentElement = currentElement.parent;
          depth++;
        }

        listings.add({
          'title': headingText,
          'content': nextContent,
          'url': detailUrl,
          'image': thumbnailUrl, // Thumbnail from overview page
        });
      }
    }

    return listings;
  }

  @override
  Future<String> fetchListingImage(String detailUrl) async {
    final images = await fetchListingImages(detailUrl);
    return images.isNotEmpty ? images.first : '';
  }

  @override
  Future<List<String>> fetchListingImages(String detailUrl) async {
    if (detailUrl.isEmpty) return [];

    try {
      final url = UrlBuilder.withCorsProxy(detailUrl);
      final detailResponse = await http.get(
        Uri.parse(url),
        headers: AppConstants.defaultHeaders,
      );

      if (detailResponse.statusCode == 200) {
        final detailDoc = html_parser.parse(detailResponse.body);
        final detailImages = detailDoc.querySelectorAll('img');
        final imageUrls = <String>[];
        final thumbnailCandidates = <String>[];

        // Collect all images, prioritizing valid thumbnails
        for (var img in detailImages) {
          final imageUrl = img.attributes['src'] ??
              img.attributes['data-src'] ??
              img.attributes['data-lazy-src'] ??
              '';

          if (imageUrl.isEmpty ||
              imageUrl.contains('logo') ||
              imageUrl.contains('icon') ||
              imageUrl.contains('badge') ||
              imageUrl.contains('button') ||
              imageUrl.contains('avatar')) {
            continue; // Skip obvious non-property images
          }

          // Check if it's a valid thumbnail (400x400+)
          if (_isValidPropertyImage(img)) {
            thumbnailCandidates.add(imageUrl);
          }

          if (!imageUrls.contains(imageUrl)) {
            imageUrls.add(imageUrl);
          }
        }

        // Reorder: put valid thumbnails first
        final reorderedUrls = <String>[];
        reorderedUrls.addAll(thumbnailCandidates);
        for (var url in imageUrls) {
          if (!thumbnailCandidates.contains(url)) {
            reorderedUrls.add(url);
          }
        }

        return reorderedUrls;
      }
    } catch (e) {
      debugPrint('Error fetching detail page images: $e');
    }

    return [];
  }
}
