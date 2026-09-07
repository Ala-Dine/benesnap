// Guards the one path in this app that can destroy a shop's real catalogue:
// opening an installed database that was created by an earlier version.
//
// `AppDatabase.migration`'s `onUpgrade` is subtle in a way that is easy to
// break by accident — `createTable` builds from the *current* Dart table
// definition rather than a snapshot of the version it is standing in for,
// which is exactly why the v1-to-v3 step has to skip the v3-to-v4 one. That
// reasoning was only ever verified by reading it. These tests verify it by
// running it, against frozen DDL snapshots of what shops actually have on
// disk (see test/helpers/legacy_schemas.dart).

import 'dart:io';

import 'package:benesnap/data/db/app_database.dart';
import 'package:benesnap/data/db/seed.dart';
import 'package:benesnap/data/models/home_text.dart';
import 'package:benesnap/data/models/home_theme.dart';
import 'package:benesnap/data/repositories/product_repository.dart';
import 'package:benesnap/data/repositories/settings_repository.dart';
import 'package:benesnap/data/repositories/tag_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import '../helpers/legacy_schemas.dart';

void main() {
  /// Opens [build]'s database through [AppDatabase], which is what actually
  /// runs the migration, and hands it to the test.
  Future<AppDatabase> upgraded(int Function(File) build) async {
    final dir = Directory.systemTemp.createTempSync('benesnap_migration');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(path.join(dir.path, 'benesnap.sqlite'));

    build(file);

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    // Any query forces the connection open, and with it the migration.
    await db.customSelect('SELECT 1').get();
    return db;
  }

  group('upgrading a v1 database', () {
    test('lands on the current schema version', () async {
      final db = await upgraded(createV1Database);
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data.values.first, db.schemaVersion);
    });

    test('keeps the catalogue', () async {
      final db = await upgraded(createV1Database);
      final product = await ProductRepository(
        db,
      ).findByBarcode(legacyProductBarcode);
      expect(product, isNotNull);
      expect(product!.brandName, 'Brand');
    });

    test('gains app_settings, with the theme column already on it', () async {
      final db = await upgraded(createV1Database);
      final homeText = await SettingsRepository(db).homeText();
      expect(homeText.welcomeTitle, defaultWelcomeTitle);
      expect(homeText.themeKey, defaultHomeThemeKey);
    });

    test('can save a theme straight after upgrading', () async {
      final db = await upgraded(createV1Database);
      final settings = SettingsRepository(db);
      await settings.updateHomeText(
        welcomeTitle: 'مرحبا',
        extraLine: '',
        themeKey: HomeThemeKey.sky,
      );
      expect((await settings.homeText()).themeKey, HomeThemeKey.sky);
    });
  });

  group('upgrading a v3 database', () {
    test('lands on the current schema version', () async {
      final db = await upgraded(createV3Database);
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data.values.first, db.schemaVersion);
    });

    test("keeps the shop's saved welcome text", () async {
      final db = await upgraded(createV3Database);
      final homeText = await SettingsRepository(db).homeText();
      expect(homeText.welcomeTitle, 'أهلًا بكم');
      expect(homeText.extraLine, 'اسأل عن العروض');
    });

    test('adds theme_key, and a row that predates it reads as the '
        'default theme', () async {
      final db = await upgraded(createV3Database);
      expect(
        (await SettingsRepository(db).homeText()).themeKey,
        defaultHomeThemeKey,
      );
    });

    test('keeps the catalogue and its tag links', () async {
      final db = await upgraded(createV3Database);
      final product = await ProductRepository(
        db,
      ).findByBarcode(legacyProductBarcode);
      expect(product, isNotNull);
      expect(product!.tags.single.label, skinSeedLabels[1]);
    });

    test('does not re-add the seeded vocabulary', () async {
      final db = await upgraded(createV3Database);
      final tags = await TagRepository(db).all();
      expect(tags.length, skinSeedLabels.length + hairSeedLabels.length);
    });
  });
}
