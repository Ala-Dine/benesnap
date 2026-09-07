import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension AppNavigation on BuildContext {
  /// Pops if there is anywhere to pop to, otherwise navigates to [fallback].
  ///
  /// Every screen with a back button needs this: most of the time it is
  /// reached by a push and can simply pop, but a redirect (or a
  /// `pushReplacement` on the kiosk path) can leave it as the only route on
  /// the stack, where `pop` would do nothing at all. Four screens each had
  /// their own copy.
  void popOr(String fallback) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }
}
