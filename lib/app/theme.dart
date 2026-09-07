import 'package:flutter/material.dart';

import '../data/models/home_theme.dart';

/// Fixed, theme-invariant colours — semantic meaning (success/danger) or
/// pure neutrals that must read the same regardless of which
/// [HomeThemeKey] the shop has picked. Everything else the app's visual
/// design needs is derived per-theme by [_BgFamily]/[_InkFamily] below,
/// from that key's own [HomeThemeKey.bg]/[HomeThemeKey.title].
abstract final class _Fixed {
  static const surface = Color(0xFFFFFFFF);
  static const onDark = Color(0xFFFFFFFF);

  static const successBg = Color(0xFFF1F7EF);
  static const successBorder = Color(0xFFBFDDBC);
  static const successFg = Color(0xFF3F6B3A);
  static const dangerBg = Color(0xFFFBEEE9);
  static const dangerBorder = Color(0xFFE9B7A4);
  static const dangerFg = Color(0xFFA05540);

  /// "Hair" suitability chips are deliberately neutral grey, in contrast to
  /// the warm "skin" chips below — a real category distinction on the
  /// product detail screen, not decoration, so it stays put regardless of
  /// the shop's chosen theme.
  static const hairChipBg = Color(0xFFEEEBE4);
  static const hairChipFg = Color(0xFF5F5A4E);
}

/// A shift in HSL space, used to derive one design token from a
/// [HomeThemeKey]'s anchor colour. [saturation]/[lightness] are
/// percentage-point deltas (e.g. `-6.7`), not the `0.0`-`1.0` fractions
/// [HSLColor] itself stores.
///
/// The numbers in [_BgFamily]/[_InkFamily] aren't invented: they're the
/// real H/S/L differences between the original approved (tan) design's own
/// tokens — e.g. `canvasPressed` really is `canvas` at -6.7% lightness,
/// -3.2% saturation — measured once from that design and re-applied to
/// every theme's anchor colour, so all five palettes share the exact same
/// internal relationships the original design already established rather
/// than five independently hand-picked colour sets.
class _HslShift {
  const _HslShift({this.hue = 0, this.saturation = 0, this.lightness = 0});

  final double hue;
  final double saturation;
  final double lightness;

  Color apply(Color anchor) {
    final hsl = HSLColor.fromColor(anchor);
    return hsl
        .withHue((hsl.hue + hue) % 360)
        .withSaturation((hsl.saturation + saturation / 100).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + lightness / 100).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Backgrounds, borders, and dividers — every shift here is relative to
/// [HomeThemeKey.bg].
abstract final class _BgFamily {
  static const canvasGradientTop = _HslShift(
    hue: 2.33,
    saturation: 1.08,
    lightness: 3.53,
  );
  static const canvasPressed = _HslShift(
    hue: 0.41,
    saturation: -3.23,
    lightness: -6.67,
  );
  static const border = _HslShift(
    hue: 1.08,
    saturation: -17.92,
    lightness: 4.71,
  );
  static const divider = _HslShift(
    hue: 1.99,
    saturation: -19.36,
    lightness: 13.33,
  );
  static const formCanvas = _HslShift(
    hue: 1.08,
    saturation: -11.67,
    lightness: 21.18,
  );
  static const imagePanelBg = _HslShift(
    hue: 3.08,
    saturation: -11.67,
    lightness: 19.61,
  );
  static const imagePanelBorder = _HslShift(
    hue: 1.80,
    saturation: -15.00,
    lightness: 11.76,
  );
  static const dropzoneBorder = _HslShift(
    hue: 1.08,
    saturation: -22.54,
    lightness: 0.98,
  );
  static const skinChipBg = _HslShift(
    hue: 1.58,
    saturation: -4.52,
    lightness: 9.80,
  );

  /// The light circular badge behind a card-header icon (settings, login,
  /// setup, the kiosk's not-found card).
  static const iconBadgeBg = _HslShift(
    hue: 1.08,
    saturation: -7.82,
    lightness: 15.88,
  );
}

/// Text, ink, and accent tones — every shift here is relative to
/// [HomeThemeKey.title].
abstract final class _InkFamily {
  static const ink = _HslShift(
    hue: 6.60,
    saturation: -29.31,
    lightness: -16.47,
  );
  static const inkHover = _HslShift(
    hue: 12.60,
    saturation: -12.92,
    lightness: -10.20,
  );
  static const body = _HslShift(hue: 0.47, saturation: 10.34, lightness: 2.94);
  static const faint = _HslShift(
    hue: 3.60,
    saturation: -17.11,
    lightness: 34.90,
  );
  static const placeholder = _HslShift(
    hue: 3.27,
    saturation: -18.16,
    lightness: 36.86,
  );
  static const chipOnFg = _HslShift(
    hue: 1.60,
    saturation: 19.44,
    lightness: -11.76,
  );
  static const chipOffFg = _HslShift(
    hue: 1.60,
    saturation: 1.23,
    lightness: 8.82,
  );
  static const skinChipFg = _HslShift(
    hue: 1.87,
    saturation: 28.45,
    lightness: -4.51,
  );
  static const gold = _HslShift(hue: 3.10, saturation: 6.36, lightness: 21.76);
  static const goldDeep = _HslShift(
    hue: 0.91,
    saturation: 8.72,
    lightness: 10.78,
  );
  static const borderFocus = _HslShift(
    hue: 0.85,
    saturation: 12.45,
    lightness: 31.57,
  );
  static const chipOnBorder = _HslShift(
    hue: 2.01,
    saturation: 18.37,
    lightness: 39.22,
  );
  static const shadowBase = _HslShift(
    hue: -0.69,
    saturation: 26.32,
    lightness: -4.71,
  );
}

/// Design tokens that have no home in [ColorScheme] or [TextTheme]. Built
/// fresh per [HomeThemeKey] by [AppTokens.forTheme] — nothing here is a
/// fixed constant except by way of [_Fixed].
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.cardRadius,
    required this.cardShadow,
    required this.formCanvas,
    required this.canvasGradientTop,
    required this.ink,
    required this.inkHover,
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
    required this.raisedShadow,
    required this.modalShadow,
    required this.prominentShadow,
    required this.shadowColor,
    required this.iconBadgeBg,
  });

  /// The shared radius/shadow for a "big white card on canvas" — login,
  /// setup, product detail/form, inventory cards, the debug panels.
  final BorderRadius cardRadius;
  final List<BoxShadow> cardShadow;

  final Color formCanvas;
  final Color canvasGradientTop;

  /// The near-black primary-action colour (dark buttons, icons, primary
  /// text) — also [ColorScheme.primary]. Exposed here too since a handful
  /// of call sites (e.g. [AppTheme.darkButtonStyle]) only have a
  /// [BuildContext], not the [HomeThemeKey] itself, to derive it from.
  final Color ink;
  final Color inkHover;

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

  /// The small lift under a circular icon button.
  ///
  /// Note for whoever extends this: the shadow *colour* is themed for every
  /// use in the app (they all build on [shadowColor]), and the shapes that
  /// repeat are named here. Five one-off shapes remain inline at their call
  /// sites — home's account button and not-found card, the product hero
  /// card, and the settings cards. They are close enough to each other to be
  /// worth collapsing, but that changes how the app looks, so it belongs in
  /// a deliberate design pass rather than in a rename.
  final List<BoxShadow> raisedShadow;

  /// The deep shadow under a floating card that owns the screen — the login
  /// and setup cards.
  final List<BoxShadow> modalShadow;

  /// The scan button / modal-level shadow — visibly heavier than [cardShadow].
  final List<BoxShadow> prominentShadow;

  /// The raw, opaque shadow tint [cardShadow]/[prominentShadow] are built
  /// from — for a one-off shadow at a weight neither preset covers, use
  /// `tokens.shadowColor.withValues(alpha: ...)` rather than a literal
  /// colour, so its hue still follows the shop's theme.
  final Color shadowColor;

  /// The light circular badge behind a card-header icon (settings, login,
  /// setup, the kiosk's not-found card).
  final Color iconBadgeBg;

  /// Derives every token in one pass from [key]'s `bg`/`title` anchors (see
  /// [_HslShift]'s doc comment for how) plus the handful of theme-invariant
  /// values in [_Fixed].
  factory AppTokens.forTheme(HomeThemeKey key) {
    final canvas = key.bg;
    final label = key.title;
    final shadowColor = _InkFamily.shadowBase.apply(label);

    return AppTokens(
      cardRadius: const BorderRadius.all(Radius.circular(24)),
      cardShadow: [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.14),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
      raisedShadow: [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.10),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
      modalShadow: [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.20),
          blurRadius: 56,
          offset: const Offset(0, 24),
        ),
      ],
      formCanvas: _BgFamily.formCanvas.apply(canvas),
      canvasGradientTop: _BgFamily.canvasGradientTop.apply(canvas),
      ink: _InkFamily.ink.apply(label),
      inkHover: _InkFamily.inkHover.apply(label),
      label: label,
      body: _InkFamily.body.apply(label),
      muted: key.subtitle,
      faint: _InkFamily.faint.apply(label),
      border: _BgFamily.border.apply(canvas),
      borderFocus: _InkFamily.borderFocus.apply(label),
      gold: _InkFamily.gold.apply(label),
      goldDeep: _InkFamily.goldDeep.apply(label),
      divider: _BgFamily.divider.apply(canvas),
      chipOnBg: canvas,
      chipOnFg: _InkFamily.chipOnFg.apply(label),
      chipOnBorder: _InkFamily.chipOnBorder.apply(label),
      chipOffBg: _Fixed.surface,
      chipOffFg: _InkFamily.chipOffFg.apply(label),
      skinChipBg: _BgFamily.skinChipBg.apply(canvas),
      skinChipFg: _InkFamily.skinChipFg.apply(label),
      hairChipBg: _Fixed.hairChipBg,
      hairChipFg: _Fixed.hairChipFg,
      successBorder: _Fixed.successBorder,
      successFg: _Fixed.successFg,
      dangerBg: _Fixed.dangerBg,
      dangerBorder: _Fixed.dangerBorder,
      dropzoneBorder: _BgFamily.dropzoneBorder.apply(canvas),
      imagePanelBg: _BgFamily.imagePanelBg.apply(canvas),
      imagePanelBorder: _BgFamily.imagePanelBorder.apply(canvas),
      successBg: _Fixed.successBg,
      prominentShadow: [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.22),
          blurRadius: 44,
          offset: const Offset(0, 20),
        ),
      ],
      shadowColor: shadowColor,
      iconBadgeBg: _BgFamily.iconBadgeBg.apply(canvas),
    );
  }

  static final _fallback = AppTokens.forTheme(defaultHomeThemeKey);

  /// Convenience accessor so widgets can write `AppTokens.of(context).gold`.
  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>() ?? _fallback;

  @override
  AppTokens copyWith({
    BorderRadius? cardRadius,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? raisedShadow,
    List<BoxShadow>? modalShadow,
    Color? formCanvas,
    Color? canvasGradientTop,
    Color? ink,
    Color? inkHover,
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
    Color? shadowColor,
    Color? iconBadgeBg,
  }) {
    return AppTokens(
      cardRadius: cardRadius ?? this.cardRadius,
      cardShadow: cardShadow ?? this.cardShadow,
      raisedShadow: raisedShadow ?? this.raisedShadow,
      modalShadow: modalShadow ?? this.modalShadow,
      formCanvas: formCanvas ?? this.formCanvas,
      canvasGradientTop: canvasGradientTop ?? this.canvasGradientTop,
      ink: ink ?? this.ink,
      inkHover: inkHover ?? this.inkHover,
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
      shadowColor: shadowColor ?? this.shadowColor,
      iconBadgeBg: iconBadgeBg ?? this.iconBadgeBg,
    );
  }

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      cardRadius: BorderRadius.lerp(cardRadius, other.cardRadius, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
      raisedShadow: BoxShadow.lerpList(raisedShadow, other.raisedShadow, t)!,
      modalShadow: BoxShadow.lerpList(modalShadow, other.modalShadow, t)!,
      formCanvas: Color.lerp(formCanvas, other.formCanvas, t)!,
      canvasGradientTop: Color.lerp(
        canvasGradientTop,
        other.canvasGradientTop,
        t,
      )!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkHover: Color.lerp(inkHover, other.inkHover, t)!,
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
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      iconBadgeBg: Color.lerp(iconBadgeBg, other.iconBadgeBg, t)!,
    );
  }
}

/// The corner radii the design uses.
///
/// Constants rather than [AppTokens] fields: a radius doesn't change with
/// the shop's colour theme, so putting them in the extension would mean
/// lerping values that never differ. Named here so a radius is changed in
/// one place instead of hunted for as a bare number across nine files.
///
/// These are the values the screens already used, not a redesign. Several
/// are suspiciously close together (10/12/13/14, 20/22/24/26/28) — worth
/// collapsing, but as a deliberate design decision rather than a side
/// effect of naming them.
abstract final class AppRadii {
  /// Chips, small status pills, the swatch tiles.
  static const sm = BorderRadius.all(Radius.circular(10));

  /// Inline notices and the settings status pills.
  static const notice = BorderRadius.all(Radius.circular(12));

  /// Text fields and the primary buttons that sit beside them.
  static const field = BorderRadius.all(Radius.circular(13));

  /// Images inset within a card — the grid thumbnail, the form's drop zone.
  static const inset = BorderRadius.all(Radius.circular(14));

  /// The settings screen's kiosk preview panel.
  static const preview = BorderRadius.all(Radius.circular(18));

  /// The "no image yet" dashed placeholder.
  static const placeholder = BorderRadius.all(Radius.circular(24));

  /// The inventory grid's product cards.
  static const card = BorderRadius.all(Radius.circular(20));

  /// The settings cards.
  static const panel = BorderRadius.all(Radius.circular(22));

  /// The scan indicator and the home screen's inline cards.
  static const kioskCard = BorderRadius.all(Radius.circular(26));

  /// The largest surfaces: the auth cards and the product hero card.
  static const hero = BorderRadius.all(Radius.circular(28));

  /// Fully rounded — search fields, tag chips, stadium buttons.
  static const pill = BorderRadius.all(Radius.circular(999));
}

abstract final class AppTheme {
  /// The app's [ThemeData] for [key] — every colour in the app, including
  /// admin screens, derives from this one call. See [AppTokens.forTheme]
  /// and [_HslShift] for how.
  ///
  /// Cached per key. There are only five, they never change at runtime, and
  /// building one means a full ColorScheme, ~40 HSL-derived tokens and a
  /// 15-role TextTheme. Returning the identical instance also matters to
  /// [AnimatedTheme], which MaterialApp wraps the whole tree in: handed an
  /// equal-but-not-identical ThemeData it lerps every colour in the app for
  /// 200ms, so an uncached call turned any settings write into a full-tree
  /// re-theme.
  static final _cache = <HomeThemeKey, ThemeData>{};

  static ThemeData forTheme(HomeThemeKey key) =>
      _cache.putIfAbsent(key, () => _build(key));

  static ThemeData _build(HomeThemeKey key) {
    final tokens = AppTokens.forTheme(key);
    final canvas = key.bg;

    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: tokens.ink,
      onPrimary: _Fixed.onDark,
      secondary: canvas,
      onSecondary: tokens.ink,
      surface: _Fixed.surface,
      onSurface: tokens.ink,
      surfaceContainerHighest: canvas,
      onSurfaceVariant: tokens.body,
      outline: tokens.border,
      outlineVariant: tokens.divider,
      error: _Fixed.dangerFg,
      onError: _Fixed.onDark,
      errorContainer: _Fixed.dangerBg,
      onErrorContainer: _Fixed.dangerFg,
      shadow: tokens.shadowColor,
    );

    final placeholder = _InkFamily.placeholder.apply(key.title);
    final canvasPressed = _BgFamily.canvasPressed.apply(canvas);
    final textTheme = _readexTextTheme(ThemeData.light().textTheme, tokens.ink);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      textTheme: textTheme,
      extensions: [tokens],

      // Visible focus rings are a hard requirement: every interactive element
      // has to be reachable and identifiable by keyboard alone.
      focusColor: canvasPressed,

      iconTheme: IconThemeData(color: tokens.ink),

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: canvas,
        foregroundColor: tokens.ink,
        titleTextStyle: textTheme.titleLarge,
      ),

      dividerTheme: DividerThemeData(color: tokens.divider, thickness: 1),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _Fixed.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: placeholder),
        border: _inputBorder(tokens.border),
        enabledBorder: _inputBorder(tokens.border),
        focusedBorder: _inputBorder(tokens.borderFocus, width: 2),
        errorBorder: _inputBorder(_Fixed.dangerFg),
        focusedErrorBorder: _inputBorder(_Fixed.dangerFg, width: 2),
      ),

      // Still a tan-pill default for whatever hasn't been reskinned to the
      // login screen's dark-rectangle treatment yet — that swap happens
      // per-button, in the screen that owns it, not globally.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return canvas.withValues(alpha: 0.5);
            }
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return canvasPressed;
            }
            return canvas;
          }),
          // Not plain ink: the design uses a warmer, slightly lighter brown
          // for text sitting on the tan pill specifically — same value as
          // chipOnFg.
          foregroundColor: WidgetStatePropertyAll(tokens.chipOnFg),
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
        backgroundColor: tokens.chipOffBg,
        selectedColor: tokens.chipOnBg,
        checkmarkColor: tokens.chipOnFg,
        side: BorderSide(color: tokens.border),
        labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.chipOffFg),
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.chipOnFg,
        ),
        shape: const StadiumBorder(),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _Fixed.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: tokens.ink),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: tokens.ink,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: _Fixed.onDark),
      ),
    );
  }

  /// [forTheme] for [defaultHomeThemeKey] — the app's theme before the
  /// shop's saved choice has loaded, and what a `MaterialApp` under test
  /// gets if it doesn't care which theme it's testing.
  static ThemeData get light => forTheme(defaultHomeThemeKey);

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
  /// The confirming action on a destructive dialog, and the delete buttons
  /// that open them — four hand-rolled copies before this.
  static ButtonStyle dangerButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppTokens.of(context).dangerBg,
      foregroundColor: Theme.of(context).colorScheme.error,
    );
  }

  static ButtonStyle darkButtonStyle(
    BuildContext context, {
    OutlinedBorder? shape,
  }) {
    final tokens = AppTokens.of(context);
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return tokens.ink.withValues(alpha: 0.5);
        }
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return tokens.inkHover;
        }
        return tokens.ink;
      }),
      foregroundColor: const WidgetStatePropertyAll(_Fixed.onDark),
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
  /// line height and letter spacing, [ink] as the default text colour, and
  /// driving the variable font's `wght` axis explicitly via [FontVariation]
  /// (relying on `fontWeight` alone to pick the right instance is not
  /// reliable on every text-rendering path).
  static TextTheme _readexTextTheme(TextTheme base, Color ink) {
    TextStyle? readex(TextStyle? style) {
      if (style == null) return null;
      final weight = style.fontWeight ?? FontWeight.w400;
      return style.copyWith(
        fontFamily: 'Readex Pro',
        color: ink,
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
