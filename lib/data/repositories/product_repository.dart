import 'package:drift/drift.dart';
import 'package:sqlite3/common.dart' show SqliteException;

import '../db/app_database.dart';
import '../exceptions.dart';
import 'storage_guard.dart';
import '../models/product.dart';
import '../models/suitability_tag.dart';
import 'row_mappers.dart';

/// The only place that reads or writes product rows.
///
/// Widgets and providers talk to this; nothing above it sees a drift type or a
/// [SqliteException].
class ProductRepository {
  ProductRepository(this._db);

  final AppDatabase _db;

  Future<List<Product>> all() => guardStorage(() async {
    final rows = await (_db.select(
      _db.products,
    )..orderBy([(p) => OrderingTerm(expression: p.brandName)])).get();
    return _attachTags(rows);
  });

  Future<Product?> findById(int id) => guardStorage(() => _findById(id));

  /// The unguarded body of [findById], for callers already inside `_guard`
  /// (and, in [create]/[update], inside a transaction that must not be
  /// unwound by a nested guard).
  Future<Product?> _findById(int id) async {
    final row = await (_db.select(
      _db.products,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return (await _attachTags([row])).first;
  }

  /// The scan path. [barcode] is expected to be normalized already.
  Future<Product?> findByBarcode(String barcode) => guardStorage(() async {
    final row = await (_db.select(
      _db.products,
    )..where((p) => p.barcode.equals(barcode))).getSingleOrNull();
    if (row == null) return null;
    return (await _attachTags([row])).first;
  });

  Future<Product> create(ProductDraft draft) => guardStorage(() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // The read-back happens inside the transaction. Outside it, a concurrent
    // delete between the insert and the read made a write that had actually
    // succeeded report ProductNotFoundException.
    return _db.transaction(() async {
      await _assertBarcodeFree(draft.barcode);
      final newId = await _db
          .into(_db.products)
          .insert(
            ProductsCompanion.insert(
              barcode: draft.barcode,
              brandName: draft.brandName,
              productName: draft.productName,
              keyIngredients: draft.keyIngredients,
              coreBenefits: draft.coreBenefits,
              imagePath: Value(draft.imagePath),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _replaceTags(newId, draft.tagIds);

      final created = await _findById(newId);
      if (created == null) throw const ProductNotFoundException();
      return created;
    });
  }, onUniqueViolation: () => DuplicateBarcodeException(draft.barcode));

  Future<Product> update(int id, ProductDraft draft) => guardStorage(() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Read back inside the transaction, for the same reason as create.
    return _db.transaction(() async {
      await _assertBarcodeFree(draft.barcode, excludingId: id);
      final changed =
          await (_db.update(_db.products)..where((p) => p.id.equals(id))).write(
            ProductsCompanion(
              barcode: Value(draft.barcode),
              brandName: Value(draft.brandName),
              productName: Value(draft.productName),
              keyIngredients: Value(draft.keyIngredients),
              coreBenefits: Value(draft.coreBenefits),
              imagePath: Value(draft.imagePath),
              updatedAt: Value(now),
            ),
          );
      if (changed == 0) throw const ProductNotFoundException();
      await _replaceTags(id, draft.tagIds);

      final updated = await _findById(id);
      if (updated == null) throw const ProductNotFoundException();
      return updated;
    });
  }, onUniqueViolation: () => DuplicateBarcodeException(draft.barcode));

  /// Deletes the product and returns the `imagePath` it was holding, so the
  /// caller can remove the file too.
  ///
  /// The row and the file are owned together but stored apart — the database
  /// only ever keeps a filename — so nothing else can work out afterwards
  /// which file belonged to a row that no longer exists. Reading it inside
  /// the same transaction as the delete is what makes the pair reliable.
  Future<String?> delete(int id) => guardStorage(() async {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.products,
      )..where((p) => p.id.equals(id))).getSingleOrNull();
      if (row == null) throw const ProductNotFoundException();

      await (_db.delete(_db.products)..where((p) => p.id.equals(id))).go();
      return row.imagePath;
    });
  });

  /// Emits a fresh list whenever the catalogue changes, so the inventory grid
  /// updates itself after an edit in another route.
  ///
  /// Declares the tag tables as sources, not just `products`: every emitted
  /// [Product] carries its tags, and deleting a tag writes
  /// `suitability_tags` and cascades through `product_tags` without touching
  /// `products` at all — so a plain `select(products).watch()` went on
  /// showing a tag that no longer existed until some unrelated product write
  /// happened to come along. The `SELECT 1` is a trigger, not a result: it
  /// exists so drift knows which tables to re-run [all] for.
  Stream<List<Product>> watchAll() {
    return _db
        .customSelect(
          'SELECT 1',
          readsFrom: {_db.products, _db.productTags, _db.suitabilityTags},
        )
        .watch()
        .asyncMap((_) => all());
  }

  /// Rejects a barcode already used by a different product.
  ///
  /// The unique index is the real guarantee; this check exists so the common
  /// case produces a clear message rather than depending on how the driver
  /// happens to surface a constraint failure.
  Future<void> _assertBarcodeFree(String barcode, {int? excludingId}) async {
    final query = _db.select(_db.products)
      ..where((p) => p.barcode.equals(barcode));
    if (excludingId != null) {
      query.where((p) => p.id.equals(excludingId).not());
    }

    if (await query.getSingleOrNull() != null) {
      throw DuplicateBarcodeException(barcode);
    }
  }

  Future<void> _replaceTags(int productId, Set<int> tagIds) async {
    await (_db.delete(
      _db.productTags,
    )..where((t) => t.productId.equals(productId))).go();

    if (tagIds.isEmpty) return;

    await _db.batch(
      (batch) => batch.insertAll(_db.productTags, [
        for (final tagId in tagIds)
          ProductTagsCompanion.insert(productId: productId, tagId: tagId),
      ]),
    );
  }

  /// Resolves tags for [rows] in one round trip rather than one query per
  /// product, which matters once the grid holds a few hundred items.
  Future<List<Product>> _attachTags(List<ProductRow> rows) async {
    if (rows.isEmpty) return const [];

    final ids = rows.map((r) => r.id).toList();
    final joined = await (_db.select(_db.productTags).join([
      innerJoin(
        _db.suitabilityTags,
        _db.suitabilityTags.id.equalsExp(_db.productTags.tagId),
      ),
    ])..where(_db.productTags.productId.isIn(ids))).get();

    final byProduct = <int, List<SuitabilityTag>>{};
    for (final row in joined) {
      final link = row.readTable(_db.productTags);
      final tag = row.readTable(_db.suitabilityTags);
      byProduct.putIfAbsent(link.productId, () => []).add(tagFromRow(tag));
    }

    return [
      for (final row in rows) _toProduct(row, byProduct[row.id] ?? const []),
    ];
  }

  static Product _toProduct(ProductRow row, List<SuitabilityTag> tags) {
    return Product(
      id: row.id,
      barcode: row.barcode,
      brandName: row.brandName,
      productName: row.productName,
      keyIngredients: row.keyIngredients,
      coreBenefits: row.coreBenefits,
      imagePath: row.imagePath,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      tags: tags,
    );
  }
}
