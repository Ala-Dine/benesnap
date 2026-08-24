import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_providers.dart';
import '../services/auth_service.dart';

/// Who is currently signed in. `null` means kiosk mode — the default.
///
/// The session is deliberately in-memory only: relaunching the app returns the
/// counter to kiosk mode, which is what the shop wants at the start of a shift.
class AuthSession extends Notifier<String?> {
  @override
  String? build() => null;

  void signIn(String username) => state = username;

  void signOut() => state = null;
}

final authSessionProvider = NotifierProvider<AuthSession, String?>(
  AuthSession.new,
);

/// True when an admin is signed in and the catalogue may be edited.
final isAdminProvider = Provider<bool>(
  (ref) => ref.watch(authSessionProvider) != null,
);

/// Kept alive for the app's lifetime so the failed-attempt lockout survives
/// navigating away from the login screen and back.
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(adminRepositoryProvider)),
);
