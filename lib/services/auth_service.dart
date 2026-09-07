import 'package:bcrypt/bcrypt.dart';

import '../data/repositories/admin_repository.dart';

/// The outcome of a login attempt, distinguishing a locked-out account from a
/// plain wrong-password so the screen can word the message appropriately.
enum LoginFailureReason { invalidCredentials, lockedOut }

class LoginFailure {
  const LoginFailure(this.reason, {this.lockoutRemaining});

  final LoginFailureReason reason;

  /// Set only when [reason] is [LoginFailureReason.lockedOut].
  final Duration? lockoutRemaining;
}

/// Admin authentication: bcrypt hashing plus a per-username failed-attempt
/// lockout, entirely in memory (a kiosk reboot is an acceptable way to clear
/// it — this isn't meant to withstand a determined attacker, just casual
/// password guessing at the counter).
class AuthService {
  AuthService(this._admins, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const maxAttempts = 5;
  static const lockoutDuration = Duration(seconds: 30);

  final AdminRepository _admins;
  final DateTime Function() _now;

  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockedUntil = {};

  /// Attempts to sign in. Returns null on success, or a [LoginFailure]
  /// describing why not.
  Future<LoginFailure?> login(String username, String password) {
    return _verify(username, password);
  }

  /// Creates the first (or an additional) admin account with a bcrypt hash.
  Future<void> createAdmin(String username, String password) {
    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    return _admins.create(username: username.trim(), passwordHash: hash);
  }

  /// Changes the signed-in admin's username and/or password, from the
  /// settings screen.
  ///
  /// The username updates freely — this screen is only reachable from an
  /// already-signed-in session, so it carries no more trust than any other
  /// admin action. A password change is different: it replaces the very
  /// credential that session was built on, so [currentPassword] must verify
  /// first, against the same lockout [login] uses. [newPassword] null or
  /// empty leaves the password unchanged and skips that check entirely.
  ///
  /// Returns null on success, or the same [LoginFailure] shape [login] uses
  /// so the screen can reuse its wrong-password/locked-out messaging.
  Future<LoginFailure?> updateCredentials({
    required String currentUsername,
    required String newUsername,
    String? currentPassword,
    String? newPassword,
  }) async {
    String? newHash;
    if (newPassword != null && newPassword.isNotEmpty) {
      final failure = await _verify(currentUsername, currentPassword ?? '');
      if (failure != null) return failure;
      newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    }

    await _admins.update(
      currentUsername: currentUsername.trim(),
      newUsername: newUsername.trim(),
      newPasswordHash: newHash,
    );
    return null;
  }

  /// Shared bcrypt check and lockout bookkeeping for [login] and
  /// [updateCredentials].
  Future<LoginFailure?> _verify(String username, String password) async {
    final key = username.trim().toLowerCase();

    final lockedUntil = _lockedUntil[key];
    if (lockedUntil != null) {
      final remaining = lockedUntil.difference(_now());
      if (remaining > Duration.zero) {
        return LoginFailure(
          LoginFailureReason.lockedOut,
          lockoutRemaining: remaining,
        );
      }
      _lockedUntil.remove(key);
      _failedAttempts.remove(key);
    }

    final hash = await _admins.passwordHashFor(username.trim());
    final matches = hash != null && BCrypt.checkpw(password, hash);

    if (matches) {
      _failedAttempts.remove(key);
      return null;
    }

    final attempts = (_failedAttempts[key] ?? 0) + 1;
    _failedAttempts[key] = attempts;

    if (attempts >= maxAttempts) {
      _lockedUntil[key] = _now().add(lockoutDuration);
      return const LoginFailure(
        LoginFailureReason.lockedOut,
        lockoutRemaining: lockoutDuration,
      );
    }

    return const LoginFailure(LoginFailureReason.invalidCredentials);
  }
}
