import 'package:drift/drift.dart';

import '../models/suitability_tag.dart';
import 'seed.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    SuitabilityTags,
    ProductTags,
    Admins,
    SeededTagOffers,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(seededTagOffers);
        await _relabelSeedToArabic();
      }
      if (from < 3) {
        await m.createTable(appSettings);
      }
    },
    beforeOpen: (details) async {
      // `product_tags` relies on cascade deletes, which SQLite only honours
      // when foreign keys are switched on — and that is per-connection.
      await customStatement('PRAGMA foreign_keys = ON');
      await seedSuitabilityTags(this);
    },
  );

  /// Renames the v1 English seed labels to their v2 Arabic equivalents in
  /// place, and records each relabeled slot in [seededTagOffers] so
  /// [seedSuitabilityTags] never reinserts it — even after a shop later
  /// deletes it.
  ///
  /// Matches existing rows to the new label lists by position
  /// (`ORDER BY id ASC`). Safe only because v1 never shipped a create-tag
  /// feature: every v1 database holds exactly the rows from one ordered
  /// batch insert, so id order reconstructs the original seed order.
  /// Defensive against a shorter-than-expected row count (never asserts an
  /// exact match) since nothing prevents seed lists from growing later.
  Future<void> _relabelSeedToArabic() async {
    Future<void> relabel(TagCategory category, List<String> labels) async {
      final rows =
          await (select(suitabilityTags)
                ..where((t) => t.category.equalsValue(category))
                ..orderBy([(t) => OrderingTerm(expression: t.id)]))
              .get();

      final pairCount = rows.length < labels.length
          ? rows.length
          : labels.length;

      for (var i = 0; i < pairCount; i++) {
        await (update(suitabilityTags)..where((t) => t.id.equals(rows[i].id)))
            .write(SuitabilityTagsCompanion(label: Value(labels[i])));
        await into(seededTagOffers).insert(
          SeededTagOffersCompanion.insert(category: category, seedIndex: i),
        );
      }
    }

    await relabel(TagCategory.skin, skinSeedLabels);
    await relabel(TagCategory.hair, hairSeedLabels);
  }
}
