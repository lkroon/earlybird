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
  static const _maxPollAttempts = 20;
  static const _pollInterval = Duration(milliseconds: 500);

  static const _extractionJs = '''
(function() {
  var links = document.querySelectorAll('a[href*="/detail/"]');
  if (links.length === 0) return JSON.stringify([]);
  var seen = {};
  var results = [];
  for (var i = 0; i < links.length; i++) {
    var link = links[i];
    var href = link.getAttribute('href');
    if (!href || seen[href]) continue;
    seen[href] = true;
    var url = href.startsWith('http') ? href : 'https://www.funda.nl' + href;
    var heading = link.querySelector('h1, h2, h3, h4');
    var title = heading ? heading.textContent.trim() : link.textContent.trim();
    if (!title || title.length > 200) {
      title = title ? title.substring(0, 200) : '';
    }
    var card = link.closest('[data-test-id], [class*="search-result"], [class*="listing"]');
    var content = '';
    if (card) {
      var texts = card.querySelectorAll('span, p, li');
      var parts = [];
      for (var j = 0; j < texts.length && parts.length < 5; j++) {
        var t = texts[j].textContent.trim();
        if (t && t !== title && t.length > 2 && t.length < 100) {
          parts.push(t);
        }
      }
      content = parts.join(' · ');
    }
    var img = '';
    var imgEl = card ? card.querySelector('img[src*="cloud.funda"], img[src*="funda"]') : null;
    if (!imgEl && card) imgEl = card.querySelector('img[src]:not([src*="logo"])');
    if (imgEl) img = imgEl.getAttribute('src') || '';
    results.push({title: title, content: content, url: url, image: img});
  }
  return JSON.stringify(results);
})()
''';

  static const _checkListingsJs = '''
(function() {
  var links = document.querySelectorAll('a[href*="/detail/"]');
  return links.length;
})()
''';

  @override
  void initState() {
    super.initState();
    final baseUrl = Uri.parse(widget.url).origin;
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

    if (titleStr.contains(widget.botProtectionPageTitle)) {
      setState(() => _phase = _Phase.solvingCaptcha);
      return;
    }

    if (_phase == _Phase.solvingCaptcha) {
      setState(() => _phase = _Phase.loadingSearch);
      await Future.delayed(const Duration(milliseconds: 500));
      await _controller.loadRequest(Uri.parse(widget.url));
      return;
    }

    if (_phase == _Phase.loadingSearch) {
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
      final countResult =
          await _controller.runJavaScriptReturningResult(_checkListingsJs);
      final count = int.tryParse(countResult.toString()) ?? 0;

      if (count > 0) {
        _pollTimer?.cancel();
        await _extractData();
      } else if (_pollAttempts >= _maxPollAttempts) {
        _pollTimer?.cancel();
        await _extractData();
      }
    } catch (e) {
      if (_pollAttempts >= _maxPollAttempts) {
        _pollTimer?.cancel();
        debugPrint('WebView polling error: $e');
        widget.onError();
      }
    }
  }

  Future<void> _extractData() async {
    if (_phase == _Phase.done) return;
    _phase = _Phase.done;

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
      widget.onDataExtracted(headings);
    } catch (e) {
      debugPrint('WebView extraction error: $e');
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
                child: Text(
                  _statusText,
                  style: const TextStyle(fontSize: 14),
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
