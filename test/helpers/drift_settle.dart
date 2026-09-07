import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tears the widget tree down and lets drift's live-query streams finish
/// their own cleanup before the test ends.
///
/// Any screen watching a drift stream (the inventory grid, the tag chips)
/// leaves a cleanup timer behind when its subscription is cancelled. The
/// test framework checks for pending timers the moment the test body
/// returns, and by then there is no pump left for that timer to run in — so
/// it reports "A Timer is still pending even after the widget tree was
/// disposed" and the run hangs on shutdown.
///
/// Call this at the end of any widget test whose screen reads a drift
/// stream. Tests that can avoid the stream entirely should prefer doing so —
/// see `staticHomeTextOverride`.
Future<void> disposeAndDrain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (var i = 0; i < 150; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}
