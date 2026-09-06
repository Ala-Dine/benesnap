import 'package:flutter/material.dart';

/// A shop-selectable kiosk colour theme — background, title, and subtitle
/// colours for the welcome screen and the settings preview that mirrors it.
///
/// Stored as [name] (the enum's own stable string key, e.g. `"sand"`) rather
/// than raw hex values, so the palette can be edited or extended later
/// without touching stored data. This is the single source of these colours
/// — the settings screen and the kiosk home screen both read a preset's
/// [bg]/[title]/[subtitle] from here rather than hardcoding hex at either
/// usage site.
enum HomeThemeKey {
  sand(
    bg: Color(0xFFE5C79B),
    title: Color(0xFF5C401F),
    subtitle: Color(0xFF7A5B34),
  ),
  blush(
    bg: Color(0xFFEBC9BE),
    title: Color(0xFF6B3F31),
    subtitle: Color(0xFF8A594A),
  ),
  sage(
    bg: Color(0xFFCBD5C0),
    title: Color(0xFF3F4E34),
    subtitle: Color(0xFF5A6B4C),
  ),
  vanilla(
    bg: Color(0xFFF0DFA8),
    title: Color(0xFF5E4C1B),
    subtitle: Color(0xFF7C6730),
  ),
  sky(
    bg: Color(0xFFC7D6DE),
    title: Color(0xFF334A56),
    subtitle: Color(0xFF4E6673),
  );

  const HomeThemeKey({
    required this.bg,
    required this.title,
    required this.subtitle,
  });

  final Color bg;
  final Color title;
  final Color subtitle;
}

const defaultHomeThemeKey = HomeThemeKey.sand;

/// Resolves a stored [HomeThemeKey.name] back to its enum value, falling
/// back to [defaultHomeThemeKey] when [key] is null or unrecognised (e.g.
/// no theme saved yet, or a stored key from a palette entry since removed).
HomeThemeKey homeThemeKeyFromStorage(String? key) {
  return HomeThemeKey.values.firstWhere(
    (candidate) => candidate.name == key,
    orElse: () => defaultHomeThemeKey,
  );
}
