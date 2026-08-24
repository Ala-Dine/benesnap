import 'package:flutter/material.dart';

/// A rounded-rect box with a dashed border, matching the mockups' "no image
/// yet" placeholder and the image drop zone.
class DashedBorderBox extends StatelessWidget {
  const DashedBorderBox({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.color,
    this.dashWidth = 6,
    this.gapWidth = 6,
    this.strokeWidth = 2,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color? color;
  final double dashWidth;
  final double gapWidth;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final borderColor = color ?? Theme.of(context).colorScheme.onSurface;

    return CustomPaint(
      painter: _DashedRRectPainter(
        color: borderColor,
        radius: borderRadius,
        dashWidth: dashWidth,
        gapWidth: gapWidth,
        strokeWidth: strokeWidth,
      ),
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.gapWidth,
    required this.strokeWidth,
  });

  final Color color;
  final BorderRadius radius;
  final double dashWidth;
  final double gapWidth;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = radius.toRRect(Offset.zero & size);
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.gapWidth != gapWidth ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
