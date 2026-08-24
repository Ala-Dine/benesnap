import 'package:benesnap/data/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({String keyIngredients = '', String coreBenefits = ''}) {
  return Product(
    id: 1,
    barcode: '123',
    brandName: 'Aurelia',
    productName: 'Hydrating serum',
    keyIngredients: keyIngredients,
    coreBenefits: coreBenefits,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  group('displayName', () {
    test('joins brand and product name with a space', () {
      expect(_product().displayName, 'Aurelia Hydrating serum');
    });
  });

  group('benefitLines', () {
    test('splits multiple lines into separate entries', () {
      final product = _product(coreBenefits: 'Hydrates\nPlumps\nSoothes');
      expect(product.benefitLines, ['Hydrates', 'Plumps', 'Soothes']);
    });

    test('a single line still renders as one item', () {
      final product = _product(coreBenefits: 'Hydrates');
      expect(product.benefitLines, ['Hydrates']);
    });

    test('trims each line and drops blank ones', () {
      final product = _product(coreBenefits: '  Hydrates  \n\n  Plumps  \n');
      expect(product.benefitLines, ['Hydrates', 'Plumps']);
    });

    test('empty benefits produce no lines', () {
      expect(_product(coreBenefits: '').benefitLines, isEmpty);
    });
  });

  group('firstKeyIngredient', () {
    test('takes the text before the first Latin comma', () {
      final product = _product(keyIngredients: 'Water, Glycerin, Niacinamide');
      expect(product.firstKeyIngredient, 'Water');
    });

    test('takes the text before the first Arabic comma', () {
      final product = _product(keyIngredients: 'ماء، جليسرين، نياسيناميد');
      expect(product.firstKeyIngredient, 'ماء');
    });

    test('trims surrounding whitespace', () {
      final product = _product(keyIngredients: '  Water  , Glycerin');
      expect(product.firstKeyIngredient, 'Water');
    });

    test('a single ingredient with no separator returns the whole string', () {
      final product = _product(keyIngredients: 'Water');
      expect(product.firstKeyIngredient, 'Water');
    });
  });
}
