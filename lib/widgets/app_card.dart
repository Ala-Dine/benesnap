import 'package:flutter/material.dart';

import '../app/theme.dart';

/// The white rounded card used throughout the kiosk and admin screens.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: borderRadius ?? tokens.cardRadius,
        boxShadow: boxShadow ?? tokens.cardShadow,
      ),
      child: child,
    );
  }
}
