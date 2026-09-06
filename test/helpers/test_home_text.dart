import 'package:benesnap/data/models/home_text.dart';
import 'package:benesnap/providers/settings_providers.dart';

/// Overrides [homeTextProvider] with a fixed value that never touches the
/// database — bypassing [HomeTextNotifier]'s own live subscription (not
/// just seeding it) sidesteps drift's live-query stream, which otherwise
/// leaves pending timers behind across a screen's dispose/recreate cycle in
/// widget tests.
dynamic staticHomeTextOverride(HomeText value) {
  return homeTextProvider.overrideWith(() => _StaticHomeTextNotifier(value));
}

class _StaticHomeTextNotifier extends HomeTextNotifier {
  _StaticHomeTextNotifier(this._value);

  final HomeText _value;

  @override
  HomeText build() => _value;
}
