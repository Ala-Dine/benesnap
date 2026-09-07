import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// A product photo, decoded at the size it is actually drawn.
///
/// Shop photos come straight off a phone: a 12MP JPEG decodes to roughly
/// 48MB of RGBA regardless of the ~230px grid cell it ends up in. A dozen of
/// those overrun Flutter's ImageCache, which then evicts and re-decodes them
/// on the next rebuild — the stutter you see scrolling the inventory or
/// typing in its search box. `cacheWidth` moves the downscale into the
/// decoder, so the cache holds thumbnails instead of originals.
///
/// The size comes from [LayoutBuilder] rather than a constant so each call
/// site stays honest as its layout changes; the longest side is used because
/// [BoxFit.cover] scales by whichever axis needs more pixels.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.file,
    this.brokenIconSize = 32,
    this.fillBrokenBackground = true,
  });

  final File file;

  /// Size of the broken-image icon shown when the file can't be read — the
  /// three call sites sit at different scales.
  final double brokenIconSize;

  /// Whether the broken-image fallback paints a panel behind itself. False
  /// where the surrounding container already provides one.
  final bool fillBrokenBackground;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final longestSide = math.max(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
        );
        final devicePixels =
            longestSide * MediaQuery.devicePixelRatioOf(context);

        return Image.file(
          file,
          fit: BoxFit.cover,
          // Unbounded on both axes: nothing to size the decode against, so
          // fall back to the full image rather than guess.
          cacheWidth: devicePixels > 0 ? devicePixels.round() : null,
          errorBuilder: (context, error, stack) {
            final icon = Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: brokenIconSize,
                color: tokens.muted,
              ),
            );
            return fillBrokenBackground
                ? ColoredBox(color: tokens.imagePanelBg, child: icon)
                : icon;
          },
        );
      },
    );
  }
}
