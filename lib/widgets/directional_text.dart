import 'package:flutter/material.dart';

/// Characters that are strongly right-to-left: Hebrew, Arabic, Syriac,
/// Thaana, NKo, Samaritan and Mandaic, plus the Arabic and Hebrew
/// presentation forms.
///
/// An approximation of the Unicode Bidirectional Algorithm's `R`/`AL`
/// classes in two ranges rather than a full property table. It over-reaches
/// slightly — Arabic-Indic digits sit inside the Arabic block and the
/// algorithm proper calls those `AN`, not strong — but a string that leads
/// with them is Arabic in every case this app will meet, so the answer it
/// gives is still the right one.
// Not raw strings: the ranges are written as \u escapes so they stay
// legible and diffable rather than as the literal characters themselves.
final _rtl = RegExp('[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]');

/// The first character that decides a direction: anything strongly RTL, or
/// any letter at all (Latin, Greek, Cyrillic, CJK — all left-to-right).
/// Digits, punctuation, symbols and whitespace decide nothing and are
/// skipped, which is the whole point.
final _firstStrong = RegExp(
  '[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]|\\p{L}',
  unicode: true,
);

/// The base direction [text] should be laid out with, taken from its first
/// strongly-directional character.
///
/// This is the rule the Unicode Bidirectional Algorithm itself uses, and
/// what `U+2068 FIRST STRONG ISOLATE` applies to a run.
///
/// Null when there is no strong character to go on at all — `"2024"`,
/// `"+"`, `""` — where nothing can be inferred and the caller's ambient
/// direction is as good an answer as any.
TextDirection? firstStrongDirection(String text) {
  final match = _firstStrong.firstMatch(text);
  if (match == null) return null;
  return _rtl.hasMatch(match[0]!) ? TextDirection.rtl : TextDirection.ltr;
}

/// Catalogue text — a brand, a product name — laid out in the direction its
/// own content asks for, while staying aligned to the surrounding layout.
///
/// The shop types this text; nothing constrains it to one script. Left to
/// inherit the app's ambient RTL, a Latin name ending in punctuation comes
/// out reordered: `DERMA+` renders as `+DERMA`, and `Dr. Jart+` — a real
/// brand — the same way, because a trailing `+` is bidi-neutral and takes
/// the paragraph's direction rather than the word's. Giving the string its
/// own base direction fixes that without touching Arabic names, which keep
/// resolving to RTL exactly as they do today.
///
/// Alignment deliberately does *not* follow that direction. It stays with
/// the ambient layout, so a Latin brand in a right-aligned card stays right
/// aligned instead of jumping to the far edge and breaking the column's
/// rhythm. Only the reading order inside the string changes.
class DirectionalText extends StatelessWidget {
  const DirectionalText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final ambient = Directionality.of(context);

    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: firstStrongDirection(text) ?? ambient,
      textAlign: ambient == TextDirection.rtl
          ? TextAlign.right
          : TextAlign.left,
    );
  }
}
