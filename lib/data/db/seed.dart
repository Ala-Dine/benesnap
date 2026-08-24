import '../models/suitability_tag.dart';
import 'app_database.dart';

/// The suitability vocabulary the shop starts with.
///
/// Position-parallel with the v1 English seed this replaced — see
/// [AppDatabase.migration]'s v1-to-v2 step, which relabels existing rows by
/// this same order rather than reinserting them.
const skinSeedLabels = <String>[
  'عادية',
  'جافة',
  'دهنية',
  'مختلطة',
  'حساسة',
  'معرّضة لحب الشباب',
  'ناضجة',
];

const hairSeedLabels = <String>[
  'مستقيم',
  'متموج',
  'مجعد',
  'شديد التجعد',
  'خفيف',
  'كثيف',
  'فروة دهنية',
  'فروة جافة',
  'مصبوغ',
  'تالف',
];

/// Inserts any seed slot that hasn't been offered yet, per
/// [AppDatabase.seededTagOffers].
///
/// Idempotent, and runs on every open rather than only on create: a shop can
/// delete a seeded tag and it stays gone, but a database made by an earlier
/// build still picks up any slot it never saw before (e.g. one added in a
/// later release).
Future<void> seedSuitabilityTags(AppDatabase db) async {
  final offered = await db.select(db.seededTagOffers).get();
  final offeredKeys = offered
      .map((row) => '${row.category.name}:${row.seedIndex}')
      .toSet();

  final newTags = <SuitabilityTagsCompanion>[];
  final newOffers = <SeededTagOffersCompanion>[];

  void queue(TagCategory category, List<String> labels) {
    for (final (index, label) in labels.indexed) {
      if (offeredKeys.contains('${category.name}:$index')) continue;
      newTags.add(
        SuitabilityTagsCompanion.insert(label: label, category: category),
      );
      newOffers.add(
        SeededTagOffersCompanion.insert(category: category, seedIndex: index),
      );
    }
  }

  queue(TagCategory.skin, skinSeedLabels);
  queue(TagCategory.hair, hairSeedLabels);

  if (newTags.isEmpty) return;

  await db.batch((batch) {
    batch.insertAll(db.suitabilityTags, newTags);
    batch.insertAll(db.seededTagOffers, newOffers);
  });
}
