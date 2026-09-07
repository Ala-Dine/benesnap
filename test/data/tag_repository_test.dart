import 'dart:io';

import 'package:benesnap/data/db/app_database.dart';
import 'package:benesnap/data/db/seed.dart';
import 'package:benesnap/data/exceptions.dart';
import 'package:benesnap/data/models/product.dart';
import 'package:benesnap/data/models/suitability_tag.dart';
import 'package:benesnap/data/repositories/product_repository.dart';
import 'package:benesnap/data/repositories/tag_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import '../helpers/legacy_schemas.dart';
import '../helpers/test_db.dart';

ProductDraft _draft({String barcode = 'TAGTEST1', Set<int> tagIds = const {}}) {
  return ProductDraft(
    barcode: barcode,
    brandName: 'Brand',
    productName: 'Product',
    keyIngredients: 'Water',
    coreBenefits: 'Shine',
    tagIds: tagIds,
  );
}

void main() {
  group('TagRepository', () {
    late AppDatabase db;
    late TagRepository tags;

    setUp(() {
      db = createTestDatabase();
      tags = TagRepository(db);
    });

    group('createTag', () {
      test('adds a new tag to the vocabulary', () async {
        final created = await tags.createTag('لامعة', TagCategory.skin);

        expect(created.id, greaterThan(0));
        expect(created.label, 'لامعة');
        expect(created.category, TagCategory.skin);
        expect((await tags.all()).map((t) => t.label), contains('لامعة'));
      });

      test('trims surrounding whitespace', () async {
        final created = await tags.createTag('  لامعة  ', TagCategory.skin);
        expect(created.label, 'لامعة');
      });

      test('rejects a duplicate label within the same category', () async {
        await tags.createTag('لامعة', TagCategory.skin);

        expect(
          () => tags.createTag('لامعة', TagCategory.skin),
          throwsA(isA<DuplicateTagException>()),
        );
      });

      test('allows the same label across different categories', () async {
        await tags.createTag('لامعة', TagCategory.skin);

        final hairTag = await tags.createTag('لامعة', TagCategory.hair);

        expect(hairTag.category, TagCategory.hair);
      });
    });

    group('deleteTag', () {
      test('removes the tag', () async {
        final created = await tags.createTag('لامعة', TagCategory.skin);

        await tags.deleteTag(created.id);

        final remaining = await tags.all();
        expect(remaining.map((t) => t.id), isNot(contains(created.id)));
      });

      test('reports a missing tag in plain language', () async {
        expect(
          () => tags.deleteTag(999999),
          throwsA(isA<TagNotFoundException>()),
        );
      });

      test('cascades to product links', () async {
        final products = ProductRepository(db);
        final created = await tags.createTag('لامعة', TagCategory.skin);
        final product = await products.create(_draft(tagIds: {created.id}));

        await tags.deleteTag(created.id);

        final reloaded = await products.findById(product.id);
        expect(reloaded!.tags, isEmpty);
      });

      test('a deleted seeded tag does not come back on reseed', () async {
        final before = await tags.all();
        final target = before.first;

        await tags.deleteTag(target.id);
        // `beforeOpen` reruns the seed on every connection; simulate that
        // directly rather than reopening the database.
        await db.customStatement('PRAGMA foreign_keys = ON');

        final after = await tags.all();
        expect(after.map((t) => t.id), isNot(contains(target.id)));
        expect(after.length, before.length - 1);
      });
    });

    group('productCountForTag', () {
      test('counts how many products carry the tag', () async {
        final products = ProductRepository(db);
        final created = await tags.createTag('لامعة', TagCategory.skin);

        expect(await tags.productCountForTag(created.id), 0);

        await products.create(_draft(tagIds: {created.id}));

        expect(await tags.productCountForTag(created.id), 1);
      });
    });

    group('watchAll', () {
      test('emits again when a tag is created', () async {
        final emissions = <List<SuitabilityTag>>[];
        final sub = tags.watchAll().listen(emissions.add);
        addTearDown(sub.cancel);

        await pumpEventQueue();
        final before = emissions.last.length;

        await tags.createTag('لامعة', TagCategory.skin);
        await pumpEventQueue();

        expect(emissions.last.length, before + 1);
      });
    });
  });

  group('v1 to v2 migration', () {
    test(
      'relabels the seed to Arabic and keeps existing product links',
      () async {
        final dir = Directory.systemTemp.createTempSync(
          'benesnap_migration_test',
        );
        addTearDown(() => dir.deleteSync(recursive: true));
        final dbFile = File(path.join(dir.path, 'v1.sqlite'));

        final dryTagId = createV1Database(dbFile);

        final db = AppDatabase(NativeDatabase(dbFile));
        addTearDown(db.close);
        final tags = TagRepository(db);
        final products = ProductRepository(db);

        final allTags = await tags.all();

        final skinLabels = allTags
            .where((t) => t.category == TagCategory.skin)
            .map((t) => t.label)
            .toList();
        final hairLabels = allTags
            .where((t) => t.category == TagCategory.hair)
            .map((t) => t.label)
            .toList();

        // Every v1 seed slot survives, now labelled in Arabic — renamed in
        // place rather than left behind alongside an Arabic copy, which the
        // no-duplicates check below is what actually pins down.
        expect(
          skinLabels,
          containsAll(skinSeedLabels.take(legacySkinLabels.length)),
        );
        expect(
          hairLabels,
          containsAll(hairSeedLabels.take(legacyHairLabels.length)),
        );
        expect(skinLabels.toSet(), hasLength(skinLabels.length));
        expect(hairLabels.toSet(), hasLength(hairLabels.length));
        expect(allTags.map((t) => t.label), isNot(contains('Dry')));

        // The same open also hands this shop the vocabulary added after v1:
        // those slots have no entry in the offers ledger yet, so the seed
        // inserts them. Counted against the lists rather than a literal, so
        // appending more later doesn't need this test edited.
        expect(skinLabels, hasLength(skinSeedLabels.length));
        expect(hairLabels, hasLength(hairSeedLabels.length));

        // The row that was 'Dry' in v1 kept its id, so the product that
        // referenced it still resolves to the (now Arabic) tag.
        final relabeled = allTags.firstWhere((t) => t.id == dryTagId);
        expect(relabeled.label, 'جافة');

        final product = await products.findByBarcode('MIGRATE1');
        expect(product, isNotNull);
        expect(product!.tags.map((t) => t.id), contains(dryTagId));
        expect(product.tags.single.label, 'جافة');
      },
    );

    test('a second open does not duplicate the relabeled seed', () async {
      final dir = Directory.systemTemp.createTempSync(
        'benesnap_migration_test',
      );
      addTearDown(() => dir.deleteSync(recursive: true));
      final dbFile = File(path.join(dir.path, 'v1.sqlite'));

      createV1Database(dbFile);

      final first = AppDatabase(NativeDatabase(dbFile));
      final firstCount = await TagRepository(first).all();
      await first.close();

      final second = AppDatabase(NativeDatabase(dbFile));
      addTearDown(second.close);
      final secondCount = await TagRepository(second).all();

      expect(secondCount.length, firstCount.length);
    });
  });

  // What every already-installed shop does on its next launch when the seed
  // lists grow: `beforeOpen` reruns the seed, finds slots with no entry in
  // the offers ledger, and inserts just those.
  group('growing the seed vocabulary', () {
    /// Rewinds [db] to the vocabulary as it stood when only the first
    /// [skinSlots]/[hairSlots] entries existed — tags and ledger both, which
    /// together are exactly what an older install carries.
    Future<void> rewindToOlderVocabulary(
      AppDatabase db, {
      required int skinSlots,
      required int hairSlots,
    }) async {
      await db.delete(db.suitabilityTags).go();
      await db.delete(db.seededTagOffers).go();

      Future<void> offer(TagCategory category, List<String> labels) async {
        for (final (index, label) in labels.indexed) {
          await db
              .into(db.suitabilityTags)
              .insert(
                SuitabilityTagsCompanion.insert(
                  label: label,
                  category: category,
                ),
              );
          await db
              .into(db.seededTagOffers)
              .insert(
                SeededTagOffersCompanion.insert(
                  category: category,
                  seedIndex: index,
                ),
              );
        }
      }

      await offer(TagCategory.skin, skinSeedLabels.take(skinSlots).toList());
      await offer(TagCategory.hair, hairSeedLabels.take(hairSlots).toList());
    }

    test('an older install picks up entries added since', () async {
      final db = createTestDatabase();
      final tags = TagRepository(db);
      await rewindToOlderVocabulary(db, skinSlots: 7, hairSlots: 10);
      final before = await tags.all();

      await seedSuitabilityTags(db);

      // Guards the test itself as much as the seed: were the lists ever
      // trimmed back to the 7/10 they started at, the rewind above would be
      // a no-op and every assertion below would pass without the seed having
      // inserted anything at all.
      final after = await tags.all();
      expect(after.length, greaterThan(before.length));

      final labels = after.map((t) => t.label);
      expect(labels, containsAll(skinSeedLabels));
      expect(labels, containsAll(hairSeedLabels));
      expect(labels, hasLength(skinSeedLabels.length + hairSeedLabels.length));
    });

    test('and does not get a second copy on the launch after that', () async {
      final db = createTestDatabase();
      await rewindToOlderVocabulary(db, skinSlots: 7, hairSlots: 10);

      await seedSuitabilityTags(db);
      await seedSuitabilityTags(db);

      final labels = (await TagRepository(db).all()).map((t) => t.label);
      expect(labels, hasLength(skinSeedLabels.length + hairSeedLabels.length));
    });

    test('an entry the shop deleted stays deleted', () async {
      final db = createTestDatabase();
      final tags = TagRepository(db);
      final target = (await tags.all()).firstWhere(
        (t) => t.label == skinSeedLabels.last,
      );

      await tags.deleteTag(target.id);
      await seedSuitabilityTags(db);

      expect(
        (await tags.all()).map((t) => t.label),
        isNot(contains(target.label)),
      );
    });
  });
}
