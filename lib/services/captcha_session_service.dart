class CaptchaSessionService {
  final Map<String, _DomainSession> _sessions = {};
  static const _sessionDuration = Duration(minutes: 20);

  bool hasValidSession(String domain) {
    final session = _sessions[domain];
    if (session == null) return false;
    return session.cookies.isNotEmpty &&
        DateTime.now().difference(session.startedAt) < _sessionDuration;
  }

  String cookieHeader(String domain) {
    final session = _sessions[domain];
    if (session == null) return '';
    return session.cookies.entries
        .map((e) => '${e.key}=${e.value}')
        .join('; ');
  }

  void setSession(String domain, Map<String, String> cookies) {
    _sessions[domain] = _DomainSession(
      cookies: cookies,
      startedAt: DateTime.now(),
    );
  }

  void clearSession(String domain) {
    _sessions.remove(domain);
  }
}

class _DomainSession {
  final Map<String, String> cookies;
  final DateTime startedAt;

  _DomainSession({required this.cookies, required this.startedAt});
}
