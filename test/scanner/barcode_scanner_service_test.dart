import 'package:benesnap/services/scanner/barcode_scanner_service.dart';
import 'package:benesnap/services/scanner/scan_event.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drives the service with a controllable clock so tests describe timings
/// instead of sleeping for them.
class _FakeClock {
  DateTime _now = DateTime.utc(2026, 1, 1);

  DateTime call() => _now;

  void advance(Duration by) => _now = _now.add(by);
}

void main() {
  late _FakeClock clock;
  late BarcodeScannerService scanner;
  late List<ScanResult> emitted;

  setUp(() {
    clock = _FakeClock();
    scanner = BarcodeScannerService(now: clock.call);
    emitted = [];
    scanner.scans.listen(emitted.add);
  });

  tearDown(() => scanner.dispose());

  /// Types [text] with [gap] between each character, then optionally a
  /// terminator. Mirrors what the HID scanner does to the keyboard queue.
  void type(String text, {required Duration gap, LogicalKeyboardKey? then}) {
    for (final char in text.split('')) {
      clock.advance(gap);
      scanner.handleKeyEvent(_downEvent(character: char));
    }
    if (then != null) {
      clock.advance(gap);
      scanner.handleKeyEvent(_downEvent(logicalKey: then));
    }
  }

  // Streams are async, so let the microtask queue drain before asserting.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('machine-speed input', () {
    test('emits the code when Enter arrives', () async {
      type(
        '5901234123457',
        gap: const Duration(milliseconds: 8),
        then: LogicalKeyboardKey.enter,
      );
      await settle();

      expect(emitted, hasLength(1));
      expect(emitted.single.code, '5901234123457');
      expect(emitted.single.keystrokes, 13);
    });

    test('numpad Enter also terminates the burst', () async {
      type(
        'ABC123',
        gap: const Duration(milliseconds: 5),
        then: LogicalKeyboardKey.numpadEnter,
      );
      await settle();

      expect(emitted.single.code, 'ABC123');
    });

    test('Tab also terminates the burst', () async {
      type(
        'ABC123',
        gap: const Duration(milliseconds: 5),
        then: LogicalKeyboardKey.tab,
      );
      await settle();

      expect(emitted.single.code, 'ABC123');
    });

    test('normalizes the payload before emitting', () async {
      type(
        'https://shop.example/p/ab12cd',
        gap: const Duration(milliseconds: 4),
        then: LogicalKeyboardKey.enter,
      );
      await settle();

      expect(emitted.single.code, 'AB12CD');
      expect(emitted.single.rawCode, 'https://shop.example/p/ab12cd');
    });

    test('reports how long the burst took', () async {
      type(
        '12345',
        gap: const Duration(milliseconds: 10),
        then: LogicalKeyboardKey.enter,
      );
      await settle();

      // 4 gaps between the 5 characters, plus one before Enter.
      expect(emitted.single.duration, const Duration(milliseconds: 50));
    });
  });

  group('human-speed input', () {
    test('does not emit when every gap exceeds the threshold', () async {
      type(
        '5901234123457',
        gap: const Duration(milliseconds: 120),
        then: LogicalKeyboardKey.enter,
      );
      await settle();

      expect(emitted, isEmpty);
    });

    test('a slow gap mid-burst discards what came before it', () async {
      // Machine-fast prefix...
      type('9999', gap: const Duration(milliseconds: 5));
      // ...then a human-length pause, then more fast characters.
      type(
        'ABCD',
        gap: const Duration(milliseconds: 200),
        then: LogicalKeyboardKey.enter,
      );
      await settle();

      // Every 200ms gap resets, so only the final 'D' is left in the buffer —
      // far too short to emit.
      expect(emitted, isEmpty);
    });

    test('a fast burst still registers after a human typed slowly', () async {
      type('hi', gap: const Duration(milliseconds: 300));
      // The assistant stops typing before reaching for the scanner.
      clock.advance(const Duration(milliseconds: 500));
      type(
        '5901234123457',
        gap: const Duration(milliseconds: 6),
        then: LogicalKeyboardKey.enter,
      );
      await settle();

      expect(emitted.single.code, '5901234123457');
    });
  });

  group('rejected input', () {
    test('a code shorter than minCodeLength is dropped', () async {
      type(
        'AB1',
        gap: const Duration(milliseconds: 5),
        then: LogicalKeyboardKey.enter,
      );
      await settle();

      expect(emitted, isEmpty);
    });

    test('a code exactly at minCodeLength is kept', () async {
      type(
        'AB12',
        gap: const Duration(milliseconds: 5),
        then: LogicalKeyboardKey.enter,
      );
      await settle();

      expect(emitted.single.code, 'AB12');
    });

    test('Enter on an empty buffer emits nothing', () async {
      scanner.handleKeyEvent(_downEvent(logicalKey: LogicalKeyboardKey.enter));
      await settle();

      expect(emitted, isEmpty);
    });

    test(
      'a buffer left stale is discarded before the next character',
      () async {
        type('5901', gap: const Duration(milliseconds: 5));
        // Longer than staleBufferTimeout: the counter has gone quiet.
        clock.advance(const Duration(milliseconds: 900));
        type(
          '234123457',
          gap: const Duration(milliseconds: 5),
          then: LogicalKeyboardKey.enter,
        );
        await settle();

        expect(emitted.single.code, '234123457');
      },
    );
  });

  group('enabled flag', () {
    test('suppresses emission while disabled', () async {
      scanner.enabled = false;
      type(
        '5901234123457',
        gap: const Duration(milliseconds: 5),
        then: LogicalKeyboardKey.enter,
      );
      await settle();

      expect(emitted, isEmpty);
    });

    test('resumes cleanly once re-enabled', () async {
      scanner.enabled = false;
      type(
        'IGNORED',
        gap: const Duration(milliseconds: 5),
        then: LogicalKeyboardKey.enter,
      );
      scanner.enabled = true;
      type(
        '5901234123457',
        gap: const Duration(milliseconds: 5),
        then: LogicalKeyboardKey.enter,
      );
      await settle();

      expect(emitted.single.code, '5901234123457');
    });
  });

  group('key handling contract', () {
    test('never consumes an event, so text fields keep working', () {
      final results = <bool>[
        scanner.handleKeyEvent(_downEvent(character: 'A')),
        scanner.handleKeyEvent(
          _downEvent(logicalKey: LogicalKeyboardKey.enter),
        ),
        scanner.handleKeyEvent(_downEvent(logicalKey: LogicalKeyboardKey.tab)),
        scanner.handleKeyEvent(_upEvent()),
      ];

      expect(results, everyElement(isFalse));
    });

    test('ignores key-up events', () async {
      for (var i = 0; i < 13; i++) {
        clock.advance(const Duration(milliseconds: 5));
        scanner.handleKeyEvent(_upEvent());
      }
      scanner.handleKeyEvent(_downEvent(logicalKey: LogicalKeyboardKey.enter));
      await settle();

      expect(emitted, isEmpty);
    });

    test('exposes the in-progress buffer for diagnostics', () {
      type('590', gap: const Duration(milliseconds: 5));

      expect(scanner.buffer, '590');
    });
  });

  group('configurable thresholds', () {
    test('a slower maxKeyInterval accepts slower hardware', () async {
      final slowClock = _FakeClock();
      final slow = BarcodeScannerService(
        maxKeyInterval: const Duration(milliseconds: 150),
        now: slowClock.call,
      );
      addTearDown(slow.dispose);
      final slowEmitted = <ScanResult>[];
      slow.scans.listen(slowEmitted.add);

      for (final char in '5901234'.split('')) {
        slowClock.advance(const Duration(milliseconds: 120));
        slow.handleKeyEvent(_downEvent(character: char));
      }
      slow.handleKeyEvent(_downEvent(logicalKey: LogicalKeyboardKey.enter));
      await settle();

      // 120ms would have been rejected by the 60ms default.
      expect(slowEmitted.single.code, '5901234');
    });

    test('a higher minCodeLength rejects a short code', () async {
      final strictClock = _FakeClock();
      final strict = BarcodeScannerService(
        minCodeLength: 8,
        now: strictClock.call,
      );
      addTearDown(strict.dispose);
      final strictEmitted = <ScanResult>[];
      strict.scans.listen(strictEmitted.add);

      for (final char in 'ABC123'.split('')) {
        strictClock.advance(const Duration(milliseconds: 5));
        strict.handleKeyEvent(_downEvent(character: char));
      }
      strict.handleKeyEvent(_downEvent(logicalKey: LogicalKeyboardKey.enter));
      await settle();

      expect(strictEmitted, isEmpty);
    });
  });
}

KeyDownEvent _downEvent({String? character, LogicalKeyboardKey? logicalKey}) {
  return KeyDownEvent(
    physicalKey: PhysicalKeyboardKey.keyA,
    logicalKey: logicalKey ?? LogicalKeyboardKey.keyA,
    character: logicalKey == null ? character : null,
    timeStamp: Duration.zero,
  );
}

KeyUpEvent _upEvent() {
  return const KeyUpEvent(
    physicalKey: PhysicalKeyboardKey.keyA,
    logicalKey: LogicalKeyboardKey.keyA,
    timeStamp: Duration.zero,
  );
}
