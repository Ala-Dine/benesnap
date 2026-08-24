import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The diagonal two-tone hatch used as a "no photo yet" placeholder —
/// `repeating-linear-gradient(135deg, ...)` in the design. CSS's repeating
/// gradient tiles at a fixed pixel period regardless of the box size; a
/// plain [LinearGradient] stretches to fill its box instead, so this paints
/// the stripes directly to keep the period constant.
class StripedPlaceholder extends StatelessWidget {
  const StripedPlaceholder({
    super.key,
    required this.background,
    required this.stripe,
    this.label,
    this.labelStyle,
  });

  final Color background;
  final Color stripe;
  final String? label;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StripePainter(background: background, stripe: stripe),
      child: label == null
          ? null
          : Center(child: Text(label!, style: labelStyle)),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter({required this.background, required this.stripe});

  final Color background;
  final Color stripe;

  static const _stripeWidth = 8.0;
  static const _period = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 4);

    final paint = Paint()..color = stripe;
    // Oversized so the rotated bands still cover every corner.
    final span = size.width + size.height;
    for (var x = -span; x < span; x += _period) {
      canvas.drawRect(Rect.fromLTWH(x, -span, _stripeWidth, span * 2), paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StripePainter oldDelegate) =>
      oldDelegate.background != background || oldDelegate.stripe != stripe;
}
