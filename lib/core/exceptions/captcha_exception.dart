class CaptchaException implements Exception {
  final String message;
  CaptchaException([this.message = 'Captcha verification required']);

  @override
  String toString() => message;
}
