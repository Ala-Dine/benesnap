import 'package:flutter/foundation.dart';

import 'home_theme.dart';

/// Shown until a shop customizes its welcome text, and whenever the title is
/// cleared back to empty — see [SettingsRepository.updateHomeText].
const defaultWelcomeTitle = 'مرحبًا بكم في المتجر';

/// The shop-customizable kiosk homepage copy and colour theme.
@immutable
class HomeText {
  const HomeText({
    required this.welcomeTitle,
    required this.extraLine,
    required this.themeKey,
  });

  final String welcomeTitle;
  final String extraLine;
  final HomeThemeKey themeKey;
}
