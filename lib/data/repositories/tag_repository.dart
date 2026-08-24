import 'package:drift/drift.dart';
// The whole `drift/remote.dart` library is marked experimental, but this is
// the only supported way to unwrap an exception thrown across the
// `NativeDatabase.createInBackground` isolate boundary.
// ignore: experimental_member_use
import 'package:drift/remote.dart' show DriftRemoteException;
import 'package:sqlite3/common.dart' show SqliteException;

import '../db/app_database.dart';
import '../exceptions.dart';
import '../models/suitability_tag.dart';

/// The only place that reads or writes the suitability tag vocabulary.
class TagRepository {
  TagRepository(this._db);

  final AppDatabase _db;

  /// SQLite's extended result code for a UNIQUE constraint failure.
  static const _uniqueViolation = 2067;

  Future<List<SuitabilityTag>> all() => _guard(() async {
    final rows = await (_db.select(
      _db.suitabilityTags,
    )..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
    return rows.map(_toTag).toList();
  });

  Future<List<SuitabilityTag>> byCategory(TagCategory category) async {
    final tags = await all();
    return tags.where((t) => t.category == category).toList();
  }

  /// Emits a fresh list whenever the vocabulary changes, so an open add/edit
  /// form picks up a tag created or deleted from elsewhere.
  Stream<List<SuitabilityTag>> watchAll() {
    final query = _db.select(_db.suitabilityTags)
      ..orderBy([(t) => OrderingTerm(expression: t.id)]);
    return query.watch().map((rows) => rows.map(_toTag).toList());
  }

  /// Adds a tag to the vocabulary. [label] must be unique within
  /// [category] — the same wording can be both a skin and a hair tag.
  Future<SuitabilityTag> createTag(String label, TagCategory category) =>
      _guard(() async {
        final trimmed = label.trim();
        final id = await _db
            .into(_db.suitabilityTags)
            .insert(
              SuitabilityTagsCompanion.insert(
                label: trimmed,
                category: category,
              ),
            );
        return SuitabilityTag(id: id, label: trimmed, category: category);
      }, label: label);

  /// Hard-deletes a tag. Existing product links are cleaned up by the
  /// `product_tags` foreign-key cascade — no manual join-table logic needed.
  Future<void> deleteTag(int id) => _guard(() async {
    final removed = await (_db.delete(
      _db.suitabilityTags,
    )..where((t) => t.id.equals(id))).go();
    if (removed == 0) throw const TagNotFoundException();
  });

  /// How many products currently carry this tag — shown in the
  /// delete-confirmation dialog before [deleteTag] is called.
  Future<int> productCountForTag(int id) => _guard(() async {
    final rows =
        await (_db.selectOnly(_db.productTags)
              ..addColumns([_db.productTags.productId.count()])
              ..where(_db.productTags.tagId.equals(id)))
            .getSingle();
    return rows.read(_db.productTags.productId.count()) ?? 0;
  });

  /// Runs [action], translating storage failures into [AppException]s.
  ///
  /// A UNIQUE violation on a write that carried a [label] is by definition
  /// the `(label, category)` index, since it is the only unique constraint on
  /// this table.
  Future<T> _guard<T>(Future<T> Function() action, {String? label}) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (e) {
      // The background isolate wraps failures, so the SqliteException we care
      // about arrives inside a DriftRemoteException.
      final cause = e is DriftRemoteException ? e.remoteCause : e;

      if (cause is AppException) throw cause;
      if (label != null &&
          cause is SqliteException &&
          cause.extendedResultCode == _uniqueViolation) {
        throw DuplicateTagException(label);
      }
      throw StorageException(cause);
    }
  }

  static SuitabilityTag _toTag(SuitabilityTagRow row) =>
      SuitabilityTag(id: row.id, label: row.label, category: row.category);
}
