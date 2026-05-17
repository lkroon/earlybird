import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CaptchaWebView extends StatefulWidget {
  final String url;
  final String botProtectionPageTitle;
  final void Function(List<Map<String, String>> headings) onDataExtracted;
  final VoidCallback onError;

  const CaptchaWebView({
    super.key,
    required this.url,
    required this.botProtectionPageTitle,
    required this.onDataExtracted,
    required this.onError,
  });

  @override
  State<CaptchaWebView> createState() => _CaptchaWebViewState();
}

enum _Phase { solvingCaptcha, loadingSearch, polling, done }

class _CaptchaWebViewState extends State<CaptchaWebView> {
  late final WebViewController _controller;
  _Phase _phase = _Phase.solvingCaptcha;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  String _debugInfo = '';
  bool _hasNavigatedToSearch = false;
  static const _maxPollAttempts = 20;
  static const _pollInterval = Duration(milliseconds: 500);

  static const _extractionJs = '''
(function() {
  var results = [];
  var seen = {};

  var links = document.querySelectorAll('a[href*="/detail/"], a[href*="/koop/"], a[href*="/huur/"]');
  for (var i = 0; i < links.length; i++) {
    var link = links[i];
    var href = link.getAttribute('href');
    if (!href || seen[href]) continue;
    if (href.indexOf('/detail/') === -1 && !href.match(/\\/(koop|huur)\\/[^/]+\\/[^/]+\\//)) continue;
    seen[href] = true;
    var url = href.startsWith('http') ? href : 'https://www.funda.nl' + href;
    var title = '';
    var heading = link.querySelector('h1, h2, h3, h4, h5');
    if (heading) {
      title = heading.textContent.trim();
    } else {
      title = link.textContent.trim().split('\\n')[0].trim();
    }
    if (!title || title.length < 3) continue;
    if (title.length > 200) title = title.substring(0, 200);
    var card = link.closest('[data-test-id], [class*="search-result"], [class*="listing"], [class*="card"], li, article');
    var content = '';
    if (card) {
      var texts = card.querySelectorAll('span, p, li, div');
      var parts = [];
      for (var j = 0; j < texts.length && parts.length < 5; j++) {
        var t = texts[j].textContent.trim();
        if (t && t !== title && t.length > 2 && t.length < 100 && parts.indexOf(t) === -1) {
          parts.push(t);
        }
      }
      content = parts.join(' · ');
    }
    var img = '';
    var imgEl = card ? card.querySelector('img[src*="cloud.funda"], img[src*="funda"]') : null;
    if (!imgEl && card) imgEl = card.querySelector('img[src]:not([src*="logo"]):not([src*="svg"])');
    if (!imgEl) imgEl = link.querySelector('img[src]');
    if (imgEl) img = imgEl.getAttribute('src') || imgEl.getAttribute('data-src') || '';
    results.push({title: title, content: content, url: url, image: img});
  }

  if (results.length === 0) {
    var allLinks = document.querySelectorAll('a[href]');
    for (var i = 0; i < allLinks.length; i++) {
      var link = allLinks[i];
      var href = link.getAttribute('href') || '';
      if (seen[href]) continue;
      if (href.indexOf('/detail/') === -1 && href.indexOf('/object/') === -1) continue;
      seen[href] = true;
      var url = href.startsWith('http') ? href : 'https://www.funda.nl' + href;
      var title = link.textContent.trim().split('\\n')[0].trim();
      if (!title || title.length < 3) continue;
      if (title.length > 200) title = title.substring(0, 200);
      results.push({title: title, content: '', url: url, image: ''});
    }
  }

  return JSON.stringify(results);
})()
''';

  static const _diagnosticJs = '''
(function() {
  var info = {};
  info.title = document.title;
  info.url = window.location.href;
  info.allLinksCount = document.querySelectorAll('a').length;
  info.detailLinks = document.querySelectorAll('a[href*="/detail/"]').length;
  info.koopLinks = document.querySelectorAll('a[href*="/koop/"]').length;
  info.h2Count = document.querySelectorAll('h2').length;
  info.imgCount = document.querySelectorAll('img').length;
  var sample = [];
  var links = document.querySelectorAll('a[href]');
  for (var i = 0; i < Math.min(links.length, 10); i++) {
    sample.push(links[i].getAttribute('href'));
  }
  info.sampleHrefs = sample;
  return JSON.stringify(info);
})()
''';

  @override
  void initState() {
    super.initState();
    final baseUrl = Uri.parse(widget.url).origin;
    debugPrint(
        '[CaptchaWebView] Init: baseUrl=$baseUrl, searchUrl=${widget.url}');
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: _onPageFinished,
        ),
      )
      ..loadRequest(Uri.parse(baseUrl));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _onPageFinished(String url) async {
    if (_phase == _Phase.done) return;

    final title = await _controller.runJavaScriptReturningResult(
      'document.title',
    );
    final titleStr = title.toString().replaceAll('"', '');
    debugPrint(
        '[CaptchaWebView] onPageFinished: url=$url | title=$titleStr | phase=$_phase');

    if (titleStr.contains(widget.botProtectionPageTitle)) {
      if (_phase != _Phase.solvingCaptcha) {
        debugPrint('[CaptchaWebView] Captcha detected after navigation, '
            'resetting to solve');
      }
      setState(() => _phase = _Phase.solvingCaptcha);
      _hasNavigatedToSearch = false;
      return;
    }

    if (_phase == _Phase.solvingCaptcha && !_hasNavigatedToSearch) {
      debugPrint('[CaptchaWebView] Captcha solved, navigating to search URL');
      _hasNavigatedToSearch = true;
      setState(() => _phase = _Phase.loadingSearch);
      await Future.delayed(const Duration(seconds: 1));
      await _controller.loadRequest(Uri.parse(widget.url));
      return;
    }

    if (_phase == _Phase.loadingSearch) {
      final currentUrl = await _controller.runJavaScriptReturningResult(
        'window.location.href',
      );
      final currentUrlStr = currentUrl.toString().replaceAll('"', '');
      debugPrint('[CaptchaWebView] Checking URL: $currentUrlStr');

      if (currentUrlStr.contains('/zoeken/')) {
        debugPrint('[CaptchaWebView] On search page, starting polling');
        setState(() => _phase = _Phase.polling);
        _startPolling();
      } else {
        debugPrint(
            '[CaptchaWebView] Not on search page yet, waiting for redirect');
      }
    }
  }

  void _startPolling() {
    _pollAttempts = 0;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollForListings());
  }

  Future<void> _pollForListings() async {
    if (_phase == _Phase.done) {
      _pollTimer?.cancel();
      return;
    }

    _pollAttempts++;
    debugPrint(
        '[CaptchaWebView] Poll attempt $_pollAttempts/$_maxPollAttempts');

    try {
      final diagResult =
          await _controller.runJavaScriptReturningResult(_diagnosticJs);
      final diagStr = diagResult.toString().replaceAll(r'\"', '"');
      final diagCleaned = diagStr.startsWith('"')
          ? diagStr.substring(1, diagStr.length - 1)
          : diagStr;
      debugPrint('[CaptchaWebView] Diagnostics: $diagCleaned');

      final diag = json.decode(diagCleaned) as Map<String, dynamic>;
      final detailLinks = diag['detailLinks'] as int? ?? 0;
      final koopLinks = diag['koopLinks'] as int? ?? 0;
      final allLinks = diag['allLinksCount'] as int? ?? 0;

      setState(() {
        _debugInfo = 'Links: $allLinks | Detail: $detailLinks | '
            'Koop: $koopLinks | Poll: $_pollAttempts';
      });

      if (detailLinks > 0 || koopLinks > 2) {
        _pollTimer?.cancel();
        debugPrint('[CaptchaWebView] Found listings, extracting...');
        await Future.delayed(const Duration(milliseconds: 500));
        await _extractData();
      } else if (_pollAttempts >= _maxPollAttempts) {
        _pollTimer?.cancel();
        debugPrint(
            '[CaptchaWebView] Max polls reached. Final diagnostics: $diagCleaned');
        await _extractData();
      }
    } catch (e) {
      debugPrint('[CaptchaWebView] Poll error: $e');
      if (_pollAttempts >= _maxPollAttempts) {
        _pollTimer?.cancel();
        widget.onError();
      }
    }
  }

  Future<void> _extractData() async {
    if (_phase == _Phase.done) return;
    setState(() => _phase = _Phase.done);

    try {
      final result =
          await _controller.runJavaScriptReturningResult(_extractionJs);
      final jsonStr = result.toString().replaceAll(r'\"', '"');
      final cleaned = jsonStr.startsWith('"')
          ? jsonStr.substring(1, jsonStr.length - 1)
          : jsonStr;
      final List<dynamic> parsed = json.decode(cleaned);
      final headings =
          parsed.map((item) => Map<String, String>.from(item as Map)).toList();
      debugPrint('[CaptchaWebView] Extracted ${headings.length} listings');
      if (headings.isNotEmpty) {
        debugPrint('[CaptchaWebView] First: ${headings.first}');
      }
      widget.onDataExtracted(headings);
    } catch (e) {
      debugPrint('[CaptchaWebView] Extraction error: $e');
      widget.onError();
    }
  }

  String get _statusText {
    switch (_phase) {
      case _Phase.solvingCaptcha:
        return 'Solve the verification to continue.';
      case _Phase.loadingSearch:
        return 'Captcha solved! Loading search results...';
      case _Phase.polling:
        return 'Waiting for listings to load...';
      case _Phase.done:
        return 'Extracting listings...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.orange.shade50,
          child: Row(
            children: [
              const Icon(Icons.security, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusText,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (_debugInfo.isNotEmpty)
                      Text(
                        _debugInfo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: WebViewWidget(controller: _controller),
        ),
      ],
    );
  }
}
