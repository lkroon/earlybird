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
        listings.add({
          'title': headingText,
          'content': nextContent,
          'url': detailUrl,
          'image': '', // Will be loaded later
        });
      }
    }

    return listings;
  }

  @override
  Future<String> fetchListingImage(String detailUrl) async {
    if (detailUrl.isEmpty) return '';

    try {
      final url = UrlBuilder.withCorsProxy(detailUrl);
      final detailResponse = await http.get(
        Uri.parse(url),
        headers: AppConstants.defaultHeaders,
      );

      if (detailResponse.statusCode == 200) {
        final detailDoc = html_parser.parse(detailResponse.body);
        final detailImages = detailDoc.querySelectorAll('img');

        // Get the second image (skip the logo)
        if (detailImages.length > 1) {
          final img = detailImages.elementAt(1);
          return img.attributes['src'] ??
              img.attributes['data-src'] ??
              img.attributes['data-lazy-src'] ??
              '';
        }
      }
    } catch (e) {
      debugPrint('Error fetching detail page: $e');
    }

    return '';
  }
}
