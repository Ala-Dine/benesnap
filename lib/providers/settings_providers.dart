import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/home_text.dart';
import 'database_providers.dart';

/// The kiosk homepage's live welcome text — watched by the home screen so a
/// change saved from settings shows up immediately without a restart.
final homeTextProvider = StreamProvider<HomeText>((ref) {
  return ref.watch(settingsRepositoryProvider).watchHomeText();
});
