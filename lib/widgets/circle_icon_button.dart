import 'package:flutter/material.dart';

import '../app/theme.dart';

/// The round icon button in a screen's top-left corner — back, settings,
/// the kiosk's account button.
///
/// Existed in four slightly different forms: a translucent-surface variant,
/// a bordered one, a shadowed one, and the kiosk's own. The differences were
/// all in the *backdrop*, never the button, so that is the only thing
/// callers vary; icon size and hit area come from here so a shop assistant
/// gets the same 40px target on every screen.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.background,
    this.border,
    this.shadow,
    this.iconSize = 19,
    this.diameter = 40,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  /// Defaults to the card surface.
  final Color? background;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
  final double iconSize;
  final double diameter;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? theme.colorScheme.surface,
        shape: BoxShape.circle,
        border: border,
        boxShadow: shadow,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: iconSize,
        tooltip: tooltip,
        color: iconColor,
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          fixedSize: Size(diameter, diameter),
        ),
      ),
    );
  }
}

/// The circular icon plaque at the top of the login, setup and kiosk
/// not-found cards.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.iconSize = 24});

  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.iconBadgeBg,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Icon(icon, size: iconSize, color: tokens.goldDeep),
      ),
    );
  }
}
