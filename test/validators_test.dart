import 'package:flutter_test/flutter_test.dart';
import 'package:ink/utils/validators.dart';
import 'package:ink/services/search_service.dart';

void main() {
  group('UrlValidator.isLikelyUrl', () {
    test('recognizes full URLs', () {
      expect(UrlValidator.isLikelyUrl('https://example.com'), isTrue);
      expect(UrlValidator.isLikelyUrl('http://example.com/path?q=1'), isTrue);
    });

    test('recognizes bare domains', () {
      expect(UrlValidator.isLikelyUrl('example.com'), isTrue);
      expect(UrlValidator.isLikelyUrl('sub.example.co.uk/path'), isTrue);
    });

    test('recognizes localhost and IPs', () {
      expect(UrlValidator.isLikelyUrl('localhost:8080'), isTrue);
      expect(UrlValidator.isLikelyUrl('192.168.1.1'), isTrue);
    });

    test('rejects plain search queries', () {
      expect(UrlValidator.isLikelyUrl('best pizza near me'), isFalse);
      expect(UrlValidator.isLikelyUrl('flutter inappwebview'), isFalse);
    });
  });

  group('SearchService.resolveInput', () {
    final service = SearchService('https://searx.example/search?q=');

    test('passes through URLs unchanged (normalized)', () {
      expect(service.resolveInput('example.com'), 'https://example.com');
      expect(
        service.resolveInput('https://example.com'),
        'https://example.com',
      );
    });

    test('redirects search terms to SearXNG', () {
      final url = service.resolveInput('open source browsers');
      expect(url.startsWith('https://searx.example/search?q=open+source+browsers'), isTrue);
      expect(url.contains('categories=general'), isTrue);
    });
  });
}
