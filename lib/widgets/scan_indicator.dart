import 'package:flutter/material.dart';

import '../app/theme.dart';

enum ScanIndicatorStatus { listening, lookingUp }

/// The white scan card at the centre of the home screen.
///
/// Not a button in the interactive sense — a live status readout (scans come
/// from the hardware, not a click). Shows a spinner while a lookup is in
/// flight, otherwise sits still.
class ScanIndicator extends StatelessWidget {
  const ScanIndicator({super.key, required this.status});

  final ScanIndicatorStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final isListening = status == ScanIndicatorStatus.listening;

    return Container(
      width: 240,
      padding: const EdgeInsets.fromLTRB(0, 34, 0, 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(26)),
        boxShadow: tokens.prominentShadow,
      ),
      child: Center(
        child: isListening
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BarcodeFrameIcon(
                    width: 112,
                    height: 66,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'امسح الكود',
                    style: AppTheme.weighted(
                      theme.textTheme.headlineSmall,
                      FontWeight.w700,
                    ).copyWith(fontSize: 30),
                  ),
                ],
              )
            : const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
      ),
    );
  }
}

/// A barcode inside four viewfinder corner brackets.
///
/// Not a Material icon — nothing in Flutter's built-in set pairs a barcode
/// with a scan frame. Echoes the corner-bracket language of the app's own
/// icon (see windows/runner/resources/app_icon.ico), but wide rather than
/// square — a real barcode reads left to right, so the frame around it
/// should too — with taller, denser bars so it reads clearly as a barcode
/// at a glance rather than a handful of stray lines.
class _BarcodeFrameIcon extends StatelessWidget {
  const _BarcodeFrameIcon({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _BarcodeFramePainter(color: color),
    );
  }
}

class _BarcodeFramePainter extends CustomPainter {
  const _BarcodeFramePainter({required this.color});

  final Color color;

  // A 220x132 design space (5:3) — wide enough for the corner brackets to
  // read as a scan frame rather than a square, matched by the icon's own
  // rendered width/height so the scale below never distorts the strokes.
  static const _designWidth = 220.0;
  static const _designHeight = 132.0;

  // A denser, more irregular rhythm than a handful of even bars reads more
  // like an actual barcode. Uniform 6.0 gaps between them, centered in the
  // frame — see the _brackets corner math below for how the margins line up.
  static const _barWidths = [
    5.0,
    9.0,
    3.0,
    7.0,
    5.0,
    3.0,
    9.0,
    5.0,
    7.0,
    3.0,
    5.0,
    9.0,
    3.0,
  ];
  static const _barGap = 6.0;
  static const _barTop = 30.0;
  static const _barHeight = 72.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _designWidth, size.height / _designHeight);

    final framePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    for (final bracket in _brackets) {
      canvas.drawPath(bracket, framePaint);
    }

    final barPaint = Paint()..color = color;
    final totalBarWidth =
        _barWidths.reduce((a, b) => a + b) + _barGap * (_barWidths.length - 1);
    var left = (_designWidth - totalBarWidth) / 2;
    for (final width in _barWidths) {
      canvas.drawRect(
        Rect.fromLTWH(left, _barTop, width, _barHeight),
        barPaint,
      );
      left += width + _barGap;
    }
  }

  // Corner brackets for a margin of 18 (x) / 16 (y) inside the design space,
  // 10-radius rounded corners with a 16-long straight arm on each side —
  // the same bracket language as the app icon, just fitted to a wide
  // rectangle instead of a square.
  static final List<Path> _brackets = [
    // Top-left
    Path()
      ..moveTo(18, 42)
      ..lineTo(18, 26)
      ..arcToPoint(const Offset(28, 16), radius: const Radius.circular(10))
      ..lineTo(44, 16),
    // Top-right
    Path()
      ..moveTo(176, 16)
      ..lineTo(192, 16)
      ..arcToPoint(const Offset(202, 26), radius: const Radius.circular(10))
      ..lineTo(202, 42),
    // Bottom-left
    Path()
      ..moveTo(18, 90)
      ..lineTo(18, 106)
      ..arcToPoint(
        const Offset(28, 116),
        radius: const Radius.circular(10),
        clockwise: false,
      )
      ..lineTo(44, 116),
    // Bottom-right
    Path()
      ..moveTo(202, 90)
      ..lineTo(202, 106)
      ..arcToPoint(const Offset(192, 116), radius: const Radius.circular(10))
      ..lineTo(176, 116),
  ];

  @override
  bool shouldRepaint(covariant _BarcodeFramePainter oldDelegate) =>
      oldDelegate.color != color;
}
