import 'dart:async';

import 'package:flutter/services.dart';

import 'barcode_normalizer.dart';
import 'scan_event.dart';

/// Listens for a USB keyboard-wedge (HID) barcode/QR scanner.
///
/// Such a scanner types the scanned code as a burst of very fast keystrokes and
/// finishes with Enter. There is no way to tell it apart from a keyboard at the
/// device level, so the burst is identified by *timing*: characters arriving
/// closer together than [maxKeyInterval] are machine-typed, anything slower is
/// a human at the keyboard and resets the buffer.
///
/// The handler registered with [HardwareKeyboard] **always returns false**, so
/// text fields, shortcuts and focus traversal keep working normally while the
/// listener is attached.
class BarcodeScannerService {
  BarcodeScannerService({
    this.maxKeyInterval = const Duration(milliseconds: 60),
    this.staleBufferTimeout = const Duration(milliseconds: 400),
    this.minCodeLength = 4,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Largest gap between two keystrokes that still counts as machine input.
  /// Tune against real hardware with the Ctrl+Shift+D debug screen.
  final Duration maxKeyInterval;

  /// A partial buffer is discarded after this much silence.
  final Duration staleBufferTimeout;

  /// Bursts shorter than this are ignored — they are almost always stray
  /// keypresses rather than a real barcode.
  final int minCodeLength;

  /// Injected clock. Tests drive synthetic timings through this rather than
  /// sleeping.
  final DateTime Function() _now;

  final _scans = StreamController<ScanResult>.broadcast();
  final _keystrokes = StreamController<KeystrokeSample>.broadcast();

  final StringBuffer _buffer = StringBuffer();
  DateTime? _lastKeyAt;
  DateTime? _burstStartedAt;
  Timer? _staleTimer;
  bool _attached = false;

  /// Completed scans, already normalized.
  Stream<ScanResult> get scans => _scans.stream;

  /// Every observed keystroke with its inter-key gap. Feeds the debug screen.
  Stream<KeystrokeSample> get keystrokes => _keystrokes.stream;

  /// While false, keystrokes are ignored entirely.
  ///
  /// Read-only: suppression is reference-counted through [suspend] rather
  /// than assigned, because more than one screen can want it off at once.
  bool get enabled => _suspensions == 0;

  int _suspensions = 0;

  /// Stops this service broadcasting scans until the returned callback runs.
  ///
  /// The admin add/edit form holds one of these for as long as it is open,
  /// so typing or scanning a barcode into its own field isn't also picked up
  /// as a catalogue lookup somewhere else. It is counted rather than a plain
  /// flag because the form can stack a second copy of itself (editing the
  /// product a duplicate barcode collides with): a bare `enabled = true` in
  /// the inner one's dispose would un-suppress while the outer one is still
  /// open.
  ///
  /// Calling the returned callback more than once is harmless.
  VoidCallback suspend() {
    _suspensions++;
    var released = false;
    return () {
      if (released) return;
      released = true;
      _suspensions--;
    };
  }

  /// Characters buffered so far. Exposed for the debug screen.
  String get buffer => _buffer.toString();

  void attach() {
    if (_attached) return;
    HardwareKeyboard.instance.addHandler(handleKeyEvent);
    _attached = true;
  }

  void detach() {
    if (!_attached) return;
    HardwareKeyboard.instance.removeHandler(handleKeyEvent);
    _attached = false;
  }

  /// Handles one key event.
  ///
  /// Always returns false so the event continues to the rest of the app. Called
  /// directly by tests, which is why it is public.
  bool handleKeyEvent(KeyEvent event) {
    if (!enabled || event is! KeyDownEvent) return false;

    final at = _now();
    _discardIfStale(at);
    final gap = _lastKeyAt == null ? Duration.zero : at.difference(_lastKeyAt!);

    if (_isTerminator(event.logicalKey)) {
      _recordKeystroke(_terminatorLabel(event.logicalKey), at, gap: gap);
      _emit(at);
      return false;
    }

    final character = event.character;
    if (character == null || character.isEmpty || character.length > 1) {
      return false;
    }
    // Control characters (including the \n some platforms attach to Enter)
    // are never part of a barcode payload.
    if (character.codeUnitAt(0) < 0x20) return false;

    // Too slow to be a machine: this is a person typing, so the burst so far
    // was not a scan. Start a fresh buffer from this character.
    if (_lastKeyAt != null && gap > maxKeyInterval) {
      _reset();
    }

    _burstStartedAt ??= at;
    _buffer.write(character);
    _recordKeystroke(character, at, gap: gap);
    _restartStaleTimer();

    return false;
  }

  void _emit(DateTime at) {
    final raw = _buffer.toString();
    final startedAt = _burstStartedAt;
    _reset();

    if (raw.length < minCodeLength) return;

    final code = BarcodeNormalizer.normalize(raw);
    if (code.isEmpty) return;

    _scans.add(
      ScanResult(
        code: code,
        rawCode: raw,
        keystrokes: raw.length,
        duration: startedAt == null ? Duration.zero : at.difference(startedAt),
      ),
    );
  }

  /// Backstop for the stale timer: if the app was busy and the timer did not
  /// fire, drop a buffer that has clearly gone cold before appending to it.
  void _discardIfStale(DateTime at) {
    final last = _lastKeyAt;
    if (last != null && at.difference(last) > staleBufferTimeout) _reset();
  }

  void _recordKeystroke(
    String character,
    DateTime at, {
    Duration gap = Duration.zero,
  }) {
    _lastKeyAt = at;
    _keystrokes.add(KeystrokeSample(character: character, gap: gap, at: at));
  }

  void _restartStaleTimer() {
    _staleTimer?.cancel();
    _staleTimer = Timer(staleBufferTimeout, _reset);
  }

  void _reset() {
    _buffer.clear();
    _lastKeyAt = null;
    _burstStartedAt = null;
    _staleTimer?.cancel();
    _staleTimer = null;
  }

  static bool _isTerminator(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.tab;

  static String _terminatorLabel(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.tab) return 'Tab';
    if (key == LogicalKeyboardKey.numpadEnter) return 'NumpadEnter';
    return 'Enter';
  }

  void dispose() {
    detach();
    _staleTimer?.cancel();
    _scans.close();
    _keystrokes.close();
  }
}
