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

class _CaptchaWebViewState extends State<CaptchaWebView> {
  late final WebViewController _controller;
  bool _extracted = false;
  bool _showingCaptcha = false;

  static const _extractionJs = '''
(function() {
  var headings = document.querySelectorAll('h1, h2, h3, h4');
  var results = [];
  for (var i = 0; i < headings.length; i++) {
    var h = headings[i];
    var text = h.textContent.trim();
    if (!text) continue;
    var link = h.querySelector('a[href]') || h.closest('a[href]');
    if (!link) {
      var innerHTML = h.innerHTML;
      var match = innerHTML.match(/href="([^"]+)"/);
      if (!match) continue;
      var href = match[1];
      if (href.indexOf('/detail/') === -1) continue;
      var url = href.startsWith('http') ? href : 'https://www.funda.nl' + href;
      var next = h.nextElementSibling;
      var content = next ? next.textContent.trim().substring(0, 200) : '';
      results.push({title: text, content: content, url: url, image: ''});
    } else {
      var href = link.getAttribute('href');
      if (href.indexOf('/detail/') === -1) continue;
      var url = href.startsWith('http') ? href : 'https://www.funda.nl' + href;
      var next = h.nextElementSibling;
      var content = next ? next.textContent.trim().substring(0, 200) : '';
      results.push({title: text, content: content, url: url, image: ''});
    }
  }
  return JSON.stringify(results);
})()
''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: _onPageFinished,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _onPageFinished(String url) async {
    if (_extracted) return;

    final title = await _controller.runJavaScriptReturningResult(
      'document.title',
    );
    final titleStr = title.toString().replaceAll('"', '');

    if (titleStr.contains(widget.botProtectionPageTitle)) {
      setState(() => _showingCaptcha = true);
      return;
    }

    if (_showingCaptcha || !titleStr.contains(widget.botProtectionPageTitle)) {
      await Future.delayed(const Duration(seconds: 1));
      await _extractData();
    }
  }

  Future<void> _extractData() async {
    if (_extracted) return;
    _extracted = true;

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
                  _showingCaptcha
                      ? 'Solve the verification to continue.'
                      : 'Loading listings via secure browser...',
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
