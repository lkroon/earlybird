import 'package:flutter_test/flutter_test.dart';
import 'package:earlybird/services/captcha_session_service.dart';

void main() {
  group('CaptchaSessionService', () {
    late CaptchaSessionService service;

    setUp(() {
      service = CaptchaSessionService();
    });

    group('hasValidSession', () {
      test('returns false when no session exists for domain', () {
        expect(service.hasValidSession('https://www.funda.nl'), false);
      });

      test('returns false for unknown domain', () {
        expect(service.hasValidSession('https://www.marktplaats.nl'), false);
      });

      test('returns true after setSession with cookies', () {
        service.setSession('https://www.funda.nl', {'_abck': 'abc123'});
        expect(service.hasValidSession('https://www.funda.nl'), true);
      });

      test('returns false after setSession with empty cookies', () {
        service.setSession('https://www.funda.nl', {});
        expect(service.hasValidSession('https://www.funda.nl'), false);
      });
    });

    group('cookieHeader', () {
      test('returns empty string when no session exists', () {
        expect(service.cookieHeader('https://www.funda.nl'), '');
      });

      test('returns formatted cookie header after setSession', () {
        service.setSession('https://www.funda.nl', {
          '_abck': 'value1',
          'bm_sz': 'value2',
        });
        final header = service.cookieHeader('https://www.funda.nl');
        expect(header, contains('_abck=value1'));
        expect(header, contains('bm_sz=value2'));
        expect(header, contains('; '));
      });

      test('returns single cookie without separator', () {
        service.setSession('https://www.funda.nl', {'_abck': 'value1'});
        expect(service.cookieHeader('https://www.funda.nl'), '_abck=value1');
      });
    });

    group('clearSession', () {
      test('does not throw when clearing non-existent session', () {
        expect(
          () => service.clearSession('https://www.funda.nl'),
          returnsNormally,
        );
      });

      test('removes session after clearing', () {
        service.setSession('https://www.funda.nl', {'_abck': 'abc123'});
        expect(service.hasValidSession('https://www.funda.nl'), true);

        service.clearSession('https://www.funda.nl');
        expect(service.hasValidSession('https://www.funda.nl'), false);
      });
    });

    group('domain isolation', () {
      test('sessions for different domains are independent', () {
        service.setSession('https://www.funda.nl', {'_abck': 'funda'});

        expect(service.hasValidSession('https://www.funda.nl'), true);
        expect(service.hasValidSession('https://www.marktplaats.nl'), false);
      });

      test('clearing one domain does not affect another', () {
        service.setSession('https://www.funda.nl', {'_abck': 'funda'});
        service.setSession('https://www.marktplaats.nl', {'sid': 'mp'});

        service.clearSession('https://www.funda.nl');

        expect(service.hasValidSession('https://www.funda.nl'), false);
        expect(service.hasValidSession('https://www.marktplaats.nl'), true);
      });
    });
  });
}
