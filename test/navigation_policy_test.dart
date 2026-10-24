import 'package:flutter_test/flutter_test.dart';
import 'package:eltahi_demo/navigation_policy.dart';

void main() {
  test('Only the HTTPS website stays inside the app', () {
    expect(
      isWebsiteUrl(Uri.parse('https://www.eltahi.com/profile?id=7')),
      isTrue,
    );
    expect(isWebsiteUrl(Uri.parse('https://eltahi.com/')), isTrue);
    for (final url in [
      'http://eltahi.com/',
      'https://eltahi.com.evil.test/',
      'https://eltahi.com:8443/',
      'javascript:alert(1)',
      'file:///etc/passwd',
    ]) {
      expect(isWebsiteUrl(Uri.parse(url)), isFalse, reason: url);
    }
  });
  test('Only approved external schemes can open another app', () {
    expect(isExternalUrl(Uri.parse('https://example.com')), isTrue);
    expect(isExternalUrl(Uri.parse('mailto:hello@example.com')), isTrue);
    for (final url in [
      'intent://arbitrary',
      'javascript:alert(1)',
      'http://example.com',
      'file:///a',
    ]) {
      expect(isExternalUrl(Uri.parse(url)), isFalse, reason: url);
    }
  });
}
