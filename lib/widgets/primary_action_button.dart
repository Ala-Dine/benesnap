import 'package:flutter/material.dart';

import '../app/theme.dart';

/// The app's main "do the thing" button: sign in, create the account, save
/// the product, save the settings.
///
/// Every one of those spent the same twenty lines spelling out the dark
/// button style, the 13px radius, and a spinner-or-label child. Sharing them
/// means the spinner is the same size and colour on all five, which by hand
/// it very nearly wasn't.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.fillWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Shows a spinner in place of the label. Also disables the button: every
  /// caller was doing that separately, and none of them wanted a button that
  /// could be pressed twice mid-save.
  final bool busy;

  /// Stretches to the available width, as the login and setup cards do.
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final button = ElevatedButton(
      onPressed: busy ? null : onPressed,
      style: AppTheme.darkButtonStyle(
        context,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.field),
      ),
      child: busy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : Text(label),
    );

    return fillWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
