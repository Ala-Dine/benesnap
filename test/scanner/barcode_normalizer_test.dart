import 'package:benesnap/services/scanner/barcode_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarcodeNormalizer', () {
    test('trims surrounding whitespace', () {
      expect(
        BarcodeNormalizer.normalize('  5901234123457 \n'),
        '5901234123457',
      );
    });

    test('uppercases the payload', () {
      expect(BarcodeNormalizer.normalize('ab12cd'), 'AB12CD');
    });

    test('reduces a URL to its last path segment', () {
      expect(
        BarcodeNormalizer.normalize('https://shop.example/products/AB12CD'),
        'AB12CD',
      );
    });

    test('ignores a trailing slash when taking the last segment', () {
      expect(
        BarcodeNormalizer.normalize('https://shop.example/p/ab12cd/'),
        'AB12CD',
      );
    });

    test('drops the query string along with the rest of the URL', () {
      expect(
        BarcodeNormalizer.normalize('https://shop.example/p/AB12CD?utm=qr'),
        'AB12CD',
      );
    });

    test('keeps a bare numeric EAN untouched', () {
      expect(BarcodeNormalizer.normalize('5901234123457'), '5901234123457');
    });

    test('keeps a code containing a colon that is not a URL', () {
      expect(BarcodeNormalizer.normalize('lot:4471'), 'LOT:4471');
    });

    test('falls back to the whole payload for a URL with no path', () {
      expect(
        BarcodeNormalizer.normalize('https://shop.example'),
        'HTTPS://SHOP.EXAMPLE',
      );
    });

    test('returns empty for a blank payload', () {
      expect(BarcodeNormalizer.normalize('   '), '');
    });
  });
}
