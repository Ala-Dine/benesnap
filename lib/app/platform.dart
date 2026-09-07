import 'dart:io';

/// Whether `window_manager` calls are safe to make — it's only initialized
/// on desktop (see `main.dart`'s `_configureWindow`), so calling it
/// anywhere else throws.
bool get isDesktopPlatform =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;
