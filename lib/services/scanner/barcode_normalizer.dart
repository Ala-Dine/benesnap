/// Turns a raw scanner payload into the canonical form stored in the
/// `products.barcode` column.
///
/// QR codes at the counter often encode a product URL rather than a bare code,
/// so a payload that parses as a URL is reduced to its last path segment.
abstract final class BarcodeNormalizer {
  static String normalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    return _lastPathSegmentOrNull(trimmed)?.toUpperCase() ??
        trimmed.toUpperCase();
  }

  /// Returns the final path segment when [value] is a URL that actually has
  /// one, otherwise null so the caller falls back to the whole payload.
  static String? _lastPathSegmentOrNull(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    return segments.last;
  }
}
