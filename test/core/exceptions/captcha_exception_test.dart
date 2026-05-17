import 'package:flutter_test/flutter_test.dart';
import 'package:earlybird/core/exceptions/captcha_exception.dart';

void main() {
  group('CaptchaException', () {
    test('has default message', () {
      final exception = CaptchaException();
      expect(exception.message, 'Captcha verification required');
      expect(exception.toString(), 'Captcha verification required');
    });

    test('accepts custom message', () {
      final exception = CaptchaException('Custom bot message');
      expect(exception.message, 'Custom bot message');
      expect(exception.toString(), 'Custom bot message');
    });

    test('implements Exception', () {
      final exception = CaptchaException();
      expect(exception, isA<Exception>());
    });

    test('can be caught with on CaptchaException', () {
      var caught = false;
      try {
        throw CaptchaException();
      } on CaptchaException {
        caught = true;
      }
      expect(caught, true);
    });
  });
}
