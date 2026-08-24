import 'package:drift/drift.dart';

import '../models/suitability_tag.dart' show TagCategory;

@DataClassName('ProductRow')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The scan lookup key. Unique — see [Products.uniqueKeys].
  TextColumn get barcode => text().withLength(min: 1, max: 128)();

  TextColumn get brandName => text().withLength(min: 1, max: 200)();
  TextColumn get productName => text().withLength(min: 1, max: 200)();
  TextColumn get keyIngredients => text()();
  TextColumn get coreBenefits => text()();

  /// Filename relative to the `images/` folder beside the database, so the
  /// catalogue survives the app being moved or reinstalled.
  TextColumn get imagePath => text().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {barcode},
  ];
}

@DataClassName('SuitabilityTagRow')
class SuitabilityTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text().withLength(min: 1, max: 60)();
  TextColumn get category => textEnum<TagCategory>()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {label, category},
  ];
}

@DataClassName('ProductTagRow')
class ProductTags extends Table {
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(SuitabilityTags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {productId, tagId};
}

/// An append-only ledger of which seed vocabulary slots have already been
/// offered to the catalogue, keyed by category and position in the seed
/// list — not by the tag row itself.
///
/// Independent of [SuitabilityTags] on purpose: once a slot is recorded
/// here, [seedSuitabilityTags] never inserts it again, even after a shop
/// deletes the tag it produced. A soft-delete flag on [SuitabilityTags]
/// would have needed a `WHERE deleted = 0` filter on every query that table;
/// this keeps that concern in exactly one place.
@DataClassName('SeededTagOfferRow')
class SeededTagOffers extends Table {
  TextColumn get category => textEnum<TagCategory>()();
  IntColumn get seedIndex => integer()();

  @override
  Set<Column> get primaryKey => {category, seedIndex};
}

@DataClassName('AdminRow')
class Admins extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 1, max: 60)();

  /// bcrypt hash. Plaintext is never stored.
  TextColumn get passwordHash => text()();

  IntColumn get createdAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {username},
  ];
}

/// The shop's customizable kiosk homepage text. At most one row (id fixed at
/// 1) — absent until the shop customizes it for the first time.
/// [SettingsRepository] falls back to sensible defaults when this table is
/// empty, so no seed step is needed.
@DataClassName('AppSettingsRow')
class AppSettings extends Table {
  IntColumn get id => integer()();
  TextColumn get welcomeTitle => text()();
  TextColumn get extraLine => text()();

  @override
  Set<Column> get primaryKey => {id};
}
