import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../exceptions.dart';
import '../models/suitability_tag.dart';
import 'row_mappers.dart';
import 'storage_guard.dart';

/// The only place that reads or writes the suitability tag vocabulary.
class TagRepository {
  TagRepository(this._db);

  final AppDatabase _db;

  Future<List<SuitabilityTag>> all() => guardStorage(() async {
    final rows = await (_db.select(
      _db.suitabilityTags,
    )..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
    return rows.map(tagFromRow).toList();
  });

  /// Emits a fresh list whenever the vocabulary changes, so an open add/edit
  /// form picks up a tag created or deleted from elsewhere.
  Stream<List<SuitabilityTag>> watchAll() {
    final query = _db.select(_db.suitabilityTags)
      ..orderBy([(t) => OrderingTerm(expression: t.id)]);
    return query.watch().map((rows) => rows.map(tagFromRow).toList());
  }

  /// Adds a tag to the vocabulary. [label] must be unique within
  /// [category] — the same wording can be both a skin and a hair tag.
  Future<SuitabilityTag> createTag(String label, TagCategory category) =>
      guardStorage(() async {
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
      }, onUniqueViolation: () => DuplicateTagException(label));

  /// Hard-deletes a tag. Existing product links are cleaned up by the
  /// `product_tags` foreign-key cascade — no manual join-table logic needed.
  Future<void> deleteTag(int id) => guardStorage(() async {
    final removed = await (_db.delete(
      _db.suitabilityTags,
    )..where((t) => t.id.equals(id))).go();
    if (removed == 0) throw const TagNotFoundException();
  });

  /// How many products currently carry this tag — shown in the
  /// delete-confirmation dialog before [deleteTag] is called.
  Future<int> productCountForTag(int id) => guardStorage(() async {
    final rows =
        await (_db.selectOnly(_db.productTags)
              ..addColumns([_db.productTags.productId.count()])
              ..where(_db.productTags.tagId.equals(id)))
            .getSingle();
    return rows.read(_db.productTags.productId.count()) ?? 0;
  });
}
