import 'package:drift/drift.dart';
// The whole `drift/remote.dart` library is marked experimental, but this is
// the only supported way to unwrap an exception thrown across the
// `NativeDatabase.createInBackground` isolate boundary.
// ignore: experimental_member_use
import 'package:drift/remote.dart' show DriftRemoteException;
import 'package:sqlite3/common.dart' show SqliteException;

import '../db/app_database.dart';
import '../exceptions.dart';

/// Admin accounts. Stores bcrypt hashes only — never a plaintext password.
///
/// Hashing itself lives in `AuthService`; this class only persists what it is
/// handed.
class AdminRepository {
  AdminRepository(this._db);

  final AppDatabase _db;

  static const _uniqueViolation = 2067;

  /// True on a fresh install, which is what triggers the one-time setup screen.
  Future<bool> isEmpty() async {
    try {
      final row = await (_db.select(_db.admins)..limit(1)).getSingleOrNull();
      return row == null;
    } catch (e) {
      throw StorageException(e);
    }
  }

  /// Returns the stored bcrypt hash for [username], or null if no such admin.
  ///
  /// Matched case-insensitively: `AuthService` already keys its lockout
  /// counter by the lowercased name, so a case-sensitive lookup here meant
  /// signing in as `admin` to an account created as `Admin` failed every
  /// time *and* burned an attempt against the same counter.
  Future<String?> passwordHashFor(String username) async {
    try {
      final row =
          await (_db.select(_db.admins)..where(
                (a) => a.username.lower().equals(username.trim().toLowerCase()),
              ))
              .getSingleOrNull();
      return row?.passwordHash;
    } catch (e) {
      throw StorageException(e);
    }
  }

  Future<void> create({
    required String username,
    required String passwordHash,
  }) async {
    try {
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
    } on AppException {
      rethrow;
    } catch (e) {
      // The background isolate wraps failures, so the SqliteException we care
      // about arrives inside a DriftRemoteException.
      final cause = e is DriftRemoteException ? e.remoteCause : e;
      if (cause is AppException) throw cause;

      if (cause is SqliteException &&
          cause.extendedResultCode == _uniqueViolation) {
        throw DuplicateUsernameException(username);
      }
      throw StorageException(cause);
    }
  }

  /// Renames [currentUsername] to [newUsername] and, when
  /// [newPasswordHash] is given, replaces its password hash too.
  ///
  /// The caller (`AuthService`) is responsible for verifying the admin's
  /// current password before calling this — this method only persists.
  Future<void> update({
    required String currentUsername,
    required String newUsername,
    String? newPasswordHash,
  }) async {
    try {
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
    } on AppException {
      rethrow;
    } catch (e) {
      final cause = e is DriftRemoteException ? e.remoteCause : e;

      if (cause is AppException) throw cause;
      if (cause is SqliteException &&
          cause.extendedResultCode == _uniqueViolation) {
        throw DuplicateUsernameException(newUsername);
      }
      throw StorageException(cause);
    }
  }
}
