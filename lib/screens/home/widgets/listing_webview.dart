import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void _log(String msg) {
  if (kDebugMode) debugPrint(msg);
}

class ListingWebView extends StatefulWidget {
  final String url;
  final String botProtectionPageTitle;
  final void Function(List<Map<String, String>> headings) onDataExtracted;
  final void Function(String details) onError;

  const ListingWebView({
    super.key,
    required this.url,
    required this.botProtectionPageTitle,
    required this.onDataExtracted,
    required this.onError,
  });

  @override
  State<ListingWebView> createState() => _ListingWebViewState();
}

enum _Phase { loading, captcha, polling, done }

class _ListingWebViewState extends State<ListingWebView> {
  late final WebViewController _controller;
  _Phase _phase = _Phase.loading;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  String _debugInfo = '';
  static const _maxPollAttempts = 30;
  static const _pollInterval = Duration(milliseconds: 1000);

  static const _extractionJs = '''
(function() {
  var results = [];
  var seen = {};

  var links = document.querySelectorAll('a[href]');
  for (var i = 0; i < links.length; i++) {
    var link = links[i];
    var href = link.getAttribute('href');
    if (!href || seen[href]) continue;
    if (href.indexOf('/detail/') === -1) continue;
    seen[href] = true;
    var url = href.startsWith('http') ? href : 'https://www.funda.nl' + href;
    var title = '';
    var heading = link.querySelector('h1, h2, h3, h4, h5');
    if (heading) {
      title = heading.textContent.trim();
    } else {
      var textNodes = link.textContent.trim();
      title = textNodes.split('\\n').filter(function(s) { return s.trim().length > 3; })[0] || '';
      title = title.trim();
    }
    if (!title || title.length < 3) continue;
    if (title.length > 200) title = title.substring(0, 200);
    var card = link.closest('[data-test-id], [class*="search-result"], [class*="listing"], [class*="card"], li, article, section');
    var content = '';
    if (card) {
      var texts = card.querySelectorAll('span, p, li');
      var parts = [];
      for (var j = 0; j < texts.length && parts.length < 5; j++) {
        var t = texts[j].textContent.trim();
        if (t && t !== title && t.length > 2 && t.length < 100 && parts.indexOf(t) === -1) {
          parts.push(t);
        }
      }
      content = parts.join(' | ');
    }
    var img = '';
    var imgEl = card ? card.querySelector('img[src*="cloud.funda"], img[src*="funda"]') : null;
    if (!imgEl && card) imgEl = card.querySelector('img[src]:not([src*="logo"]):not([src*="svg"])');
    if (!imgEl) imgEl = link.querySelector('img[src]');
    if (imgEl) img = imgEl.getAttribute('src') || imgEl.getAttribute('data-src') || '';
    results.push({title: title, content: content, url: url, image: img});
  }
  return JSON.stringify(results);
})()
''';

  static const _diagnosticJs = '''
(function() {
  var info = {};
  info.title = document.title;
  info.url = window.location.href;
  info.allLinks = document.querySelectorAll('a').length;
  info.detailLinks = document.querySelectorAll('a[href*="/detail/"]').length;
  info.imgs = document.querySelectorAll('img').length;
  info.bodyLen = document.body ? document.body.innerHTML.length : 0;
  var hrefs = [];
  var all = document.querySelectorAll('a[href]');
  for (var i = 0; i < Math.min(all.length, 15); i++) {
    hrefs.push(all[i].getAttribute('href'));
  }
  info.hrefs = hrefs;
  return JSON.stringify(info);
})()
''';

  @override
  void initState() {
    super.initState();
    _log('[WebView] Loading search URL directly: ${widget.url}');
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: _onPageFinished,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
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
    if (!mounted) return;

    final titleStr = title.toString().replaceAll('"', '');
    _log('[WebView] Page finished: $url | title: "$titleStr" | '
        'phase: $_phase');

    if (titleStr.contains(widget.botProtectionPageTitle)) {
      setState(() {
        _phase = _Phase.captcha;
        _debugInfo = 'Captcha detected - solve to continue';
      });
      return;
    }

    if (_phase != _Phase.polling && _phase != _Phase.done) {
      _log('[WebView] Page loaded, starting DOM polling');
      setState(() => _phase = _Phase.polling);
      _startPolling();
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

    try {
      final diagResult =
          await _controller.runJavaScriptReturningResult(_diagnosticJs);
      if (!mounted) return;

      final diagStr = _cleanJsResult(diagResult.toString());
      _log('[WebView] Poll $_pollAttempts: $diagStr');

      final diag = json.decode(diagStr) as Map<String, dynamic>;
      final detailLinks = diag['detailLinks'] as int? ?? 0;
      final allLinks = diag['allLinks'] as int? ?? 0;
      final bodyLen = diag['bodyLen'] as int? ?? 0;
      final pageUrl = diag['url'] as String? ?? '';

      setState(() {
        _debugInfo = 'Poll $_pollAttempts/$_maxPollAttempts | '
            'Links: $allLinks | Detail: $detailLinks | '
            'Body: ${bodyLen ~/ 1024}kb';
      });

      if (detailLinks > 0) {
        _pollTimer?.cancel();
        _log('[WebView] Found $detailLinks detail links, extracting');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        await _extractData();
      } else if (_pollAttempts >= _maxPollAttempts) {
        _pollTimer?.cancel();
        final hrefs = diag['hrefs'] as List<dynamic>? ?? [];
        _log('[WebView] Max polls reached. URL: $pageUrl');
        _log('[WebView] Sample hrefs: $hrefs');
        widget.onError(
          'No /detail/ links found after ${_maxPollAttempts}s. '
          'Page: $pageUrl | Links: $allLinks | Detail: $detailLinks | '
          'Sample: ${hrefs.take(5).join(", ")}',
        );
      }
    } catch (e) {
      _log('[WebView] Poll $_pollAttempts error: $e');
      if (!mounted) return;
      setState(() {
        _debugInfo = 'Poll $_pollAttempts error: $e';
      });
      if (_pollAttempts >= _maxPollAttempts) {
        _pollTimer?.cancel();
        widget.onError('Polling failed: $e');
      }
    }
  }

  Future<void> _extractData() async {
    if (_phase == _Phase.done) return;
    setState(() => _phase = _Phase.done);

    try {
      final result =
          await _controller.runJavaScriptReturningResult(_extractionJs);
      if (!mounted) return;

      final cleaned = _cleanJsResult(result.toString());
      _log('[WebView] Raw extraction (first 200): '
          '${cleaned.substring(0, cleaned.length.clamp(0, 200))}');
      final List<dynamic> parsed = json.decode(cleaned);
      final headings =
          parsed.map((item) => Map<String, String>.from(item as Map)).toList();
      _log('[WebView] Extracted ${headings.length} listings');
      if (headings.isNotEmpty) {
        _log('[WebView] First: ${headings.first}');
      }
      widget.onDataExtracted(headings);
    } catch (e) {
      _log('[WebView] Extraction error: $e');
      if (!mounted) return;
      widget.onError('Extraction parse error: $e');
    }
  }

  String _cleanJsResult(String raw) {
    // runJavaScriptReturningResult wraps JS string results in quotes with
    // escaped content. Use json.decode to properly unescape the outer layer.
    if (raw.startsWith('"') && raw.endsWith('"')) {
      try {
        final decoded = json.decode(raw);
        if (decoded is String) return decoded;
      } catch (_) {}
    }
    return raw;
  }

  String get _statusText {
    switch (_phase) {
      case _Phase.loading:
        return 'Loading search page...';
      case _Phase.captcha:
        return 'Solve the verification to continue.';
      case _Phase.polling:
        return 'Waiting for listings to render...';
      case _Phase.done:
        return 'Extracting listings...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.orange.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.security, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (kDebugMode && _debugInfo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _debugInfo,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontFamily: 'monospace',
                    ),
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
