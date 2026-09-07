// The whole `drift/remote.dart` library is marked experimental, but this is
// the only supported way to unwrap an exception thrown across the
// `NativeDatabase.createInBackground` isolate boundary.
// ignore: experimental_member_use
import 'package:drift/remote.dart' show DriftRemoteException;
import 'package:sqlite3/common.dart' show SqliteException;

import '../exceptions.dart';

/// SQLite's extended result code for a UNIQUE constraint failure.
const uniqueViolation = 2067;

/// Runs a database call and translates anything it throws into an
/// [AppException].
///
/// This is the single boundary `exceptions.dart` describes: past it, no
/// caller ever sees a raw drift or sqlite error. It also unwraps
/// [DriftRemoteException], which is what the background-isolate connection
/// wraps every failure in — three repositories each had their own copy of
/// this, and two of them forgot the unwrap, burying the real cause a level
/// deeper than the code reading it expected.
///
/// [onUniqueViolation] turns a UNIQUE failure into the domain exception that
/// names what actually collided; without it, one becomes a plain
/// [StorageException].
Future<T> guardStorage<T>(
  Future<T> Function() action, {
  AppException Function()? onUniqueViolation,
}) async {
  try {
    return await action();
  } on AppException {
    rethrow;
  } catch (e) {
    final cause = e is DriftRemoteException ? e.remoteCause : e;

    if (cause is AppException) throw cause;
    if (onUniqueViolation != null &&
        cause is SqliteException &&
        cause.extendedResultCode == uniqueViolation) {
      throw onUniqueViolation();
    }
    throw StorageException(cause);
  }
}
