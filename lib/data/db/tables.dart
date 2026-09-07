import 'package:drift/drift.dart';

import '../models/home_theme.dart' show HomeThemeKey, defaultHomeThemeKey;
import '../models/suitability_tag.dart' show TagCategory;

/// Sorted by brand on every read — the catalogue list, the search, and the
/// live stream feeding the inventory grid all order by it — so it earns an
/// index rather than a sort per query.
@TableIndex(name: 'products_brand_name', columns: {#brandName})
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

/// The composite primary key indexes `(product_id, tag_id)`, which only
/// helps predicates leading with `product_id`. Two things go the other way
/// and would otherwise scan the whole join table: counting how many products
/// carry a tag (shown before confirming a tag delete), and the ON DELETE
/// CASCADE from `suitability_tags`, which SQLite implements as a child-table
/// scan per deleted parent row.
@TableIndex(name: 'product_tags_tag_id', columns: {#tagId})
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

  /// A [HomeThemeKey.name], e.g. `"sand"` — never the raw colour values.
  /// Null until the shop picks one; [SettingsRepository] falls back to
  /// [defaultHomeThemeKey] the same way it does for the text fields.
  TextColumn get themeKey => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
