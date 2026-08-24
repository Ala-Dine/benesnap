import 'package:flutter/foundation.dart';

/// Shown until a shop customizes its welcome text, and whenever the title is
/// cleared back to empty — see [SettingsRepository.updateHomeText].
const defaultWelcomeTitle = 'مرحبًا بكم في المتجر';

/// The shop-customizable kiosk homepage copy.
@immutable
class HomeText {
  const HomeText({required this.welcomeTitle, required this.extraLine});

  final String welcomeTitle;
  final String extraLine;
}
