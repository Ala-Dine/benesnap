import 'package:flutter/foundation.dart';

/// A single keystroke observed by the scanner listener, with the gap since the
/// previous one. Surfaced by the debug screen so the shop can tune thresholds
/// against their actual hardware.
@immutable
class KeystrokeSample {
  const KeystrokeSample({
    required this.character,
    required this.gap,
    required this.at,
  });

  /// The printable character, or a label like `Enter` for terminators.
  final String character;

  /// Time since the previous keystroke. Zero for the first of a burst.
  final Duration gap;

  final DateTime at;
}

/// A completed scan: a terminator arrived and the buffer passed the length
/// check.
@immutable
class ScanResult {
  const ScanResult({
    required this.code,
    required this.rawCode,
    required this.keystrokes,
    required this.duration,
  });

  /// Normalized code, ready for a `products.barcode` lookup.
  final String code;

  /// Exactly what the scanner typed, before normalization.
  final String rawCode;

  /// How many characters made up the burst.
  final int keystrokes;

  /// Wall time from first character to terminator.
  final Duration duration;

  @override
  String toString() =>
      'ScanResult($code, $keystrokes keys in ${duration.inMilliseconds}ms)';
}
