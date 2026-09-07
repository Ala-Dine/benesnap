import 'package:benesnap/data/db/app_database.dart';
import 'package:benesnap/data/exceptions.dart';
import 'package:benesnap/data/models/product.dart';
import 'package:benesnap/data/models/suitability_tag.dart';
import 'package:benesnap/data/repositories/product_repository.dart';
import 'package:benesnap/data/repositories/tag_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late ProductRepository products;
  late TagRepository tags;

  setUp(() {
    db = createTestDatabase();
    products = ProductRepository(db);
    tags = TagRepository(db);
  });

  ProductDraft draft({
    String barcode = '5901234123457',
    String brandName = 'Aurelia',
    String productName = 'Hydrating serum',
    String keyIngredients = 'Hyaluronic acid (2%), vitamin B5, purified water',
    String coreBenefits = 'Holds up to 1,000x its weight\nPlumps fine lines',
    String? imagePath,
    Set<int> tagIds = const {},
  }) {
    return ProductDraft(
      barcode: barcode,
      brandName: brandName,
      productName: productName,
      keyIngredients: keyIngredients,
      coreBenefits: coreBenefits,
      imagePath: imagePath,
      tagIds: tagIds,
    );
  }

  group('create', () {
    test('stores every field and assigns an id', () async {
      final created = await products.create(draft(imagePath: 'serum.png'));

      expect(created.id, greaterThan(0));
      expect(created.barcode, '5901234123457');
      expect(created.brandName, 'Aurelia');
      expect(created.productName, 'Hydrating serum');
      expect(created.keyIngredients, contains('Hyaluronic acid'));
      expect(created.imagePath, 'serum.png');
    });

    test('stamps createdAt and updatedAt', () async {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final created = await products.create(draft());

      expect(created.createdAt.isAfter(before), isTrue);
      expect(created.updatedAt.isAfter(before), isTrue);
    });

    test('leaves imagePath null when no picture was chosen', () async {
      final created = await products.create(draft());

      expect(created.imagePath, isNull);
    });

    test('links the selected suitability tags', () async {
      final all = await tags.all();
      final dry = all.firstWhere((t) => t.label == 'جافة');
      final curly = all.firstWhere((t) => t.label == 'مجعد');

      final created = await products.create(draft(tagIds: {dry.id, curly.id}));

      expect(created.tags.map((t) => t.label), containsAll(['جافة', 'مجعد']));
      expect(created.tagsIn(TagCategory.skin).single.label, 'جافة');
      expect(created.tagsIn(TagCategory.hair).single.label, 'مجعد');
    });
  });

  group('unique barcode', () {
    test('a second product with the same barcode is rejected', () async {
      await products.create(draft());

      expect(
        () => products.create(draft(productName: 'Different product')),
        throwsA(isA<DuplicateBarcodeException>()),
      );
    });

    test('the failure names the offending barcode in plain language', () async {
      await products.create(draft(barcode: 'AB12CD'));

      try {
        await products.create(draft(barcode: 'AB12CD'));
        fail('expected a DuplicateBarcodeException');
      } on DuplicateBarcodeException catch (e) {
        expect(e.barcode, 'AB12CD');
        expect(e.message, contains('AB12CD'));
        expect(e.message, isNot(contains('SqliteException')));
      }
    });

    test('a rejected create leaves the catalogue untouched', () async {
      await products.create(draft());

      await expectLater(
        products.create(draft(brandName: 'Other')),
        throwsA(isA<DuplicateBarcodeException>()),
      );

      final all = await products.all();
      expect(all, hasLength(1));
      expect(all.single.brandName, 'Aurelia');
    });

    test('updating onto another product\'s barcode is rejected', () async {
      await products.create(draft(barcode: 'AAAA1111'));
      final second = await products.create(draft(barcode: 'BBBB2222'));

      expect(
        () => products.update(second.id, draft(barcode: 'AAAA1111')),
        throwsA(isA<DuplicateBarcodeException>()),
      );
    });

    test('keeping its own barcode while editing is allowed', () async {
      final created = await products.create(draft(barcode: 'AAAA1111'));

      final updated = await products.update(
        created.id,
        draft(barcode: 'AAAA1111', productName: 'Renamed'),
      );

      expect(updated.productName, 'Renamed');
      expect(updated.barcode, 'AAAA1111');
    });
  });

  group('read', () {
    test('findByBarcode returns the matching product', () async {
      await products.create(draft(barcode: 'AB12CD'));

      final found = await products.findByBarcode('AB12CD');

      expect(found, isNotNull);
      expect(found!.productName, 'Hydrating serum');
    });

    test('findByBarcode returns null for an unknown code', () async {
      expect(await products.findByBarcode('NOPE9999'), isNull);
    });

    test('findById returns null once deleted', () async {
      final created = await products.create(draft());
      await products.delete(created.id);

      expect(await products.findById(created.id), isNull);
    });

    test('all returns every product ordered by brand', () async {
      await products.create(draft(barcode: 'C3', brandName: 'Coral'));
      await products.create(draft(barcode: 'A1', brandName: 'Aurelia'));
      await products.create(draft(barcode: 'B2', brandName: 'Botanica'));

      final all = await products.all();

      expect(all.map((p) => p.brandName), ['Aurelia', 'Botanica', 'Coral']);
    });

    test('all is empty on a fresh catalogue', () async {
      expect(await products.all(), isEmpty);
    });
  });

  group('update', () {
    test('changes the stored fields', () async {
      final created = await products.create(draft());

      final updated = await products.update(
        created.id,
        draft(
          brandName: 'Aurelia Skincare',
          productName: 'Hydrating serum v2',
          coreBenefits: 'Lightweight',
        ),
      );

      expect(updated.id, created.id);
      expect(updated.brandName, 'Aurelia Skincare');
      expect(updated.productName, 'Hydrating serum v2');
      expect(updated.benefitLines, ['Lightweight']);
    });

    test('replaces the tag selection rather than adding to it', () async {
      final all = await tags.all();
      final dry = all.firstWhere((t) => t.label == 'جافة');
      final oily = all.firstWhere((t) => t.label == 'دهنية');

      final created = await products.create(draft(tagIds: {dry.id}));
      final updated = await products.update(
        created.id,
        draft(tagIds: {oily.id}),
      );

      expect(updated.tags.map((t) => t.label), ['دهنية']);
    });

    test('clearing every tag leaves none behind', () async {
      final all = await tags.all();
      final dry = all.firstWhere((t) => t.label == 'جافة');

      final created = await products.create(draft(tagIds: {dry.id}));
      final updated = await products.update(created.id, draft());

      expect(updated.tags, isEmpty);
    });

    test('updating a missing product reports it in plain language', () async {
      expect(
        () => products.update(4321, draft()),
        throwsA(isA<ProductNotFoundException>()),
      );
    });
  });

  group('delete', () {
    test('hands back the image filename so the caller can delete the '
        'file too', () async {
      // The row is the only record of which file belonged to this product,
      // so once it is gone nothing else can work that out — the delete has
      // to report it on the way past or the file is orphaned forever.
      final created = await products.create(draft(imagePath: 'img_123_ab.png'));

      expect(await products.delete(created.id), 'img_123_ab.png');
    });

    test('hands back null for a product that never had an image', () async {
      final created = await products.create(draft());
      expect(await products.delete(created.id), isNull);
    });

    test('removes the product', () async {
      final created = await products.create(draft());

      await products.delete(created.id);

      expect(await products.all(), isEmpty);
    });

    test('frees the barcode for reuse', () async {
      final created = await products.create(draft(barcode: 'AB12CD'));
      await products.delete(created.id);

      final replacement = await products.create(draft(barcode: 'AB12CD'));

      expect(replacement.barcode, 'AB12CD');
    });

    test('cascades to the tag links', () async {
      final all = await tags.all();
      final dry = all.firstWhere((t) => t.label == 'جافة');
      final created = await products.create(draft(tagIds: {dry.id}));

      await products.delete(created.id);

      final orphans = await db.select(db.productTags).get();
      expect(orphans, isEmpty);
    });

    test('deleting a missing product reports it in plain language', () async {
      expect(
        () => products.delete(4321),
        throwsA(isA<ProductNotFoundException>()),
      );
    });
  });

  group('watchAll', () {
    test('emits again when a tag the catalogue uses is deleted', () async {
      // Deleting a tag writes suitability_tags and cascades through
      // product_tags without touching products at all, so a stream watching
      // only products kept handing out a Product still carrying the deleted
      // tag until some unrelated write came along.
      final tag = (await tags.all()).first;
      await products.create(draft(tagIds: {tag.id}));

      final emissions = <List<Product>>[];
      final subscription = products.watchAll().listen(emissions.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      expect(emissions.last.single.tags, hasLength(1));

      await tags.deleteTag(tag.id);
      await pumpEventQueue();

      expect(emissions.last.single.tags, isEmpty);
    });

    test('emits again when a product is added', () async {
      final emissions = <List<Product>>[];
      final sub = products.watchAll().listen(emissions.add);
      addTearDown(sub.cancel);

      await pumpEventQueue();
      await products.create(draft());
      await pumpEventQueue();

      expect(emissions.first, isEmpty);
      expect(emissions.last, hasLength(1));
    });
  });

  group('seeded tags', () {
    test('ship with the skin and hair vocabulary', () async {
      final all = await tags.all();

      expect(all.where((t) => t.category == TagCategory.skin), hasLength(7));
      expect(all.where((t) => t.category == TagCategory.hair), hasLength(10));
    });

    test('are not duplicated when the database is reopened', () async {
      final first = await tags.all();

      // beforeOpen runs the seed again on a second connection.
      await db.customStatement('PRAGMA foreign_keys = ON');
      final second = await tags.all();

      expect(second.length, first.length);
    });

    test('cover both categories', () async {
      final all = await tags.all();
      final hair = all.where((t) => t.category == TagCategory.hair);

      expect(hair, isNotEmpty);
      expect(all.any((t) => t.category == TagCategory.skin), isTrue);
      expect(hair.map((t) => t.label), contains('شديد التجعد'));
    });
  });
}
