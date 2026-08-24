import 'dart:io';

import 'package:benesnap/data/db/app_database.dart';
import 'package:benesnap/data/exceptions.dart';
import 'package:benesnap/data/models/product.dart';
import 'package:benesnap/data/models/suitability_tag.dart';
import 'package:benesnap/data/repositories/product_repository.dart';
import 'package:benesnap/data/repositories/tag_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

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

        final dryTagId = _createV1Database(dbFile);

        final db = AppDatabase(NativeDatabase(dbFile));
        addTearDown(db.close);
        final tags = TagRepository(db);
        final products = ProductRepository(db);

        final allTags = await tags.all();

        // Every v1 seed slot survives, now labelled in Arabic.
        expect(
          allTags.where((t) => t.category == TagCategory.skin),
          hasLength(7),
        );
        expect(
          allTags.where((t) => t.category == TagCategory.hair),
          hasLength(10),
        );
        expect(allTags.map((t) => t.label), contains('جافة'));
        expect(allTags.map((t) => t.label), isNot(contains('Dry')));

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

      _createV1Database(dbFile);

      final first = AppDatabase(NativeDatabase(dbFile));
      final firstCount = await TagRepository(first).all();
      await first.close();

      final second = AppDatabase(NativeDatabase(dbFile));
      addTearDown(second.close);
      final secondCount = await TagRepository(second).all();

      expect(secondCount.length, firstCount.length);
    });
  });
}

/// Builds a database file shaped exactly like a v1 (`schemaVersion == 1`)
/// BeneSnap database: the original English seed, inserted in the same order
/// the old seed used, plus one product linked to the 'Dry' tag — so the
/// migration test can verify that an existing product-tag link survives the
/// v1-to-v2 upgrade. Returns the id assigned to the 'Dry' row.
int _createV1Database(File dbFile) {
  final raw = sqlite3.sqlite3.open(dbFile.path);

  raw.execute('''
    CREATE TABLE products (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      barcode TEXT NOT NULL UNIQUE,
      brand_name TEXT NOT NULL,
      product_name TEXT NOT NULL,
      key_ingredients TEXT NOT NULL,
      core_benefits TEXT NOT NULL,
      image_path TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
    CREATE TABLE suitability_tags (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      label TEXT NOT NULL,
      category TEXT NOT NULL,
      UNIQUE(label, category)
    );
    CREATE TABLE product_tags (
      product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
      tag_id INTEGER NOT NULL REFERENCES suitability_tags(id) ON DELETE CASCADE,
      PRIMARY KEY(product_id, tag_id)
    );
    CREATE TABLE admins (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      created_at INTEGER NOT NULL
    );
  ''');

  const skinTypes = [
    'Normal',
    'Dry',
    'Oily',
    'Combination',
    'Sensitive',
    'Acne-prone',
    'Mature',
  ];
  const hairTypes = [
    'Straight',
    'Wavy',
    'Curly',
    'Coily',
    'Fine',
    'Thick',
    'Oily scalp',
    'Dry scalp',
    'Colour-treated',
    'Damaged',
  ];

  final insertTag = raw.prepare(
    'INSERT INTO suitability_tags (label, category) VALUES (?, ?)',
  );
  for (final label in skinTypes) {
    insertTag.execute([label, 'skin']);
  }
  for (final label in hairTypes) {
    insertTag.execute([label, 'hair']);
  }
  insertTag.close();

  final dryId =
      raw
              .select("SELECT id FROM suitability_tags WHERE label = 'Dry'")
              .first['id']
          as int;

  final now = DateTime.now().millisecondsSinceEpoch;
  raw.execute(
    'INSERT INTO products '
    '(barcode, brand_name, product_name, key_ingredients, core_benefits, '
    'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
    ['MIGRATE1', 'Brand', 'Product', 'Water', 'Shine', now, now],
  );
  final productId = raw.lastInsertRowId;

  raw.execute('INSERT INTO product_tags (product_id, tag_id) VALUES (?, ?)', [
    productId,
    dryId,
  ]);

  raw.execute('PRAGMA user_version = 1');
  raw.close();

  return dryId;
}
