/// Frozen snapshots of BeneSnap's older on-disk schemas, for migration tests.
///
/// These are deliberately hand-written rather than built from the current
/// drift table definitions: the whole point is to reproduce what a shop's
/// installed database actually looks like, which is exactly what the current
/// definitions no longer describe. `AppDatabase.migration`'s `onUpgrade`
/// builds tables from today's Dart definitions (see the comment on its
/// v1-to-v3 step), so a snapshot generated from those definitions would
/// quietly test nothing.
///
/// The DDL below was taken verbatim from what drift emits, minus the tables
/// and columns each version predates.
library;

import 'dart:io';

import 'package:benesnap/data/db/seed.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// The four tables that have existed unchanged since v1.
const _coreDdl = '''
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
''';

/// The v1 English seed vocabulary, in the order the v1 seed inserted it.
///
/// Position-parallel with [skinSeedLabels]/[hairSeedLabels] — that pairing is
/// the entire basis of the v1-to-v2 relabel, which matches rows by id order
/// rather than by text.
const legacySkinLabels = [
  'Normal',
  'Dry',
  'Oily',
  'Combination',
  'Sensitive',
  'Acne-prone',
  'Mature',
];

const legacyHairLabels = [
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

/// The barcode of the single product every fixture below carries, so a test
/// can assert the catalogue survived an upgrade.
const legacyProductBarcode = 'MIGRATE1';

/// Builds a database file shaped exactly like a v1 BeneSnap database: the
/// original English seed, plus one product linked to the 'Dry' tag.
///
/// Returns the id assigned to the 'Dry' row.
int createV1Database(File dbFile) {
  final raw = sqlite3.sqlite3.open(dbFile.path);
  raw.execute(_coreDdl);

  final insertTag = raw.prepare(
    'INSERT INTO suitability_tags (label, category) VALUES (?, ?)',
  );
  for (final label in legacySkinLabels) {
    insertTag.execute([label, 'skin']);
  }
  for (final label in legacyHairLabels) {
    insertTag.execute([label, 'hair']);
  }
  insertTag.close();

  final dryId =
      raw
              .select("SELECT id FROM suitability_tags WHERE label = 'Dry'")
              .first['id']
          as int;

  _insertProduct(raw, tagId: dryId);

  raw.execute('PRAGMA user_version = 1');
  raw.close();

  return dryId;
}

/// Builds a database file shaped like a v3 BeneSnap database — the last
/// version before the theme picker: the Arabic seed with every slot already
/// recorded as offered, an `app_settings` row with no `theme_key` column at
/// all, an admin, and one product linked to the 'جافة' tag.
///
/// Returns the id assigned to that tag.
int createV3Database(
  File dbFile, {
  String welcomeTitle = 'أهلًا بكم',
  String extraLine = 'اسأل عن العروض',
}) {
  final raw = sqlite3.sqlite3.open(dbFile.path);
  raw.execute(_coreDdl);
  raw.execute('''
    CREATE TABLE seeded_tag_offers (
      category TEXT NOT NULL,
      seed_index INTEGER NOT NULL,
      PRIMARY KEY(category, seed_index)
    );
    CREATE TABLE app_settings (
      id INTEGER NOT NULL,
      welcome_title TEXT NOT NULL,
      extra_line TEXT NOT NULL,
      PRIMARY KEY(id)
    );
  ''');

  final insertTag = raw.prepare(
    'INSERT INTO suitability_tags (label, category) VALUES (?, ?)',
  );
  final insertOffer = raw.prepare(
    'INSERT INTO seeded_tag_offers (category, seed_index) VALUES (?, ?)',
  );
  for (final (index, label) in skinSeedLabels.indexed) {
    insertTag.execute([label, 'skin']);
    insertOffer.execute(['skin', index]);
  }
  for (final (index, label) in hairSeedLabels.indexed) {
    insertTag.execute([label, 'hair']);
    insertOffer.execute(['hair', index]);
  }
  insertTag.close();
  insertOffer.close();

  final dryId =
      raw.select('SELECT id FROM suitability_tags WHERE label = ?', [
            skinSeedLabels[1],
          ]).first['id']
          as int;

  _insertProduct(raw, tagId: dryId);

  raw.execute(
    'INSERT INTO admins (username, password_hash, created_at) '
    'VALUES (?, ?, ?)',
    ['owner', r'$2b$10$notarealhashjustaplaceholdervalue00000000', 0],
  );
  raw.execute(
    'INSERT INTO app_settings (id, welcome_title, extra_line) VALUES (?, ?, ?)',
    [1, welcomeTitle, extraLine],
  );

  raw.execute('PRAGMA user_version = 3');
  raw.close();

  return dryId;
}

void _insertProduct(sqlite3.Database raw, {required int tagId}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  raw.execute(
    'INSERT INTO products '
    '(barcode, brand_name, product_name, key_ingredients, core_benefits, '
    'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [legacyProductBarcode, 'Brand', 'Product', 'Water', 'Shine', now, now],
  );
  raw.execute('INSERT INTO product_tags (product_id, tag_id) VALUES (?, ?)', [
    raw.lastInsertRowId,
    tagId,
  ]);
}
