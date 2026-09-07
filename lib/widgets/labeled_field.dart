import 'package:flutter/material.dart';

import '../app/theme.dart';

/// A label above a text field — the pattern used on the login, setup, and
/// add/edit product forms.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.hintText,
    this.maxLines = 1,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.enabled = true,
    this.focusNode,
    this.icon,
    this.suffixIcon,
    this.textDirection,
    this.borderColor,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final String? hintText;
  final int maxLines;

  /// Enforces a character limit with no built-in counter row — pair with a
  /// caller-rendered counter (the settings screen's "22 / 42 حرفًا") when one
  /// is needed, since the default Material counter doesn't match this
  /// design's wording.
  final int? maxLength;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final bool enabled;
  final FocusNode? focusNode;

  /// An inset icon (person/lock, on the login and setup cards). Flutter's
  /// `InputDecoration.prefixIcon` already places it on the correct leading
  /// edge under RTL with no extra directional handling needed.
  final IconData? icon;

  /// A trailing status icon (the barcode field's waiting/filled/duplicate
  /// indicator) or affordance (a rescan button).
  final Widget? suffixIcon;

  /// Forces a direction other than the ambient one — the barcode field
  /// stays LTR even inside this RTL app, since a barcode is Latin/numeric
  /// content, not Arabic text.
  final TextDirection? textDirection;

  /// Overrides the field's enabled/focused border colour, for a field that
  /// needs to communicate a state (success, error) beyond plain focus.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTheme.weighted(theme.textTheme.bodyMedium, FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          textDirection: textDirection,
          // `counterText: ''` alone only blanks the counter's text — Flutter
          // still reserves the row's height for it. Returning null from
          // buildCounter is what actually removes the space, which matters
          // here since callers that set maxLength pair this with their own
          // counter rendered separately (see the settings screen).
          buildCounter: maxLength == null
              ? null
              : (
                  context, {
                  required currentLength,
                  required maxLength,
                  required isFocused,
                }) => null,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 17, color: tokens.faint),
            suffixIcon: suffixIcon,
            enabledBorder: borderColor == null
                ? null
                : OutlineInputBorder(
                    borderRadius: AppRadii.field,
                    borderSide: BorderSide(color: borderColor!),
                  ),
            focusedBorder: borderColor == null
                ? null
                : OutlineInputBorder(
                    borderRadius: AppRadii.field,
                    borderSide: BorderSide(color: borderColor!, width: 2),
                  ),
          ),
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          autofocus: autofocus,
          enabled: enabled,
        ),
      ],
    );
  }
}
