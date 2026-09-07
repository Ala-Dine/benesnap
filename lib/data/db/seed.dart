import '../models/suitability_tag.dart';
import 'app_database.dart';

/// The suitability vocabulary the shop starts with.
///
/// **Append only — never insert, reorder, or delete an entry.** Position *is*
/// identity here: [seedSuitabilityTags] records offered slots by index in
/// [AppDatabase.seededTagOffers], and [AppDatabase.migration]'s v1-to-v2 step
/// relabels existing rows by this same order rather than by text. Reordering
/// would relabel a shop's existing tags into the wrong meanings and re-offer
/// vocabulary it had deliberately deleted; appending is safe, and is how a
/// later release hands new entries to shops already running.
///
/// The leading entries stay position-parallel with the v1 English seed this
/// replaced (`legacySkinLabels`/`legacyHairLabels` in the tests); everything
/// past them was added afterwards and has no v1 counterpart.
///
/// Deliberately broad rather than minimal: a shop assistant tagging a new
/// product should almost always find the wording already here, since adding
/// one costs a detour through the "add tag" field on every product that
/// needs it.
const skinSeedLabels = <String>[
  // The original v1 vocabulary.
  'عادية',
  'جافة',
  'دهنية',
  'مختلطة',
  'حساسة',
  'معرّضة لحب الشباب',
  'ناضجة',
  // Added since: the concerns a cosmetics counter actually labels by.
  'جميع أنواع البشرة',
  'باهتة',
  'تصبغات',
  'احمرار',
  'مسام واسعة',
  'تجاعيد',
  'هالات سوداء',
  'بشرة الأطفال',
];

const hairSeedLabels = <String>[
  // The original v1 vocabulary.
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
  // Added since. Note the hair/scalp split the original only had for
  // oiliness and dryness of the *scalp*: a mask for dry lengths and a serum
  // for a dry scalp are different products, so both now have wording.
  'جميع أنواع الشعر',
  'جاف',
  'دهني',
  'هايش',
  'متقصف',
  'باهت',
  'قشرة',
  'تساقط',
  'فروة حساسة',
  'معالج كيميائيًا',
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
