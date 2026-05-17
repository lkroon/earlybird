import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'scraper_service.dart';
import 'captcha_session_service.dart';
import '../core/exceptions/captcha_exception.dart';
import '../models/search_filter.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/url_builder.dart';

class FundaScraperService implements ScraperService {
  final CaptchaSessionService captchaSession;

  FundaScraperService({required this.captchaSession});

  @override
  String get serviceName => 'Funda';

  @override
  String get baseUrl => 'https://www.funda.nl';

  @override
  List<String> get botProtectionBodyIndicators => [
        'captcha',
        '__akam_recaptcha',
      ];

  @override
  String get botProtectionPageTitle => 'bijna op de pagina';

  @override
  Future<List<Map<String, String>>> fetchListingHeadings(
      SearchFilter filter) async {
    final fundaUrl = UrlBuilder.buildFundaUrl(filter);
    final url = UrlBuilder.withCorsProxy(fundaUrl);

    final headers = Map<String, String>.from(AppConstants.defaultHeaders);
    if (captchaSession.hasValidSession(baseUrl)) {
      headers['Cookie'] = captchaSession.cookieHeader(baseUrl);
    }

    final response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch listings: ${response.statusCode}');
    }

    final document = html_parser.parse(response.body);

    final title = document.querySelector('title')?.text ?? '';
    final isBotProtected = title.contains(botProtectionPageTitle) ||
        botProtectionBodyIndicators
            .any((indicator) => response.body.contains(indicator));

    if (isBotProtected) {
      captchaSession.clearSession(baseUrl);
      throw CaptchaException();
    }

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
      final headers = Map<String, String>.from(AppConstants.defaultHeaders);
      if (captchaSession.hasValidSession(baseUrl)) {
        headers['Cookie'] = captchaSession.cookieHeader(baseUrl);
      }
      final detailResponse = await http.get(
        Uri.parse(url),
        headers: headers,
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
      if (kDebugMode) debugPrint('Error fetching detail page: $e');
    }

    return '';
  }
}
