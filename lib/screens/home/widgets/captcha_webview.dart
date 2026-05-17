import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../services/captcha_session_service.dart';

class CaptchaWebView extends StatefulWidget {
  final CaptchaSessionService captchaSession;
  final String domain;
  final String botProtectionPageTitle;
  final VoidCallback onSolved;

  const CaptchaWebView({
    super.key,
    required this.captchaSession,
    required this.domain,
    required this.botProtectionPageTitle,
    required this.onSolved,
  });

  @override
  State<CaptchaWebView> createState() => _CaptchaWebViewState();
}

class _CaptchaWebViewState extends State<CaptchaWebView> {
  late final WebViewController _controller;
  bool _solving = true;

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
      ..loadRequest(Uri.parse(widget.domain));
  }

  Future<void> _onPageFinished(String url) async {
    final title = await _controller.runJavaScriptReturningResult(
      'document.title',
    );
    final titleStr = title.toString().replaceAll('"', '');
    if (!titleStr.contains(widget.botProtectionPageTitle) &&
        titleStr.isNotEmpty) {
      await _completeCaptcha();
    }
  }

  Future<void> _completeCaptcha() async {
    if (!_solving) return;
    _solving = false;
    await Future.delayed(const Duration(milliseconds: 500));

    final cookieString = await _controller.runJavaScriptReturningResult(
      'document.cookie',
    );
    final cookies = _parseCookies(cookieString.toString());
    widget.captchaSession.setSession(widget.domain, cookies);

    if (mounted) {
      widget.onSolved();
    }
  }

  Map<String, String> _parseCookies(String raw) {
    final cleaned = raw.replaceAll('"', '');
    if (cleaned.isEmpty) return {};
    final cookies = <String, String>{};
    for (final pair in cleaned.split('; ')) {
      final idx = pair.indexOf('=');
      if (idx > 0) {
        cookies[pair.substring(0, idx)] = pair.substring(idx + 1);
      }
    }
    return cookies;
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
              const Expanded(
                child: Text(
                  'Solve the verification to continue browsing listings.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: _completeCaptcha,
                child: const Text('Done'),
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
