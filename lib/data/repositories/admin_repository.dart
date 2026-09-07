import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../exceptions.dart';
import 'storage_guard.dart';

/// Admin accounts. Stores bcrypt hashes only — never a plaintext password.
///
/// Hashing itself lives in `AuthService`; this class only persists what it is
/// handed.
class AdminRepository {
  AdminRepository(this._db);

  final AppDatabase _db;

  /// True on a fresh install, which is what triggers the one-time setup screen.
  Future<bool> isEmpty() => guardStorage(() async {
    final row = await (_db.select(_db.admins)..limit(1)).getSingleOrNull();
    return row == null;
  });

  /// Returns the stored bcrypt hash for [username], or null if no such admin.
  ///
  /// Matched case-insensitively: `AuthService` already keys its lockout
  /// counter by the lowercased name, so a case-sensitive lookup here meant
  /// signing in as `admin` to an account created as `Admin` failed every
  /// time *and* burned an attempt against the same counter.
  Future<String?> passwordHashFor(String username) => guardStorage(() async {
    final row =
        await (_db.select(_db.admins)..where(
              (a) => a.username.lower().equals(username.trim().toLowerCase()),
            ))
            .getSingleOrNull();
    return row?.passwordHash;
  });

  Future<void> create({
    required String username,
    required String passwordHash,
  }) => guardStorage(() async {
    // The unique index is case-sensitive, so it would happily accept `admin`
    // alongside `Admin` — which passwordHashFor could then no longer tell
    // apart.
    if (await passwordHashFor(username) != null) {
      throw DuplicateUsernameException(username);
    }
    await _db
        .into(_db.admins)
        .insert(
          AdminsCompanion.insert(
            username: username,
            passwordHash: passwordHash,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }, onUniqueViolation: () => DuplicateUsernameException(username));

  /// Renames [currentUsername] to [newUsername] and, when
  /// [newPasswordHash] is given, replaces its password hash too.
  ///
  /// The caller (`AuthService`) is responsible for verifying the admin's
  /// current password before calling this — this method only persists.
  Future<void> update({
    required String currentUsername,
    required String newUsername,
    String? newPasswordHash,
  }) => guardStorage(() async {
    final changed =
        await (_db.update(_db.admins)..where(
              (a) => a.username.lower().equals(
                currentUsername.trim().toLowerCase(),
              ),
            ))
            .write(
              AdminsCompanion(
                username: Value(newUsername),
                passwordHash: newPasswordHash == null
                    ? const Value.absent()
                    : Value(newPasswordHash),
              ),
            );
    if (changed == 0) throw const AdminNotFoundException();
  }, onUniqueViolation: () => DuplicateUsernameException(newUsername));
}
