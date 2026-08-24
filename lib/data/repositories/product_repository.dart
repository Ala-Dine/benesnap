import 'package:drift/drift.dart';
// The whole `drift/remote.dart` library is marked experimental, but this is
// the only supported way to unwrap an exception thrown across the
// `NativeDatabase.createInBackground` isolate boundary.
// ignore: experimental_member_use
import 'package:drift/remote.dart' show DriftRemoteException;
import 'package:sqlite3/common.dart' show SqliteException;

import '../db/app_database.dart';
import '../exceptions.dart';
import '../models/product.dart';
import '../models/suitability_tag.dart';

/// The only place that reads or writes product rows.
///
/// Widgets and providers talk to this; nothing above it sees a drift type or a
/// [SqliteException].
class ProductRepository {
  ProductRepository(this._db);

  final AppDatabase _db;

  /// SQLite's extended result code for a UNIQUE constraint failure.
  static const _uniqueViolation = 2067;

  Future<List<Product>> all() => _guard(() async {
    final rows = await (_db.select(
      _db.products,
    )..orderBy([(p) => OrderingTerm(expression: p.brandName)])).get();
    return _attachTags(rows);
  });

  Future<Product?> findById(int id) => _guard(() async {
    final row = await (_db.select(
      _db.products,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return (await _attachTags([row])).first;
  });

  /// The scan path. [barcode] is expected to be normalized already.
  Future<Product?> findByBarcode(String barcode) => _guard(() async {
    final row = await (_db.select(
      _db.products,
    )..where((p) => p.barcode.equals(barcode))).getSingleOrNull();
    if (row == null) return null;
    return (await _attachTags([row])).first;
  });

  /// Matches brand, product name, or barcode — the three things a shop
  /// assistant might have to hand.
  Future<List<Product>> search(String query) => _guard(() async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return all();

    final pattern = '%${trimmed.toLowerCase()}%';
    final rows =
        await (_db.select(_db.products)
              ..where(
                (p) =>
                    p.brandName.lower().like(pattern) |
                    p.productName.lower().like(pattern) |
                    p.barcode.lower().like(pattern),
              )
              ..orderBy([(p) => OrderingTerm(expression: p.brandName)]))
            .get();
    return _attachTags(rows);
  });

  Future<Product> create(ProductDraft draft) => _guard(() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final id = await _db.transaction(() async {
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
      return newId;
    });

    final created = await findById(id);
    if (created == null) throw const ProductNotFoundException();
    return created;
  }, barcode: draft.barcode);

  Future<Product> update(int id, ProductDraft draft) => _guard(() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
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
    });

    final updated = await findById(id);
    if (updated == null) throw const ProductNotFoundException();
    return updated;
  }, barcode: draft.barcode);

  Future<void> delete(int id) => _guard(() async {
    final removed = await (_db.delete(
      _db.products,
    )..where((p) => p.id.equals(id))).go();
    if (removed == 0) throw const ProductNotFoundException();
  });

  /// Emits a fresh list whenever the catalogue changes, so the inventory grid
  /// updates itself after an edit in another route.
  Stream<List<Product>> watchAll() {
    final query = _db.select(_db.products)
      ..orderBy([(p) => OrderingTerm(expression: p.brandName)]);
    return query.watch().asyncMap(_attachTags);
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
      byProduct.putIfAbsent(link.productId, () => []).add(_toTag(tag));
    }

    return [
      for (final row in rows) _toProduct(row, byProduct[row.id] ?? const []),
    ];
  }

  /// Runs [action], translating storage failures into [AppException]s.
  ///
  /// A UNIQUE violation on a write that carried a [barcode] is by definition
  /// the barcode index, since it is the only unique column on the table.
  /// `_assertBarcodeFree` normally catches that first; this is the backstop for
  /// a genuine race, so the constraint can never reach the user raw.
  Future<T> _guard<T>(Future<T> Function() action, {String? barcode}) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (e) {
      // The background isolate wraps failures, so the SqliteException we care
      // about arrives inside a DriftRemoteException.
      final cause = e is DriftRemoteException ? e.remoteCause : e;

      if (cause is AppException) throw cause;
      if (barcode != null &&
          cause is SqliteException &&
          cause.extendedResultCode == _uniqueViolation) {
        throw DuplicateBarcodeException(barcode);
      }
      throw StorageException(cause);
    }
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

  static SuitabilityTag _toTag(SuitabilityTagRow row) =>
      SuitabilityTag(id: row.id, label: row.label, category: row.category);
}
