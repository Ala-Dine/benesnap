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
                    size: 66,
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
/// with a scan frame. Reuses the exact bracket geometry from the app's own
/// icon (see windows/runner/resources/app_icon.ico), just with barcode bars
/// where that icon has a bottle, so the two stay visually consistent.
class _BarcodeFrameIcon extends StatelessWidget {
  const _BarcodeFrameIcon({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BarcodeFramePainter(color: color),
    );
  }
}

class _BarcodeFramePainter extends CustomPainter {
  const _BarcodeFramePainter({required this.color});

  final Color color;

  // A 200x200 design space — matching the app icon's own viewBox — so the
  // bracket arm length, corner radius and stroke width scale together the
  // same way they do there.
  static const _designSize = 200.0;

  static const _barLefts = [
    63.25,
    72.25,
    79.75,
    90.25,
    97.75,
    106.75,
    114.25,
    124.75,
    132.25,
  ];
  static const _barWidths = [4.5, 3.0, 6.0, 3.0, 4.5, 3.0, 6.0, 3.0, 4.5];
  static const _barTop = 72.0;
  static const _barHeight = 56.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _designSize, size.height / _designSize);

    final framePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    for (final bracket in _brackets) {
      canvas.drawPath(bracket, framePaint);
    }

    final barPaint = Paint()..color = color;
    for (var i = 0; i < _barLefts.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(_barLefts[i], _barTop, _barWidths[i], _barHeight),
        barPaint,
      );
    }
  }

  static final List<Path> _brackets = [
    // Top-left
    Path()
      ..moveTo(34, 68)
      ..lineTo(34, 47)
      ..arcToPoint(const Offset(47, 34), radius: const Radius.circular(13))
      ..lineTo(68, 34),
    // Top-right
    Path()
      ..moveTo(132, 34)
      ..lineTo(153, 34)
      ..arcToPoint(const Offset(166, 47), radius: const Radius.circular(13))
      ..lineTo(166, 68),
    // Bottom-left
    Path()
      ..moveTo(34, 132)
      ..lineTo(34, 153)
      ..arcToPoint(
        const Offset(47, 166),
        radius: const Radius.circular(13),
        clockwise: false,
      )
      ..lineTo(68, 166),
    // Bottom-right
    Path()
      ..moveTo(166, 132)
      ..lineTo(166, 153)
      ..arcToPoint(const Offset(153, 166), radius: const Radius.circular(13))
      ..lineTo(132, 166),
  ];

  @override
  bool shouldRepaint(covariant _BarcodeFramePainter oldDelegate) =>
      oldDelegate.color != color;
}
