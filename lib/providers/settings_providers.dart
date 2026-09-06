import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/home_text.dart';
import 'database_providers.dart';

/// Overridden in `main()` with a one-shot read of the saved row, resolved
/// before `runApp` — see [HomeTextNotifier.build] for why.
final initialHomeTextProvider = Provider<HomeText>(
  (ref) =>
      throw StateError('initialHomeTextProvider must be overridden in main()'),
);

/// The kiosk homepage's live welcome text — watched by the home screen so a
/// change saved from settings shows up immediately without a restart.
///
/// Backed by a [Notifier] rather than a plain `StreamProvider` so the very
/// first read is already correct. A `StreamProvider` only reaches
/// `AsyncData` once its stream's first emission actually arrives — at least
/// one database round trip away, even if that stream is *seeded* with an
/// already-known first value, since listener callbacks on a `Stream` are
/// always dispatched asynchronously (a Dart guarantee, not a quirk of this
/// database). The very first frame would otherwise have nothing to show but
/// the default theme, then flash to the shop's actual chosen one moments
/// later. `build()` below sidesteps that entirely: it returns
/// [initialHomeTextProvider]'s already-resolved value synchronously, and
/// only starts listening to the live database stream, for updates made
/// while the app is running, after that.
class HomeTextNotifier extends Notifier<HomeText> {
  @override
  HomeText build() {
    final subscription = ref
        .watch(settingsRepositoryProvider)
        .watchHomeText()
        .listen((value) => state = value);
    ref.onDispose(subscription.cancel);
    return ref.watch(initialHomeTextProvider);
  }
}

final homeTextProvider = NotifierProvider<HomeTextNotifier, HomeText>(
  HomeTextNotifier.new,
);
