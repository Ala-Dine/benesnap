import 'package:flutter/material.dart';

/// Raw palette values sampled from `Shope_Scanner_dc.html`, the approved
/// design. These are the only literal colours in the app. Widgets must read
/// colours from [ColorScheme] or from the [AppTokens] theme extension, never
/// from here.
abstract final class _Palette {
  // Backgrounds.
  static const canvas = Color(0xFFE8CE9E);
  static const canvasGradientTop = Color(0xFFECD8AC);
  static const formCanvas = Color(0xFFFCFAF6);
  static const surface = Color(0xFFFFFFFF);

  /// Hover shade for a tan pill, taken directly from the design's own
  /// `style-hover` on the not-found screen's "scan another product" button.
  static const canvasPressed = Color(0xFFDFC085);

  // Ink / text.
  static const ink = Color(0xFF1B1A17);
  static const inkHover = Color(0xFF33301F);
  static const label = Color(0xFF5C4A2A);
  static const body = Color(0xFF6E5527);
  static const muted = Color(0xFF9A8560);
  static const faint = Color(0xFFB0A488);
  static const placeholder = Color(0xFFB3A88F);
  static const onDark = Color(0xFFFFFFFF);

  // Borders / accents.
  static const border = Color(0xFFE4D6BA);
  static const borderFocus = Color(0xFFC9A45E);
  static const gold = Color(0xFFB08F45);
  static const goldDeep = Color(0xFF8A6C33);
  static const divider = Color(0xFFF0E9DA);

  // Editable form chips (add/edit product screen).
  static const chipOnBg = canvas;
  static const chipOnFg = Color(0xFF3A2C10);
  static const chipOnBorder = Color(0xFFD8B876);
  static const chipOffBg = surface;
  static const chipOffFg = Color(0xFF7C6537);

  // Display-only suitability chips (product detail screen).
  static const skinChipBg = Color(0xFFF0E3C8);
  static const skinChipFg = Color(0xFF5C4413);
  static const hairChipBg = Color(0xFFEEEBE4);
  static const hairChipFg = Color(0xFF5F5A4E);

  // Status.
  static const successBg = Color(0xFFF1F7EF);
  static const successBorder = Color(0xFFBFDDBC);
  static const successFg = Color(0xFF3F6B3A);
  static const dangerBg = Color(0xFFFBEEE9);
  static const dangerBorder = Color(0xFFE9B7A4);
  static const dangerFg = Color(0xFFA05540);

  // Image zones.
  static const dropzoneBorder = Color(0xFFDCCDAF);
  static const imagePanelBg = Color(0xFFFAF7F0);
  static const imagePanelBorder = Color(0xFFEFE6D3);

  /// Shadows are warm brown (rgb 90,64,20) at varying alpha, never neutral
  /// grey — this is a deliberate, visible part of the design.
  static const _shadowBase = Color(0xFF5A4014);
  static const shadowMid = Color(0x245A4014); // ~.14 alpha — cards
  static const shadowHigh = Color(0x385A4014); // ~.22 alpha — the scan button
}

/// Design tokens that have no home in [ColorScheme] or [TextTheme].
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.cardRadius,
    required this.cardShadow,
    required this.formCanvas,
    required this.canvasGradientTop,
    required this.label,
    required this.body,
    required this.muted,
    required this.faint,
    required this.border,
    required this.borderFocus,
    required this.gold,
    required this.goldDeep,
    required this.divider,
    required this.chipOnBg,
    required this.chipOnFg,
    required this.chipOnBorder,
    required this.chipOffBg,
    required this.chipOffFg,
    required this.skinChipBg,
    required this.skinChipFg,
    required this.hairChipBg,
    required this.hairChipFg,
    required this.successBorder,
    required this.successFg,
    required this.dangerBg,
    required this.dangerBorder,
    required this.dropzoneBorder,
    required this.imagePanelBg,
    required this.imagePanelBorder,
    required this.successBg,
    required this.prominentShadow,
  });

  /// The shared radius/shadow for a "big white card on canvas" — login,
  /// setup, product detail/form, inventory cards, the debug panels.
  final BorderRadius cardRadius;
  final List<BoxShadow> cardShadow;

  final Color formCanvas;
  final Color canvasGradientTop;
  final Color label;
  final Color body;
  final Color muted;
  final Color faint;
  final Color border;
  final Color borderFocus;
  final Color gold;
  final Color goldDeep;
  final Color divider;
  final Color chipOnBg;
  final Color chipOnFg;
  final Color chipOnBorder;
  final Color chipOffBg;
  final Color chipOffFg;
  final Color skinChipBg;
  final Color skinChipFg;
  final Color hairChipBg;
  final Color hairChipFg;
  final Color successBorder;
  final Color successFg;
  final Color dangerBg;
  final Color dangerBorder;
  final Color dropzoneBorder;
  final Color imagePanelBg;
  final Color imagePanelBorder;
  final Color successBg;

  /// The scan button / modal-level shadow — visibly heavier than [cardShadow].
  final List<BoxShadow> prominentShadow;

  static const _light = AppTokens(
    cardRadius: BorderRadius.all(Radius.circular(24)),
    cardShadow: [
      BoxShadow(
        color: _Palette.shadowMid,
        blurRadius: 18,
        offset: Offset(0, 6),
      ),
    ],
    formCanvas: _Palette.formCanvas,
    canvasGradientTop: _Palette.canvasGradientTop,
    label: _Palette.label,
    body: _Palette.body,
    muted: _Palette.muted,
    faint: _Palette.faint,
    border: _Palette.border,
    borderFocus: _Palette.borderFocus,
    gold: _Palette.gold,
    goldDeep: _Palette.goldDeep,
    divider: _Palette.divider,
    chipOnBg: _Palette.chipOnBg,
    chipOnFg: _Palette.chipOnFg,
    chipOnBorder: _Palette.chipOnBorder,
    chipOffBg: _Palette.chipOffBg,
    chipOffFg: _Palette.chipOffFg,
    skinChipBg: _Palette.skinChipBg,
    skinChipFg: _Palette.skinChipFg,
    hairChipBg: _Palette.hairChipBg,
    hairChipFg: _Palette.hairChipFg,
    successBorder: _Palette.successBorder,
    successFg: _Palette.successFg,
    dangerBg: _Palette.dangerBg,
    dangerBorder: _Palette.dangerBorder,
    dropzoneBorder: _Palette.dropzoneBorder,
    imagePanelBg: _Palette.imagePanelBg,
    imagePanelBorder: _Palette.imagePanelBorder,
    successBg: _Palette.successBg,
    prominentShadow: [
      BoxShadow(
        color: _Palette.shadowHigh,
        blurRadius: 44,
        offset: Offset(0, 20),
      ),
    ],
  );

  /// Convenience accessor so widgets can write `AppTokens.of(context).gold`.
  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>() ?? _light;

  @override
  AppTokens copyWith({
    BorderRadius? cardRadius,
    List<BoxShadow>? cardShadow,
    Color? formCanvas,
    Color? canvasGradientTop,
    Color? label,
    Color? body,
    Color? muted,
    Color? faint,
    Color? border,
    Color? borderFocus,
    Color? gold,
    Color? goldDeep,
    Color? divider,
    Color? chipOnBg,
    Color? chipOnFg,
    Color? chipOnBorder,
    Color? chipOffBg,
    Color? chipOffFg,
    Color? skinChipBg,
    Color? skinChipFg,
    Color? hairChipBg,
    Color? hairChipFg,
    Color? successBorder,
    Color? successFg,
    Color? dangerBg,
    Color? dangerBorder,
    Color? dropzoneBorder,
    Color? imagePanelBg,
    Color? imagePanelBorder,
    Color? successBg,
    List<BoxShadow>? prominentShadow,
  }) {
    return AppTokens(
      cardRadius: cardRadius ?? this.cardRadius,
      cardShadow: cardShadow ?? this.cardShadow,
      formCanvas: formCanvas ?? this.formCanvas,
      canvasGradientTop: canvasGradientTop ?? this.canvasGradientTop,
      label: label ?? this.label,
      body: body ?? this.body,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      border: border ?? this.border,
      borderFocus: borderFocus ?? this.borderFocus,
      gold: gold ?? this.gold,
      goldDeep: goldDeep ?? this.goldDeep,
      divider: divider ?? this.divider,
      chipOnBg: chipOnBg ?? this.chipOnBg,
      chipOnFg: chipOnFg ?? this.chipOnFg,
      chipOnBorder: chipOnBorder ?? this.chipOnBorder,
      chipOffBg: chipOffBg ?? this.chipOffBg,
      chipOffFg: chipOffFg ?? this.chipOffFg,
      skinChipBg: skinChipBg ?? this.skinChipBg,
      skinChipFg: skinChipFg ?? this.skinChipFg,
      hairChipBg: hairChipBg ?? this.hairChipBg,
      hairChipFg: hairChipFg ?? this.hairChipFg,
      successBorder: successBorder ?? this.successBorder,
      successFg: successFg ?? this.successFg,
      dangerBg: dangerBg ?? this.dangerBg,
      dangerBorder: dangerBorder ?? this.dangerBorder,
      dropzoneBorder: dropzoneBorder ?? this.dropzoneBorder,
      imagePanelBg: imagePanelBg ?? this.imagePanelBg,
      imagePanelBorder: imagePanelBorder ?? this.imagePanelBorder,
      successBg: successBg ?? this.successBg,
      prominentShadow: prominentShadow ?? this.prominentShadow,
    );
  }

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      cardRadius: BorderRadius.lerp(cardRadius, other.cardRadius, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
      formCanvas: Color.lerp(formCanvas, other.formCanvas, t)!,
      canvasGradientTop: Color.lerp(
        canvasGradientTop,
        other.canvasGradientTop,
        t,
      )!,
      label: Color.lerp(label, other.label, t)!,
      body: Color.lerp(body, other.body, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldDeep: Color.lerp(goldDeep, other.goldDeep, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      chipOnBg: Color.lerp(chipOnBg, other.chipOnBg, t)!,
      chipOnFg: Color.lerp(chipOnFg, other.chipOnFg, t)!,
      chipOnBorder: Color.lerp(chipOnBorder, other.chipOnBorder, t)!,
      chipOffBg: Color.lerp(chipOffBg, other.chipOffBg, t)!,
      chipOffFg: Color.lerp(chipOffFg, other.chipOffFg, t)!,
      skinChipBg: Color.lerp(skinChipBg, other.skinChipBg, t)!,
      skinChipFg: Color.lerp(skinChipFg, other.skinChipFg, t)!,
      hairChipBg: Color.lerp(hairChipBg, other.hairChipBg, t)!,
      hairChipFg: Color.lerp(hairChipFg, other.hairChipFg, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      successFg: Color.lerp(successFg, other.successFg, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      dangerBorder: Color.lerp(dangerBorder, other.dangerBorder, t)!,
      dropzoneBorder: Color.lerp(dropzoneBorder, other.dropzoneBorder, t)!,
      imagePanelBg: Color.lerp(imagePanelBg, other.imagePanelBg, t)!,
      imagePanelBorder: Color.lerp(
        imagePanelBorder,
        other.imagePanelBorder,
        t,
      )!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      prominentShadow: BoxShadow.lerpList(
        prominentShadow,
        other.prominentShadow,
        t,
      )!,
    );
  }
}

abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _Palette.ink,
      onPrimary: _Palette.onDark,
      secondary: _Palette.canvas,
      onSecondary: _Palette.ink,
      surface: _Palette.surface,
      onSurface: _Palette.ink,
      surfaceContainerHighest: _Palette.canvas,
      onSurfaceVariant: _Palette.body,
      outline: _Palette.border,
      outlineVariant: _Palette.divider,
      error: _Palette.dangerFg,
      onError: _Palette.onDark,
      errorContainer: _Palette.dangerBg,
      onErrorContainer: _Palette.dangerFg,
      shadow: _Palette._shadowBase,
    );

    final textTheme = _readexTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _Palette.canvas,
      textTheme: textTheme,
      extensions: const [AppTokens._light],

      // Visible focus rings are a hard requirement: every interactive element
      // has to be reachable and identifiable by keyboard alone.
      focusColor: _Palette.canvasPressed,

      iconTheme: const IconThemeData(color: _Palette.ink),

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _Palette.canvas,
        foregroundColor: _Palette.ink,
        titleTextStyle: textTheme.titleLarge,
      ),

      dividerTheme: const DividerThemeData(
        color: _Palette.divider,
        thickness: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _Palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: _Palette.placeholder),
        border: _inputBorder(_Palette.border),
        enabledBorder: _inputBorder(_Palette.border),
        focusedBorder: _inputBorder(_Palette.borderFocus, width: 2),
        errorBorder: _inputBorder(_Palette.dangerFg),
        focusedErrorBorder: _inputBorder(_Palette.dangerFg, width: 2),
      ),

      // Still a tan-pill default for whatever hasn't been reskinned to the
      // login screen's dark-rectangle treatment yet — that swap happens
      // per-button, in the screen that owns it, not globally.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return _Palette.canvas.withValues(alpha: 0.5);
            }
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return _Palette.canvasPressed;
            }
            return _Palette.canvas;
          }),
          // Not plain ink: the design uses a warmer, slightly lighter brown
          // for text sitting on the tan pill specifically — same value as
          // chipOnFg.
          foregroundColor: const WidgetStatePropertyAll(_Palette.chipOnFg),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          textStyle: WidgetStatePropertyAll(
            weighted(textTheme.titleMedium, FontWeight.w500),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: _Palette.chipOffBg,
        selectedColor: _Palette.chipOnBg,
        checkmarkColor: _Palette.chipOnFg,
        side: const BorderSide(color: _Palette.border),
        labelStyle: textTheme.bodyMedium?.copyWith(color: _Palette.chipOffFg),
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          color: _Palette.chipOnFg,
        ),
        shape: const StadiumBorder(),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _Palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _Palette.ink,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: _Palette.ink,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: _Palette.onDark),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(13)),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Overrides [style]'s weight for a one-off heading/label that needs to
  /// diverge from its role's default. Plain `style.copyWith(fontWeight: ...)`
  /// is not enough on its own: it would leave [TextStyle.fontVariations]
  /// still pointing at the old weight, so the variable font's `wght` axis and
  /// the reported `fontWeight` would disagree. Use this wherever a screen
  /// needs a specific weight instead of its text-theme role's default.
  static TextStyle weighted(TextStyle? style, FontWeight weight) {
    return (style ?? const TextStyle()).copyWith(
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
    );
  }

  /// The dark rectangle/pill button used for a screen's single primary
  /// action — login's submit button, the not-found screen's admin-only "add
  /// this product" button — distinct from the softer tan pill
  /// [elevatedButtonTheme] gives every other button by default.
  static ButtonStyle darkButtonStyle(
    BuildContext context, {
    OutlinedBorder? shape,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return _Palette.ink.withValues(alpha: 0.5);
        }
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return _Palette.inkHover;
        }
        return _Palette.ink;
      }),
      foregroundColor: const WidgetStatePropertyAll(_Palette.onDark),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(shape ?? const StadiumBorder()),
      // Unlike the tan default (weight 500), a dark primary-action button is
      // semibold in the design — set explicitly rather than inherited, since
      // elevatedButtonTheme's own textStyle is 500.
      textStyle: WidgetStatePropertyAll(
        weighted(Theme.of(context).textTheme.titleMedium, FontWeight.w600),
      ),
    );
  }

  /// Rebuilds [base] with Readex Pro, keeping Material's default per-role
  /// font size and weight scale but overriding family, the Arabic-appropriate
  /// line height and letter spacing, and driving the variable font's `wght`
  /// axis explicitly via [FontVariation] (relying on `fontWeight` alone to
  /// pick the right instance is not reliable on every text-rendering path).
  static TextTheme _readexTextTheme(TextTheme base) {
    TextStyle? readex(TextStyle? style) {
      if (style == null) return null;
      final weight = style.fontWeight ?? FontWeight.w400;
      return style.copyWith(
        fontFamily: 'Readex Pro',
        color: _Palette.ink,
        height: 1.7,
        letterSpacing: 0,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
      );
    }

    return TextTheme(
      displayLarge: readex(base.displayLarge),
      displayMedium: readex(base.displayMedium),
      displaySmall: readex(base.displaySmall),
      headlineLarge: readex(base.headlineLarge),
      headlineMedium: readex(base.headlineMedium),
      headlineSmall: readex(base.headlineSmall),
      titleLarge: readex(base.titleLarge),
      titleMedium: readex(base.titleMedium),
      titleSmall: readex(base.titleSmall),
      bodyLarge: readex(base.bodyLarge),
      bodyMedium: readex(base.bodyMedium),
      bodySmall: readex(base.bodySmall),
      labelLarge: readex(base.labelLarge),
      labelMedium: readex(base.labelMedium),
      labelSmall: readex(base.labelSmall),
    );
  }
}
